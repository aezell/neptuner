defmodule Neptuner.Workers.SyncWorker do
  @moduledoc """
  Background worker for synchronizing data from connected services.
  Handles Google Calendar, Gmail, Microsoft services, and other integrations.
  """

  use Oban.Worker, queue: :sync, max_attempts: 3

  require Logger
  alias Neptuner.{Connections, Integrations}
  alias Neptuner.Connections.ServiceConnection
  alias Neptuner.Integrations.IntegrationCoordinator

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "sync_connection", "connection_id" => connection_id}}) do
    case Connections.get_service_connection!(connection_id) do
      %ServiceConnection{} = connection ->
        sync_connection(connection)

      nil ->
        Logger.warning("Connection #{connection_id} not found for sync")
        {:error, :connection_not_found}
    end
  rescue
    error ->
      Logger.error("Sync worker failed for connection #{connection_id}: #{inspect(error)}")
      {:error, error}
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "sync_all_connections", "user_id" => user_id}}) do
    user_id
    |> Connections.list_service_connections()
    |> Enum.filter(&(&1.sync_enabled and &1.connection_status == :active))
    |> Enum.each(fn connection ->
      # Schedule individual sync jobs to avoid timeout
      schedule_connection_sync(connection, delay: :rand.uniform(60))
    end)

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "refresh_expired_tokens"}}) do
    Connections.get_connections_needing_refresh()
    |> Enum.each(fn connection ->
      case Connections.refresh_service_connection_token(connection) do
        {:ok, updated_connection} ->
          Logger.info("Refreshed token for connection #{connection.id}")
          # Schedule sync after successful refresh
          schedule_connection_sync(updated_connection, delay: 30)

        {:error, reason} ->
          Logger.warning(
            "Failed to refresh token for connection #{connection.id}: #{inspect(reason)}"
          )
      end
    end)

    :ok
  end

  @doc """
  Schedules a sync job for a specific connection.
  """
  def schedule_connection_sync(%ServiceConnection{} = connection, opts \\ []) do
    delay = Keyword.get(opts, :delay, 0)

    %{
      "type" => "sync_connection",
      "connection_id" => connection.id
    }
    |> __MODULE__.new(schedule_in: delay)
    |> Oban.insert()
  end

  @doc """
  Schedules sync jobs for all connections for a user.
  """
  def schedule_user_sync(user_id, opts \\ []) do
    delay = Keyword.get(opts, :delay, 0)

    %{
      "type" => "sync_all_connections",
      "user_id" => user_id
    }
    |> __MODULE__.new(schedule_in: delay)
    |> Oban.insert()
  end

  @doc """
  Schedules periodic token refresh job.
  """
  def schedule_token_refresh(opts \\ []) do
    delay = Keyword.get(opts, :delay, 0)

    %{
      "type" => "refresh_expired_tokens"
    }
    |> __MODULE__.new(schedule_in: delay)
    |> Oban.insert()
  end

  # Private functions

  defp sync_connection(
         %ServiceConnection{provider: :google, service_type: :calendar} = connection
       ) do
    Logger.info("Syncing Google Calendar for connection #{connection.id}")

    case Integrations.GoogleCalendar.sync_calendar_events(connection) do
      {:ok, count} ->
        Logger.info(
          "Successfully synced #{count} calendar events for connection #{connection.id}"
        )

        :ok

      {:error, reason} ->
        Logger.error(
          "Google Calendar sync failed for connection #{connection.id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp sync_connection(%ServiceConnection{provider: :google, service_type: :email} = connection) do
    Logger.info("Syncing Gmail for connection #{connection.id}")

    case Integrations.Gmail.sync_email_summaries(connection) do
      {:ok, count} ->
        Logger.info(
          "Successfully synced #{count} email summaries for connection #{connection.id}"
        )

        :ok

      {:error, reason} ->
        Logger.error("Gmail sync failed for connection #{connection.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sync_connection(
         %ServiceConnection{provider: :microsoft, service_type: :calendar} = connection
       ) do
    Logger.info("Syncing Microsoft Calendar for connection #{connection.id}")

    case Integrations.MicrosoftCalendar.sync_calendar_events(connection) do
      {:ok, count} ->
        Logger.info(
          "Successfully synced #{count} calendar events for connection #{connection.id}"
        )

        :ok

      {:error, reason} ->
        Logger.error(
          "Microsoft Calendar sync failed for connection #{connection.id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp sync_connection(
         %ServiceConnection{provider: :microsoft, service_type: :email} = connection
       ) do
    Logger.info("Syncing Microsoft Outlook for connection #{connection.id}")

    case Integrations.MicrosoftOutlook.sync_email_summaries(connection) do
      {:ok, count} ->
        Logger.info(
          "Successfully synced #{count} email summaries for connection #{connection.id}"
        )

        :ok

      {:error, reason} ->
        Logger.error(
          "Microsoft Outlook sync failed for connection #{connection.id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp sync_connection(%ServiceConnection{} = connection) do
    Logger.info(
      "Using IntegrationCoordinator for #{connection.provider}/#{connection.service_type} connection #{connection.id}"
    )

    case IntegrationCoordinator.sync_connection(connection) do
      {:ok, _provider, count} ->
        Logger.info("Successfully synced #{count} items for connection #{connection.id}")
        :ok

      {:error, _provider, reason} ->
        Logger.error("Sync failed for connection #{connection.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
