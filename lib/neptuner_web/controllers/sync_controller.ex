defmodule NeptunerWeb.SyncController do
  @moduledoc """
  Controller for manual data synchronization triggers.
  Useful for testing integrations and providing users manual sync options.
  """

  use NeptunerWeb, :controller
  alias Neptuner.Workers.SyncWorker
  alias Neptuner.{Connections, Integrations}
  require Logger

  @doc """
  Manually trigger sync for a specific connection.
  """
  def sync_connection(conn, %{"connection_id" => connection_id}) do
    user_id = conn.assigns.current_scope.user.id

    case Connections.get_service_connection!(connection_id) do
      connection when connection.user_id == user_id ->
        case SyncWorker.schedule_connection_sync(connection) do
          {:ok, _job} ->
            conn
            |> put_flash(
              :info,
              "Cosmic sync initiated! Your #{connection.provider} #{connection.service_type} data will be refreshed."
            )
            |> redirect(to: ~p"/connections")

          {:error, reason} ->
            Logger.error(
              "Failed to schedule sync for connection #{connection_id}: #{inspect(reason)}"
            )

            conn
            |> put_flash(
              :error,
              "Failed to initiate cosmic sync. The universe may be temporarily unavailable."
            )
            |> redirect(to: ~p"/connections")
        end

      _ ->
        conn
        |> put_flash(:error, "Connection not found in your cosmic realm.")
        |> redirect(to: ~p"/connections")
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_flash(:error, "Connection has transcended to a higher dimension.")
      |> redirect(to: ~p"/connections")
  end

  @doc """
  Manually trigger sync for all user's connections.
  """
  def sync_all_connections(conn, _params) do
    user_id = conn.assigns.current_scope.user.id

    case SyncWorker.schedule_user_sync(user_id) do
      {:ok, _job} ->
        conn
        |> put_flash(
          :info,
          "Universal sync initiated! All your cosmic connections will be refreshed."
        )
        |> redirect(to: ~p"/connections")

      {:error, reason} ->
        Logger.error("Failed to schedule user sync for user #{user_id}: #{inspect(reason)}")

        conn
        |> put_flash(
          :error,
          "Failed to initiate universal sync. The cosmic forces are temporarily misaligned."
        )
        |> redirect(to: ~p"/connections")
    end
  end

  @doc """
  Get sync status for user's connections.
  """
  def sync_status(conn, _params) do
    user_id = conn.assigns.current_scope.user.id
    connections = Connections.list_service_connections(user_id)

    connection_statuses =
      Enum.map(connections, fn connection ->
        %{
          id: connection.id,
          provider: connection.provider,
          service_type: connection.service_type,
          status: connection.connection_status,
          last_sync: connection.last_sync_at,
          sync_enabled: connection.sync_enabled
        }
      end)

    conn
    |> put_resp_content_type("application/json")
    |> json(%{
      connections: connection_statuses,
      total_connections: length(connections),
      active_connections: Enum.count(connections, &(&1.connection_status == :active)),
      last_universal_sync: get_most_recent_sync(connections)
    })
  end

  @doc """
  Test endpoint for checking Google Calendar integration.
  """
  def test_calendar_sync(conn, %{"connection_id" => connection_id}) do
    user_id = conn.assigns.current_scope.user.id

    case Connections.get_service_connection!(connection_id) do
      connection when connection.user_id == user_id and connection.service_type == :calendar ->
        case Integrations.GoogleCalendar.sync_calendar_events(connection) do
          {:ok, count} ->
            conn
            |> json(%{
              success: true,
              message: "Successfully synced #{count} calendar events",
              count: count
            })

          {:error, reason} ->
            conn
            |> put_status(422)
            |> json(%{
              success: false,
              error: "Calendar sync failed: #{inspect(reason)}"
            })
        end

      connection when connection.user_id == user_id ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          error: "Connection is not a calendar service"
        })

      _ ->
        conn
        |> put_status(404)
        |> json(%{
          success: false,
          error: "Connection not found"
        })
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(404)
      |> json(%{
        success: false,
        error: "Connection not found"
      })
  end

  @doc """
  Test endpoint for checking Gmail integration.
  """
  def test_email_sync(conn, %{"connection_id" => connection_id}) do
    user_id = conn.assigns.current_scope.user.id

    case Connections.get_service_connection!(connection_id) do
      connection when connection.user_id == user_id and connection.service_type == :email ->
        case Integrations.Gmail.sync_email_summaries(connection) do
          {:ok, count} ->
            conn
            |> json(%{
              success: true,
              message: "Successfully synced #{count} email summaries",
              count: count
            })

          {:error, reason} ->
            conn
            |> put_status(422)
            |> json(%{
              success: false,
              error: "Email sync failed: #{inspect(reason)}"
            })
        end

      connection when connection.user_id == user_id ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          error: "Connection is not an email service"
        })

      _ ->
        conn
        |> put_status(404)
        |> json(%{
          success: false,
          error: "Connection not found"
        })
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(404)
      |> json(%{
        success: false,
        error: "Connection not found"
      })
  end

  # Private functions

  defp get_most_recent_sync(connections) do
    connections
    |> Enum.map(& &1.last_sync_at)
    |> Enum.filter(&(&1 != nil))
    |> Enum.max(DateTime, fn -> nil end)
  end
end
