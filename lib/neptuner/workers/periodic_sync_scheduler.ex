defmodule Neptuner.Workers.PeriodicSyncScheduler do
  @moduledoc """
  Schedules periodic synchronization jobs for active connections.
  Ensures users' productivity data stays fresh with cosmic regularity.
  """

  use GenServer
  require Logger
  alias Neptuner.Workers.SyncWorker

  # Sync every 2 hours
  @sync_interval :timer.hours(2)
  # Check for token refresh every hour
  @token_refresh_interval :timer.hours(1)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule initial sync and token refresh
    schedule_periodic_sync()
    schedule_token_refresh()

    Logger.info("Periodic sync scheduler started - cosmic data synchronization initiated")
    {:ok, %{last_sync: DateTime.utc_now()}}
  end

  @impl true
  def handle_info(:periodic_sync, state) do
    Logger.info("Running periodic sync for all active connections")

    # Get all users with active connections and schedule their syncs
    active_users = get_users_with_active_connections()

    Enum.each(active_users, fn user_id ->
      # Stagger sync jobs to avoid overwhelming APIs
      # Random delay up to 5 minutes
      delay = :rand.uniform(300)
      SyncWorker.schedule_user_sync(user_id, delay: delay)
    end)

    Logger.info("Scheduled periodic sync for #{length(active_users)} users")

    # Schedule next periodic sync
    schedule_periodic_sync()

    {:noreply, %{state | last_sync: DateTime.utc_now()}}
  end

  @impl true
  def handle_info(:token_refresh, state) do
    Logger.info("Running periodic token refresh check")

    # Schedule token refresh job
    SyncWorker.schedule_token_refresh()

    # Schedule next token refresh check
    schedule_token_refresh()

    {:noreply, state}
  end

  @impl true
  def handle_call(:force_sync, _from, state) do
    Logger.info("Force sync requested - initiating immediate sync for all users")

    active_users = get_users_with_active_connections()

    Enum.each(active_users, fn user_id ->
      SyncWorker.schedule_user_sync(user_id, delay: 0)
    end)

    {:reply, {:ok, length(active_users)}, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      last_sync: state.last_sync,
      uptime: DateTime.diff(DateTime.utc_now(), state.last_sync, :second),
      active_connections: count_active_connections()
    }

    {:reply, status, state}
  end

  @doc """
  Manually trigger a sync for all users (useful for testing or admin actions).
  """
  def force_sync do
    GenServer.call(__MODULE__, :force_sync)
  end

  @doc """
  Get the current status of the periodic sync scheduler.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # Private functions

  defp schedule_periodic_sync do
    Process.send_after(self(), :periodic_sync, @sync_interval)
  end

  defp schedule_token_refresh do
    Process.send_after(self(), :token_refresh, @token_refresh_interval)
  end

  defp get_users_with_active_connections do
    # Get unique user IDs with active, sync-enabled connections
    alias Neptuner.Connections.ServiceConnection
    import Ecto.Query

    ServiceConnection
    |> where([sc], sc.connection_status == :active and sc.sync_enabled == true)
    |> select([sc], sc.user_id)
    |> distinct(true)
    |> Neptuner.Repo.all()
  end

  defp count_active_connections do
    alias Neptuner.Connections.ServiceConnection
    import Ecto.Query

    ServiceConnection
    |> where([sc], sc.connection_status == :active and sc.sync_enabled == true)
    |> Neptuner.Repo.aggregate(:count, :id)
  end
end
