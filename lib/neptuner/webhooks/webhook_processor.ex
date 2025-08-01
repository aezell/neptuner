defmodule Neptuner.Webhooks.WebhookProcessor do
  @moduledoc """
  Processes webhook notifications from various providers.
  Handles Google Calendar, Gmail, and Microsoft Graph webhooks.
  """

  require Logger
  alias Neptuner.{Connections, Repo}
  alias Neptuner.Connections.ServiceConnection
  alias Neptuner.Webhooks.WebhookSubscription

  @doc """
  Processes Google Calendar webhook notifications.
  Returns the connection ID that should be synced.
  """
  def process_google_calendar_webhook(channel_id, _resource_id, _params) do
    case find_connection_by_webhook_channel(channel_id, :google, :calendar) do
      %ServiceConnection{} = connection ->
        Logger.info("Processing Google Calendar webhook for connection #{connection.id}")

        # Mark the connection as needing sync
        Connections.update_service_connection(connection, %{
          last_webhook_at: DateTime.utc_now()
        })

        {:ok, connection.id}

      nil ->
        Logger.warning("No connection found for Google Calendar webhook channel #{channel_id}")
        {:error, "Connection not found"}
    end
  end

  @doc """
  Processes Gmail webhook notifications (push notifications).
  Returns the connection ID that should be synced.
  """
  def process_gmail_webhook(_subscription, _params) do
    # Gmail push notifications don't include easy connection mapping
    # We'll need to sync all Gmail connections for now
    # In a more sophisticated setup, we'd map message numbers to connections

    gmail_connections =
      Connections.list_service_connections_by_type(nil, :email)
      |> Enum.filter(&(&1.provider == :google))

    case gmail_connections do
      [connection] ->
        Logger.info("Processing Gmail webhook for connection #{connection.id}")

        Connections.update_service_connection(connection, %{
          last_webhook_at: DateTime.utc_now()
        })

        {:ok, connection.id}

      [] ->
        Logger.warning("No Gmail connections found for webhook")
        {:error, "No Gmail connections"}

      multiple_connections ->
        Logger.info("Multiple Gmail connections found, syncing all")

        # Update all connections and return the first one for sync scheduling
        Enum.each(multiple_connections, fn connection ->
          Connections.update_service_connection(connection, %{
            last_webhook_at: DateTime.utc_now()
          })
        end)

        {:ok, hd(multiple_connections).id}
    end
  end

  @doc """
  Processes Microsoft Graph webhook notifications.
  Returns a list of connection IDs that should be synced.
  """
  def process_microsoft_graph_webhook(params) do
    Logger.info("Processing Microsoft Graph webhook: #{inspect(params)}")

    # Microsoft Graph webhooks include resource information
    case extract_microsoft_resource_info(params) do
      {:ok, resource_type, _resource_data} ->
        service_type = map_microsoft_resource_to_service(resource_type)

        # Find all Microsoft connections of this service type
        microsoft_connections =
          Connections.list_service_connections_by_type(nil, service_type)
          |> Enum.filter(&(&1.provider == :microsoft))

        case microsoft_connections do
          [] ->
            Logger.warning("No Microsoft #{service_type} connections found for webhook")
            {:error, "No connections found"}

          connections ->
            Logger.info(
              "Found #{length(connections)} Microsoft #{service_type} connections for webhook"
            )

            # Update all connections
            connection_ids =
              Enum.map(connections, fn connection ->
                Connections.update_service_connection(connection, %{
                  last_webhook_at: DateTime.utc_now()
                })

                connection.id
              end)

            {:ok, connection_ids}
        end

      {:error, reason} ->
        Logger.warning("Failed to extract Microsoft Graph resource info: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Creates webhook subscriptions for a connection.
  This sets up real-time notifications for the connected service.
  """
  def create_webhook_subscriptions(%ServiceConnection{} = connection) do
    case {connection.provider, connection.service_type} do
      {:google, :calendar} ->
        create_google_calendar_webhook(connection)

      {:google, :email} ->
        create_gmail_webhook(connection)

      {:microsoft, :calendar} ->
        create_microsoft_calendar_webhook(connection)

      {:microsoft, :email} ->
        create_microsoft_email_webhook(connection)

      _ ->
        Logger.info(
          "Webhook subscriptions not supported for #{connection.provider}/#{connection.service_type}"
        )

        {:ok, :not_supported}
    end
  end

  @doc """
  Removes webhook subscriptions for a connection.
  """
  def remove_webhook_subscriptions(%ServiceConnection{} = connection) do
    # Find and remove all webhook subscriptions for this connection
    WebhookSubscription
    |> Repo.get_by(connection_id: connection.id)
    |> case do
      nil ->
        {:ok, :no_subscriptions}

      subscription ->
        remove_provider_webhook_subscription(subscription)
        Repo.delete(subscription)
        {:ok, :removed}
    end
  end

  # Private functions

  defp find_connection_by_webhook_channel(_channel_id, provider, service_type) do
    # In a real implementation, you'd store webhook channel mappings
    # For now, find the first matching connection
    ServiceConnection
    |> Repo.get_by(provider: provider, service_type: service_type, connection_status: :active)
  end

  defp extract_microsoft_resource_info(params) do
    # Microsoft Graph webhooks have different formats depending on the resource
    cond do
      params["resource"] && String.contains?(params["resource"], "/calendars/") ->
        {:ok, :calendar, params["resource"]}

      params["resource"] && String.contains?(params["resource"], "/messages") ->
        {:ok, :email, params["resource"]}

      params["value"] && is_list(params["value"]) ->
        # Batch notification format
        first_item = List.first(params["value"])
        extract_microsoft_resource_info(first_item)

      true ->
        {:error, "Unrecognized Microsoft Graph webhook format"}
    end
  end

  defp map_microsoft_resource_to_service(:calendar), do: :calendar
  defp map_microsoft_resource_to_service(:email), do: :email
  defp map_microsoft_resource_to_service(_), do: :unknown

  defp create_google_calendar_webhook(%ServiceConnection{} = connection) do
    # Google Calendar webhook creation would go here
    # This involves calling the Google Calendar API to set up a webhook channel
    Logger.info("Creating Google Calendar webhook for connection #{connection.id}")

    # Store webhook subscription info
    create_webhook_subscription(connection, %{
      provider_webhook_id: "google_cal_#{connection.id}",
      webhook_type: :google_calendar,
      # Google webhooks expire
      expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
    })
  end

  defp create_gmail_webhook(%ServiceConnection{} = connection) do
    # Gmail push notification setup would go here
    Logger.info("Creating Gmail webhook for connection #{connection.id}")

    create_webhook_subscription(connection, %{
      provider_webhook_id: "gmail_#{connection.id}",
      webhook_type: :gmail_push,
      # Gmail push notifications don't expire
      expires_at: nil
    })
  end

  defp create_microsoft_calendar_webhook(%ServiceConnection{} = connection) do
    alias Neptuner.Integrations.MicrosoftGraphWebhooks

    Logger.info("Creating Microsoft Calendar webhook for connection #{connection.id}")

    case MicrosoftGraphWebhooks.create_calendar_subscription(connection) do
      {:ok, webhook_data} ->
        create_webhook_subscription(connection, %{
          provider_webhook_id: webhook_data["id"],
          webhook_type: :microsoft_calendar,
          webhook_url: webhook_data["notificationUrl"],
          expires_at: parse_microsoft_date(webhook_data["expirationDateTime"]),
          metadata: %{
            "resource" => webhook_data["resource"],
            "change_type" => webhook_data["changeType"],
            "client_state" => webhook_data["clientState"]
          }
        })

      {:error, reason} ->
        Logger.error(
          "Failed to create Microsoft Calendar webhook API subscription: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp create_microsoft_email_webhook(%ServiceConnection{} = connection) do
    alias Neptuner.Integrations.MicrosoftGraphWebhooks

    Logger.info("Creating Microsoft Email webhook for connection #{connection.id}")

    case MicrosoftGraphWebhooks.create_email_subscription(connection) do
      {:ok, webhook_data} ->
        create_webhook_subscription(connection, %{
          provider_webhook_id: webhook_data["id"],
          webhook_type: :microsoft_email,
          webhook_url: webhook_data["notificationUrl"],
          expires_at: parse_microsoft_date(webhook_data["expirationDateTime"]),
          metadata: %{
            "resource" => webhook_data["resource"],
            "change_type" => webhook_data["changeType"],
            "client_state" => webhook_data["clientState"]
          }
        })

      {:error, reason} ->
        Logger.error(
          "Failed to create Microsoft Email webhook API subscription: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp create_webhook_subscription(%ServiceConnection{} = connection, attrs) do
    webhook_attrs =
      Map.merge(attrs, %{
        connection_id: connection.id,
        is_active: true,
        created_at: DateTime.utc_now()
      })

    %WebhookSubscription{}
    |> WebhookSubscription.changeset(webhook_attrs)
    |> Repo.insert()
  end

  defp remove_provider_webhook_subscription(%WebhookSubscription{} = subscription) do
    # Remove the webhook subscription from the provider's API
    case subscription.webhook_type do
      :google_calendar ->
        Logger.info("Removing Google Calendar webhook #{subscription.provider_webhook_id}")

      # Call Google API to stop the webhook channel

      :gmail_push ->
        Logger.info("Removing Gmail webhook #{subscription.provider_webhook_id}")

      # Call Google API to stop the push subscription

      :microsoft_calendar ->
        Logger.info("Removing Microsoft Calendar webhook #{subscription.provider_webhook_id}")

      # Call Microsoft Graph API to delete the subscription

      :microsoft_email ->
        Logger.info("Removing Microsoft Email webhook #{subscription.provider_webhook_id}")

      # Call Microsoft Graph API to delete the subscription

      _ ->
        Logger.warning("Unknown webhook type: #{subscription.webhook_type}")
    end
  end

  defp parse_microsoft_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_microsoft_date(_), do: nil
end
