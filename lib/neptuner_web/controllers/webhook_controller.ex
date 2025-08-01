defmodule NeptunerWeb.WebhookController do
  use NeptunerWeb, :controller
  require Logger

  alias Neptuner.Connections
  alias Neptuner.Webhooks.WebhookProcessor
  alias Neptuner.Workers.SyncWorker

  @doc """
  Handles Google Calendar webhook notifications for real-time sync.
  """
  def google_calendar(conn, params) do
    Logger.info("Received Google Calendar webhook: #{inspect(params)}")

    # Google Calendar webhook verification
    with {:ok, channel_id} <- get_channel_id(conn),
         {:ok, resource_id} <- get_resource_id(conn),
         :ok <- verify_google_webhook(conn) do
      # Process the webhook asynchronously
      case WebhookProcessor.process_google_calendar_webhook(channel_id, resource_id, params) do
        {:ok, connection_id} ->
          # Get the connection and schedule immediate sync
          connection = Connections.get_service_connection!(connection_id)
          SyncWorker.schedule_connection_sync(connection, delay: 0)

          conn
          |> put_status(200)
          |> json(%{status: "ok"})

        {:error, reason} ->
          Logger.warning("Failed to process Google Calendar webhook: #{inspect(reason)}")

          conn
          # Always return 200 to avoid retries for invalid webhooks
          |> put_status(200)
          |> json(%{status: "ignored", reason: reason})
      end
    else
      {:error, reason} ->
        Logger.warning("Invalid Google Calendar webhook: #{inspect(reason)}")

        conn
        |> put_status(400)
        |> json(%{error: reason})
    end
  end

  @doc """
  Handles Gmail webhook notifications (push notifications) for real-time sync.
  """
  def gmail(conn, params) do
    Logger.info("Received Gmail webhook: #{inspect(params)}")

    # Gmail push notification verification
    with {:ok, subscription} <- get_gmail_subscription(conn),
         :ok <- verify_gmail_webhook(conn) do
      # Process the webhook asynchronously
      case WebhookProcessor.process_gmail_webhook(subscription, params) do
        {:ok, connection_id} ->
          # Get the connection and schedule immediate sync
          connection = Connections.get_service_connection!(connection_id)
          SyncWorker.schedule_connection_sync(connection, delay: 0)

          conn
          |> put_status(200)
          |> json(%{status: "ok"})

        {:error, reason} ->
          Logger.warning("Failed to process Gmail webhook: #{inspect(reason)}")

          conn
          |> put_status(200)
          |> json(%{status: "ignored", reason: reason})
      end
    else
      {:error, reason} ->
        Logger.warning("Invalid Gmail webhook: #{inspect(reason)}")

        conn
        |> put_status(400)
        |> json(%{error: reason})
    end
  end

  @doc """
  Handles Microsoft Graph webhook notifications for real-time sync.
  """
  def microsoft_graph(conn, params) do
    Logger.info("Received Microsoft Graph webhook: #{inspect(params)}")

    # Microsoft Graph webhook verification
    with :ok <- verify_microsoft_webhook(conn, params) do
      # Process the webhook asynchronously
      case WebhookProcessor.process_microsoft_graph_webhook(params) do
        {:ok, connection_ids} when is_list(connection_ids) ->
          # Schedule immediate sync for all affected connections
          Enum.each(connection_ids, fn connection_id ->
            connection = Connections.get_service_connection!(connection_id)
            SyncWorker.schedule_connection_sync(connection, delay: 0)
          end)

          conn
          |> put_status(200)
          |> json(%{status: "ok"})

        {:error, reason} ->
          Logger.warning("Failed to process Microsoft Graph webhook: #{inspect(reason)}")

          conn
          |> put_status(200)
          |> json(%{status: "ignored", reason: reason})
      end
    else
      {:error, reason} ->
        Logger.warning("Invalid Microsoft Graph webhook: #{inspect(reason)}")

        conn
        |> put_status(400)
        |> json(%{error: reason})
    end
  end

  @doc """
  Health check endpoint for webhook infrastructure.
  """
  def health(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{status: "healthy", timestamp: DateTime.utc_now()})
  end

  # Private functions

  defp get_channel_id(conn) do
    case get_req_header(conn, "x-goog-channel-id") do
      [channel_id] -> {:ok, channel_id}
      [] -> {:error, "Missing x-goog-channel-id header"}
      _ -> {:error, "Invalid x-goog-channel-id header"}
    end
  end

  defp get_resource_id(conn) do
    case get_req_header(conn, "x-goog-resource-id") do
      [resource_id] -> {:ok, resource_id}
      [] -> {:error, "Missing x-goog-resource-id header"}
      _ -> {:error, "Invalid x-goog-resource-id header"}
    end
  end

  defp get_gmail_subscription(conn) do
    # Gmail push notifications come with subscription info in headers
    case get_req_header(conn, "x-goog-message-number") do
      [message_number] -> {:ok, %{message_number: message_number}}
      [] -> {:error, "Missing x-goog-message-number header"}
      _ -> {:error, "Invalid x-goog-message-number header"}
    end
  end

  defp verify_google_webhook(conn) do
    # Basic verification - in production you'd want to verify the token
    case get_req_header(conn, "x-goog-channel-token") do
      [_token] -> :ok
      [] -> {:error, "Missing webhook token"}
      _ -> {:error, "Invalid webhook token"}
    end
  end

  defp verify_gmail_webhook(conn) do
    # Gmail push notifications include a token for verification
    case get_req_header(conn, "x-goog-channel-token") do
      # In production, verify this token
      [_token] -> :ok
      [] -> {:error, "Missing Gmail webhook token"}
      _ -> {:error, "Invalid Gmail webhook token"}
    end
  end

  defp verify_microsoft_webhook(conn, params) do
    # Microsoft Graph webhook verification
    # Check for validation token (for subscription setup)
    case params do
      %{"validationToken" => validation_token} ->
        # This is a subscription validation request
        send_resp(conn, 200, validation_token)
        {:ok, :validation}

      _ ->
        # This is a regular webhook notification
        # In production, you'd verify the signature and tenant
        :ok
    end
  end
end
