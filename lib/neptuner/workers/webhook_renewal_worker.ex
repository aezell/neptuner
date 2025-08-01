defmodule Neptuner.Workers.WebhookRenewalWorker do
  @moduledoc """
  Background worker for renewing webhook subscriptions before they expire.
  Handles Google Calendar channels and Microsoft Graph subscriptions.
  """

  use Oban.Worker, queue: :webhooks, max_attempts: 3

  require Logger
  alias Neptuner.Integrations.MicrosoftGraphWebhooks

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "renew_microsoft_webhooks"}}) do
    Logger.info("Starting Microsoft Graph webhook renewal process")

    MicrosoftGraphWebhooks.renew_expiring_subscriptions()

    # Schedule the next renewal check in 12 hours
    schedule_microsoft_renewal(delay: 12 * 60 * 60)

    :ok
  rescue
    error ->
      Logger.error("Webhook renewal worker failed: #{inspect(error)}")
      {:error, error}
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "renew_google_webhooks"}}) do
    Logger.info("Starting Google webhook renewal process")

    # Google Calendar webhooks need to be renewed every 7 days
    # This would call similar renewal logic for Google webhooks
    renew_google_calendar_channels()

    # Schedule the next renewal check in 24 hours
    schedule_google_renewal(delay: 24 * 60 * 60)

    :ok
  rescue
    error ->
      Logger.error("Google webhook renewal worker failed: #{inspect(error)}")
      {:error, error}
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "cleanup_expired_webhooks"}}) do
    Logger.info("Starting expired webhook cleanup")

    cleanup_expired_webhooks()

    # Schedule next cleanup in 24 hours
    schedule_webhook_cleanup(delay: 24 * 60 * 60)

    :ok
  rescue
    error ->
      Logger.error("Webhook cleanup worker failed: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Schedules Microsoft Graph webhook renewal job.
  """
  def schedule_microsoft_renewal(opts \\ []) do
    delay = Keyword.get(opts, :delay, 0)

    %{
      "type" => "renew_microsoft_webhooks"
    }
    |> __MODULE__.new(schedule_in: delay)
    |> Oban.insert()
  end

  @doc """
  Schedules Google webhook renewal job.
  """
  def schedule_google_renewal(opts \\ []) do
    delay = Keyword.get(opts, :delay, 0)

    %{
      "type" => "renew_google_webhooks"
    }
    |> __MODULE__.new(schedule_in: delay)
    |> Oban.insert()
  end

  @doc """
  Schedules webhook cleanup job.
  """
  def schedule_webhook_cleanup(opts \\ []) do
    delay = Keyword.get(opts, :delay, 0)

    %{
      "type" => "cleanup_expired_webhooks"
    }
    |> __MODULE__.new(schedule_in: delay)
    |> Oban.insert()
  end

  # Private functions

  defp renew_google_calendar_channels do
    alias Neptuner.{Repo, Connections}
    alias Neptuner.Webhooks.WebhookSubscription

    # Find Google Calendar webhook subscriptions that need renewal
    renewal_threshold = DateTime.add(DateTime.utc_now(), 2, :day)

    expiring_google_webhooks =
      WebhookSubscription
      |> Repo.all()
      |> Enum.filter(fn webhook ->
        (webhook.webhook_type == :google_calendar and
           webhook.is_active and
           webhook.expires_at) && DateTime.compare(webhook.expires_at, renewal_threshold) == :lt
      end)

    Logger.info(
      "Found #{length(expiring_google_webhooks)} Google Calendar webhooks needing renewal"
    )

    Enum.each(expiring_google_webhooks, fn webhook ->
      connection = Connections.get_service_connection!(webhook.connection_id)

      # For Google Calendar, we need to create a new channel since they can't be renewed
      {:ok, new_webhook_data} = recreate_google_calendar_channel(connection, webhook)

      # Update the webhook with new channel info
      webhook
      |> WebhookSubscription.changeset(%{
        provider_webhook_id: new_webhook_data.channel_id,
        expires_at: new_webhook_data.expires_at,
        metadata:
          Map.merge(webhook.metadata, %{
            "resource_id" => new_webhook_data.resource_id,
            "renewed_at" => DateTime.utc_now()
          })
      })
      |> Repo.update()
    end)
  end

  defp recreate_google_calendar_channel(connection, _webhook) do
    # This would call the Google Calendar API to create a new webhook channel
    # Since Google Calendar channels can't be renewed, we need to create new ones
    Logger.info("Recreating Google Calendar channel for connection #{connection.id}")

    # Placeholder for actual Google Calendar API call
    {:ok,
     %{
       channel_id: "new_channel_#{:rand.uniform(1_000_000)}",
       resource_id: "new_resource_#{:rand.uniform(1_000_000)}",
       expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
     }}
  end

  defp cleanup_expired_webhooks do
    alias Neptuner.{Repo, Connections}
    alias Neptuner.Webhooks.WebhookSubscription

    # Find all expired webhook subscriptions
    expired_webhooks =
      WebhookSubscription
      |> Repo.all()
      |> Enum.filter(fn webhook ->
        webhook.expires_at &&
          DateTime.compare(webhook.expires_at, DateTime.utc_now()) == :lt
      end)

    Logger.info("Found #{length(expired_webhooks)} expired webhooks to clean up")

    Enum.each(expired_webhooks, fn webhook ->
      connection = Connections.get_service_connection!(webhook.connection_id)

      # Attempt to delete the webhook from the provider
      case delete_provider_webhook(webhook, connection) do
        :ok ->
          Logger.info("Successfully deleted expired webhook #{webhook.id}")

        {:error, reason} ->
          Logger.warning("Failed to delete expired webhook #{webhook.id}: #{inspect(reason)}")
      end

      # Mark webhook as inactive regardless of deletion success
      webhook
      |> WebhookSubscription.changeset(%{is_active: false})
      |> Repo.update()
    end)
  end

  defp delete_provider_webhook(webhook, connection) do
    case webhook.webhook_type do
      :microsoft_calendar ->
        case ensure_valid_token(connection) do
          {:ok, access_token} ->
            MicrosoftGraphWebhooks.delete_subscription(webhook.provider_webhook_id, access_token)

          {:error, reason} ->
            {:error, reason}
        end

      :microsoft_email ->
        case ensure_valid_token(connection) do
          {:ok, access_token} ->
            MicrosoftGraphWebhooks.delete_subscription(webhook.provider_webhook_id, access_token)

          {:error, reason} ->
            {:error, reason}
        end

      :google_calendar ->
        # Google Calendar channels expire automatically, no need to delete
        :ok

      :gmail_push ->
        # Gmail push subscriptions expire automatically, no need to delete
        :ok

      _ ->
        Logger.warning("Unknown webhook type for cleanup: #{webhook.webhook_type}")
        :ok
    end
  end

  defp ensure_valid_token(connection) do
    alias Neptuner.Connections

    alias Neptuner.Connections.ServiceConnection

    if ServiceConnection.needs_refresh?(connection) do
      case Connections.refresh_service_connection_token(connection) do
        {:ok, updated_connection} -> {:ok, updated_connection.access_token}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, connection.access_token}
    end
  end
end
