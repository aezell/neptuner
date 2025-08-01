defmodule Neptuner.Integrations.MicrosoftGraphWebhooks do
  @moduledoc """
  Microsoft Graph webhook management for real-time notifications.
  Handles creation, renewal, and deletion of webhook subscriptions.
  """

  require Logger
  alias Neptuner.Connections.ServiceConnection
  alias Neptuner.Webhooks.WebhookSubscription

  @microsoft_graph_api_base "https://graph.microsoft.com/v1.0"
  @webhook_base_url System.get_env("APP_URL", "http://localhost:4000")

  @doc """
  Creates a Microsoft Graph webhook subscription for calendar events.
  """
  def create_calendar_subscription(%ServiceConnection{} = connection) do
    with {:ok, access_token} <- ensure_valid_token(connection),
         {:ok, webhook_data} <-
           create_graph_subscription(
             access_token,
             "me/calendars/#{get_primary_calendar_id(connection)}/events",
             ["created", "updated", "deleted"],
             "#{@webhook_base_url}/webhooks/microsoft/graph"
           ) do
      Logger.info("Created Microsoft Graph calendar webhook for connection #{connection.id}")

      {:ok, webhook_data}
    else
      {:error, reason} ->
        Logger.error("Failed to create Microsoft Graph calendar webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Creates a Microsoft Graph webhook subscription for email messages.
  """
  def create_email_subscription(%ServiceConnection{} = connection) do
    with {:ok, access_token} <- ensure_valid_token(connection),
         {:ok, webhook_data} <-
           create_graph_subscription(
             access_token,
             "me/messages",
             ["created", "updated", "deleted"],
             "#{@webhook_base_url}/webhooks/microsoft/graph"
           ) do
      Logger.info("Created Microsoft Graph email webhook for connection #{connection.id}")

      {:ok, webhook_data}
    else
      {:error, reason} ->
        Logger.error("Failed to create Microsoft Graph email webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Renews a Microsoft Graph webhook subscription before it expires.
  """
  def renew_subscription(subscription_id, access_token) do
    # Microsoft Graph subscriptions need to be renewed periodically
    expiry_time = DateTime.add(DateTime.utc_now(), 3, :day) |> DateTime.to_iso8601()

    url = "#{@microsoft_graph_api_base}/subscriptions/#{subscription_id}"

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        expirationDateTime: expiry_time
      })

    case Req.patch(url, headers: headers, body: body) do
      {:ok, %{status: 200, body: response}} ->
        Logger.info("Renewed Microsoft Graph webhook subscription #{subscription_id}")
        {:ok, response}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to renew Microsoft Graph webhook: #{status} - #{inspect(body)}")
        {:error, "Renewal failed with status #{status}"}

      {:error, reason} ->
        Logger.error("Microsoft Graph webhook renewal request failed: #{inspect(reason)}")
        {:error, "Network error during renewal"}
    end
  end

  @doc """
  Deletes a Microsoft Graph webhook subscription.
  """
  def delete_subscription(subscription_id, access_token) do
    url = "#{@microsoft_graph_api_base}/subscriptions/#{subscription_id}"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.delete(url, headers: headers) do
      {:ok, %{status: 204}} ->
        Logger.info("Deleted Microsoft Graph webhook subscription #{subscription_id}")
        :ok

      {:ok, %{status: 404}} ->
        Logger.info(
          "Microsoft Graph webhook subscription #{subscription_id} not found (already deleted)"
        )

        :ok

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to delete Microsoft Graph webhook: #{status} - #{inspect(body)}")
        {:error, "Deletion failed with status #{status}"}

      {:error, reason} ->
        Logger.error("Microsoft Graph webhook deletion request failed: #{inspect(reason)}")
        {:error, "Network error during deletion"}
    end
  end

  @doc """
  Lists all active webhook subscriptions for debugging.
  """
  def list_subscriptions(access_token) do
    url = "#{@microsoft_graph_api_base}/subscriptions"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: response}} ->
        subscriptions = response["value"] || []
        Logger.info("Found #{length(subscriptions)} Microsoft Graph webhook subscriptions")
        {:ok, subscriptions}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to list Microsoft Graph webhooks: #{status} - #{inspect(body)}")
        {:error, "List request failed with status #{status}"}

      {:error, reason} ->
        Logger.error("Microsoft Graph webhook list request failed: #{inspect(reason)}")
        {:error, "Network error during list"}
    end
  end

  @doc """
  Processes webhook renewal for expiring subscriptions.
  Should be called periodically by a background job.
  """
  def renew_expiring_subscriptions do
    alias Neptuner.{Repo, Connections}

    # Find webhook subscriptions that need renewal (expire within 1 day)
    renewal_threshold = DateTime.add(DateTime.utc_now(), 1, :day)

    expiring_webhooks =
      WebhookSubscription
      |> Repo.all()
      |> Enum.filter(fn webhook ->
        (webhook.webhook_type in [:microsoft_calendar, :microsoft_email] and
           webhook.is_active and
           webhook.expires_at) && DateTime.compare(webhook.expires_at, renewal_threshold) == :lt
      end)

    Logger.info("Found #{length(expiring_webhooks)} Microsoft Graph webhooks needing renewal")

    Enum.each(expiring_webhooks, fn webhook ->
      connection = Connections.get_service_connection!(webhook.connection_id)

      case ensure_valid_token(connection) do
        {:ok, access_token} ->
          case renew_subscription(webhook.provider_webhook_id, access_token) do
            {:ok, response} ->
              # Update the webhook expiry time
              new_expiry = parse_microsoft_date(response["expirationDateTime"])

              webhook
              |> WebhookSubscription.changeset(%{expires_at: new_expiry})
              |> Repo.update()

            {:error, reason} ->
              Logger.warning("Failed to renew webhook #{webhook.id}: #{inspect(reason)}")
              # Mark webhook as inactive if renewal fails
              webhook
              |> WebhookSubscription.changeset(%{is_active: false})
              |> Repo.update()
          end

        {:error, reason} ->
          Logger.warning("Failed to get access token for webhook renewal: #{inspect(reason)}")
      end
    end)
  end

  # Private functions

  defp ensure_valid_token(%ServiceConnection{} = connection) do
    alias Neptuner.Connections

    if ServiceConnection.needs_refresh?(connection) do
      case Connections.refresh_service_connection_token(connection) do
        {:ok, updated_connection} -> {:ok, updated_connection.access_token}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, connection.access_token}
    end
  end

  defp create_graph_subscription(access_token, resource, change_types, notification_url) do
    # Microsoft Graph subscriptions expire after a maximum of 3 days
    expiry_time = DateTime.add(DateTime.utc_now(), 3, :day) |> DateTime.to_iso8601()

    url = "#{@microsoft_graph_api_base}/subscriptions"

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        changeType: Enum.join(change_types, ","),
        notificationUrl: notification_url,
        resource: resource,
        expirationDateTime: expiry_time,
        clientState: generate_client_state()
      })

    case Req.post(url, headers: headers, body: body) do
      {:ok, %{status: 201, body: response}} ->
        {:ok, response}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Microsoft Graph subscription creation failed: #{status} - #{inspect(body)}")
        {:error, "Subscription creation failed with status #{status}"}

      {:error, reason} ->
        Logger.error("Microsoft Graph subscription creation request failed: #{inspect(reason)}")
        {:error, "Network error during subscription creation"}
    end
  end

  defp get_primary_calendar_id(_connection) do
    # For now, use the primary calendar
    # In a more sophisticated implementation, we'd track which calendars the user wants
    "primary"
  end

  defp generate_client_state do
    # Generate a unique client state for webhook verification
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end

  defp parse_microsoft_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_microsoft_date(_), do: nil
end
