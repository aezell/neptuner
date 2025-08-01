defmodule Neptuner.Connections.TokenRefreshWorker do
  use Oban.Worker, queue: :token_refresh, max_attempts: 3

  require Logger
  alias Neptuner.Connections
  alias Neptuner.Connections.OAuthProviders

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"connection_id" => connection_id}}) do
    connection = Connections.get_service_connection!(connection_id)
    refresh_connection_token(connection)
  rescue
    Ecto.NoResultsError ->
      Logger.warning("Token refresh job: Connection #{connection_id} not found, skipping")
      :ok
  end

  def schedule_refresh(connection) do
    # Schedule refresh 5 minutes before token expires
    refresh_time = DateTime.add(connection.token_expires_at, -300, :second)

    %{connection_id: connection.id}
    |> __MODULE__.new(scheduled_at: refresh_time)
    |> Oban.insert()
  end

  def refresh_all_expired_tokens do
    connections = Connections.get_connections_needing_refresh()

    Logger.info("Refreshing #{length(connections)} expired tokens")

    Enum.each(connections, &refresh_connection_token/1)
  end

  def refresh_connection_token(connection) do
    provider = Atom.to_string(connection.provider)

    case OAuthProviders.refresh_access_token(provider, connection.refresh_token) do
      {:ok, token_data} ->
        case Connections.refresh_connection_token(
               connection,
               token_data.access_token,
               token_data.refresh_token,
               token_data.expires_at
             ) do
          {:ok, updated_connection} ->
            Logger.info("Successfully refreshed token for connection #{connection.id}")

            # Schedule next refresh
            if updated_connection.token_expires_at do
              schedule_refresh(updated_connection)
            end

            :ok

          {:error, reason} ->
            Logger.error(
              "Failed to update connection #{connection.id} with new token: #{inspect(reason)}"
            )

            Connections.mark_connection_error(connection)
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error(
          "Failed to refresh token for connection #{connection.id}: #{inspect(reason)}"
        )

        Connections.mark_connection_expired(connection)
        {:error, reason}
    end
  end
end
