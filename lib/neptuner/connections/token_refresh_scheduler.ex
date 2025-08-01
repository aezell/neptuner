defmodule Neptuner.Connections.TokenRefreshScheduler do
  use GenServer
  require Logger

  alias Neptuner.Connections.TokenRefreshWorker

  # Check every hour
  @refresh_interval :timer.hours(1)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule first check
    schedule_check()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_tokens, state) do
    Logger.info("Checking for tokens needing refresh")

    # Refresh any expired tokens immediately
    TokenRefreshWorker.refresh_all_expired_tokens()

    # Schedule next check
    schedule_check()

    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_tokens, @refresh_interval)
  end
end
