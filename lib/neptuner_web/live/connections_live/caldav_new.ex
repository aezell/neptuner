defmodule NeptunerWeb.ConnectionsLive.CalDAVNew do
  use NeptunerWeb, :live_view

  alias Neptuner.Connections.OAuthProviders

  @impl true
  def mount(_params, _session, socket) do
    changeset = change_caldav_connection(%{})

    {:ok,
     socket
     |> assign(:changeset, changeset)
     |> assign(:page_title, "Connect CalDAV Calendar")}
  end

  @impl true
  def handle_event("validate", %{"caldav_connection" => params}, socket) do
    changeset =
      %{}
      |> change_caldav_connection(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"caldav_connection" => params}, socket) do
    current_user = socket.assigns.current_scope.user

    attrs = %{
      username: params["username"],
      password: params["password"],
      server_url: params["server_url"]
    }

    case OAuthProviders.create_caldav_connection(current_user.id, attrs) do
      {:ok, _connection} ->
        {:noreply,
         socket
         |> put_flash(:info, "CalDAV calendar connected successfully!")
         |> push_navigate(to: ~p"/connections")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to connect CalDAV calendar: #{reason}")
         |> assign(:changeset, change_caldav_connection(attrs))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="bg-white shadow sm:rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Connect CalDAV Calendar</h3>
            <div class="mt-2 max-w-xl text-sm text-gray-500">
              <p>
                Connect your CalDAV-compatible calendar service (like iCloud, Nextcloud, or other self-hosted solutions).
              </p>
            </div>

            <.form
              for={@changeset}
              id="caldav-connection-form"
              phx-change="validate"
              phx-submit="save"
              class="mt-5"
            >
              <div class="space-y-4">
                <div>
                  <.input
                    field={@changeset[:server_url]}
                    type="url"
                    label="CalDAV Server URL"
                    placeholder="https://caldav.example.com/calendar/"
                    required
                  />
                  <p class="mt-1 text-xs text-gray-500">
                    The CalDAV server URL. For iCloud, use: https://caldav.icloud.com/
                  </p>
                </div>

                <div>
                  <.input
                    field={@changeset[:username]}
                    type="text"
                    label="Username/Email"
                    placeholder="your-email@example.com"
                    required
                  />
                </div>

                <div>
                  <.input
                    field={@changeset[:password]}
                    type="password"
                    label="Password/App Password"
                    placeholder="Enter your password or app-specific password"
                    required
                  />
                  <p class="mt-1 text-xs text-gray-500">
                    For iCloud, use an app-specific password. For other services, use your regular password or app password.
                  </p>
                </div>
              </div>

              <div class="mt-6 flex items-center justify-end space-x-3">
                <.link
                  navigate={~p"/connections"}
                  class="bg-white py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </.link>
                <.button type="submit" class="btn-primary">
                  Connect Calendar
                </.button>
              </div>
            </.form>
          </div>
        </div>
        
    <!-- Help Section -->
        <div class="mt-8 bg-blue-50 rounded-lg p-6">
          <div class="flex">
            <div class="flex-shrink-0">
              <.icon name="hero-information-circle" class="h-5 w-5 text-blue-400" />
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-blue-800">Connection Tips</h3>
              <div class="mt-2 text-sm text-blue-700">
                <ul class="list-disc list-inside space-y-1">
                  <li>
                    <strong>iCloud:</strong>
                    Use https://caldav.icloud.com/ and create an app-specific password
                  </li>
                  <li>
                    <strong>Google:</strong>
                    Use OAuth connection instead of CalDAV for better integration
                  </li>
                  <li>
                    <strong>Nextcloud:</strong>
                    Use https://your-nextcloud.com/remote.php/dav/calendars/username/
                  </li>
                  <li>
                    <strong>Self-hosted:</strong>
                    Check your server documentation for the correct CalDAV URL
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp change_caldav_connection(attrs, params \\ %{}) do
    types = %{
      server_url: :string,
      username: :string,
      password: :string
    }

    {attrs, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:server_url, :username, :password])
    |> Ecto.Changeset.validate_format(:server_url, ~r/^https?:\/\//,
      message: "must be a valid URL"
    )
    |> Ecto.Changeset.validate_length(:username, min: 1)
    |> Ecto.Changeset.validate_length(:password, min: 1)
  end
end
