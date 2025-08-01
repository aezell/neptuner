defmodule NeptunerWeb.ConnectionsLive.Index do
  use NeptunerWeb, :live_view

  alias Neptuner.Connections

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    connections = Connections.list_service_connections(current_user.id)

    {:ok,
     socket
     |> assign(:connections, connections)
     |> assign(:page_title, "Service Connections")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Service Connections")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-2xl font-semibold text-gray-900">Service Connections</h1>
            <p class="mt-2 text-sm text-gray-700">
              Connect your accounts to sync calendars, emails, and tasks. Because apparently we need to connect everything to everything else in the grand theater of digital productivity.
            </p>
          </div>
        </div>
        
    <!-- Connection Statistics -->
        <div class="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-3">
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <.icon name="hero-link" class="h-8 w-8 text-gray-400" />
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Connected Services</dt>
                    <dd class="text-lg font-medium text-gray-900">{length(@connections)}</dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <.icon name="hero-check-circle" class="h-8 w-8 text-green-400" />
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Active Connections</dt>
                    <dd class="text-lg font-medium text-gray-900">
                      {Enum.count(@connections, &(&1.connection_status == :active))}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <.icon name="hero-exclamation-triangle" class="h-8 w-8 text-yellow-400" />
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-sm font-medium text-gray-500 truncate">Need Attention</dt>
                    <dd class="text-lg font-medium text-gray-900">
                      {Enum.count(@connections, &(&1.connection_status in [:expired, :error]))}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Add New Connection -->
        <div class="mt-8 bg-white shadow sm:rounded-md">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Connect New Service</h3>
            <div class="mt-2 max-w-xl text-sm text-gray-500">
              <p>
                Expand your digital surveillance network by connecting additional productivity monitoring services.
              </p>
            </div>
            <div class="mt-5">
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for {provider, provider_name} <- [{"google", "Google"}, {"microsoft", "Microsoft"}, {"apple", "Apple"}] do %>
                  <div class="relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm hover:border-gray-400">
                    <div class="flex items-center space-x-3">
                      <div class="flex-shrink-0">
                        <.provider_icon provider={provider} />
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium text-gray-900">{provider_name}</p>
                        <div class="mt-2 space-y-1">
                          <%= if provider != "apple" do %>
                            <.link
                              href={~p"/oauth/#{provider}/connect?service_type=calendar"}
                              class="inline-flex items-center px-2.5 py-1.5 border border-transparent text-xs font-medium rounded text-indigo-700 bg-indigo-100 hover:bg-indigo-200"
                            >
                              Calendar
                            </.link>
                            <.link
                              href={~p"/oauth/#{provider}/connect?service_type=email"}
                              class="inline-flex items-center px-2.5 py-1.5 border border-transparent text-xs font-medium rounded text-indigo-700 bg-indigo-100 hover:bg-indigo-200 ml-2"
                            >
                              Email
                            </.link>
                          <% else %>
                            <.link
                              href={~p"/oauth/#{provider}/connect?service_type=calendar"}
                              class="inline-flex items-center px-2.5 py-1.5 border border-transparent text-xs font-medium rounded text-indigo-700 bg-indigo-100 hover:bg-indigo-200"
                            >
                              Calendar
                            </.link>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
                <!-- CalDAV Connection -->
                <div class="relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm hover:border-gray-400">
                  <div class="flex items-center space-x-3">
                    <div class="flex-shrink-0">
                      <.provider_icon provider="caldav" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium text-gray-900">CalDAV</p>
                      <div class="mt-2 space-y-1">
                        <.link
                          navigate={~p"/connections/caldav/new"}
                          class="inline-flex items-center px-2.5 py-1.5 border border-transparent text-xs font-medium rounded text-indigo-700 bg-indigo-100 hover:bg-indigo-200"
                        >
                          Calendar
                        </.link>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Existing Connections -->
        <div class="mt-8">
          <div class="shadow sm:rounded-md">
            <div class="px-4 py-5 sm:p-6 bg-white sm:rounded-t-md">
              <h3 class="text-lg leading-6 font-medium text-gray-900">Your Connected Services</h3>
              <div class="mt-2 max-w-xl text-sm text-gray-500">
                <p>
                  The digital tentacles of your productivity apparatus, reaching into various corporate data silos.
                </p>
              </div>
            </div>

            <%= if @connections == [] do %>
              <div class="bg-gray-50 px-4 py-5 sm:p-6 sm:rounded-b-md">
                <div class="text-center">
                  <.icon name="hero-link-slash" class="mx-auto h-12 w-12 text-gray-400" />
                  <h3 class="mt-2 text-sm font-medium text-gray-900">No connections yet</h3>
                  <p class="mt-1 text-sm text-gray-500">
                    Your digital life remains blissfully fragmented. For now.
                  </p>
                </div>
              </div>
            <% else %>
              <ul role="list" class="divide-y divide-gray-200">
                <%= for connection <- @connections do %>
                  <li class="px-4 py-4 sm:px-6">
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <div class="flex-shrink-0">
                          <.provider_icon provider={Atom.to_string(connection.provider)} />
                        </div>
                        <div class="ml-4">
                          <div class="flex items-center">
                            <p class="text-sm font-medium text-gray-900">
                              {connection.display_name}
                            </p>
                            <.connection_status_badge status={connection.connection_status} />
                          </div>
                          <p class="text-sm text-gray-500">
                            {String.capitalize(Atom.to_string(connection.provider))}
                            {String.capitalize(Atom.to_string(connection.service_type))}
                          </p>
                          <%= if connection.last_sync_at do %>
                            <p class="text-xs text-gray-400">
                              Last synced: {Calendar.strftime(
                                connection.last_sync_at,
                                "%B %d at %I:%M %p"
                              )}
                            </p>
                          <% end %>
                        </div>
                      </div>
                      <div class="flex items-center space-x-2">
                        <.link
                          href={~p"/oauth/#{connection.id}/disconnect"}
                          method="delete"
                          data-confirm="Are you sure you want to disconnect this account?"
                          class="inline-flex items-center px-2.5 py-1.5 border border-gray-300 text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
                        >
                          Disconnect
                        </.link>
                      </div>
                    </div>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </div>
        </div>
        
    <!-- Philosophical Footer -->
        <div class="mt-8 bg-gray-50 rounded-lg p-6">
          <div class="flex">
            <div class="flex-shrink-0">
              <.icon name="hero-light-bulb" class="h-5 w-5 text-gray-400" />
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-gray-800">Cosmic Perspective</h3>
              <div class="mt-2 text-sm text-gray-600">
                <p>
                  Each connection represents another stream of data about your existence being processed by algorithms designed to optimize metrics that may or may not correlate with human flourishing. But hey, at least you'll know exactly how many meetings could have been emails.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp provider_icon(%{provider: "google"}) do
    assigns = %{}

    ~H"""
    <div class="w-8 h-8 bg-red-100 rounded-full flex items-center justify-center">
      <span class="text-red-600 font-bold text-sm">G</span>
    </div>
    """
  end

  defp provider_icon(%{provider: "microsoft"}) do
    assigns = %{}

    ~H"""
    <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
      <span class="text-blue-600 font-bold text-sm">M</span>
    </div>
    """
  end

  defp provider_icon(%{provider: "apple"}) do
    assigns = %{}

    ~H"""
    <div class="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
      <span class="text-gray-700 font-bold text-sm">🍎</span>
    </div>
    """
  end

  defp provider_icon(%{provider: "caldav"}) do
    assigns = %{}

    ~H"""
    <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
      <span class="text-green-600 font-bold text-sm">📅</span>
    </div>
    """
  end

  defp provider_icon(assigns) when is_map(assigns) do
    provider_icon(%{provider: assigns[:provider] || "unknown"})
  end

  defp provider_icon(provider) when is_binary(provider) do
    provider_icon(%{provider: provider})
  end

  defp connection_status_badge(%{status: :active}) do
    assigns = %{}

    ~H"""
    <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
      Active
    </span>
    """
  end

  defp connection_status_badge(%{status: :expired}) do
    assigns = %{}

    ~H"""
    <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
      Expired
    </span>
    """
  end

  defp connection_status_badge(%{status: :error}) do
    assigns = %{}

    ~H"""
    <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
      Error
    </span>
    """
  end

  defp connection_status_badge(%{status: :disconnected}) do
    assigns = %{}

    ~H"""
    <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
      Disconnected
    </span>
    """
  end

  defp connection_status_badge(assigns) when is_map(assigns) do
    connection_status_badge(%{status: assigns[:status] || :unknown})
  end

  defp connection_status_badge(status) when is_atom(status) do
    connection_status_badge(%{status: status})
  end
end
