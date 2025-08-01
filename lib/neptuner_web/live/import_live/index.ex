defmodule NeptunerWeb.ImportLive.Index do
  use NeptunerWeb, :live_view
  alias Neptuner.Integrations.ImportTools

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:step, :select_source)
     |> assign(:source_type, nil)
     |> assign(:import_file, nil)
     |> assign(:preview_data, nil)
     |> assign(:import_result, nil)
     |> assign(:uploading, false)
     |> allow_upload(:import_file,
       accept: ~w(.json .csv .txt),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  def handle_event("select_source", %{"source" => source}, socket) do
    {:noreply,
     socket
     |> assign(:source_type, String.to_atom(source))
     |> assign(:step, :upload_file)}
  end

  def handle_event("back_to_source", _, socket) do
    {:noreply,
     socket
     |> assign(:step, :select_source)
     |> assign(:source_type, nil)
     |> assign(:preview_data, nil)
     |> assign(:import_result, nil)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :import_file, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)

    case uploaded_files do
      [file_content] ->
        source_type = Atom.to_string(socket.assigns.source_type)

        case ImportTools.preview_import(file_content, source_type) do
          {:ok, preview} ->
            {:noreply,
             socket
             |> assign(:preview_data, preview)
             |> assign(:import_file, file_content)
             |> assign(:step, :preview_and_confirm)}

          {:error, reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to preview import: #{inspect(reason)}")
             |> assign(:step, :upload_file)}
        end

      [] ->
        {:noreply,
         socket
         |> put_flash(:error, "No file uploaded")
         |> assign(:step, :upload_file)}
    end
  end

  def handle_event("confirm_import", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    source_type = socket.assigns.source_type
    file_content = socket.assigns.import_file

    result =
      case source_type do
        :todoist ->
          ImportTools.import_from_todoist(user_id, file_content)

        :notion ->
          ImportTools.import_from_notion(user_id, file_content)

        :apple_reminders ->
          ImportTools.import_from_apple_reminders(user_id, file_content)

        :csv ->
          ImportTools.import_from_csv(user_id, file_content)

        :json ->
          ImportTools.import_habits_from_json(user_id, file_content)
      end

    if result[:success] do
      {:noreply,
       socket
       |> assign(:import_result, result)
       |> assign(:step, :import_complete)
       |> put_flash(:info, "Successfully imported #{result[:imported_count]} items!")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Import failed: #{result[:error]}")
       |> assign(:step, :preview_and_confirm)}
    end
  end

  def handle_event("start_over", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :select_source)
     |> assign(:source_type, nil)
     |> assign(:import_file, nil)
     |> assign(:preview_data, nil)
     |> assign(:import_result, nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto">
        <div class="mb-8">
          <.header>Import & Migration Wizard</.header>
          <p class="mt-2 text-sm text-gray-600">
            Migrate your productivity data from other apps into the cosmic realm of Neptuner
          </p>
        </div>
        
    <!-- Progress Steps -->
        <div class="mb-8">
          <div class="flex items-center justify-between">
            <div class={step_class(@step, :select_source)}>
              <div class="flex items-center">
                <div class="flex items-center justify-center w-8 h-8 rounded-full border-2 border-cosmic-300 bg-white">
                  <span class="text-sm font-medium text-cosmic-600">1</span>
                </div>
                <span class="ml-2 text-sm font-medium text-gray-900">Select Source</span>
              </div>
            </div>

            <div class={step_class(@step, :upload_file)}>
              <div class="flex items-center">
                <div class="flex items-center justify-center w-8 h-8 rounded-full border-2 border-cosmic-300 bg-white">
                  <span class="text-sm font-medium text-cosmic-600">2</span>
                </div>
                <span class="ml-2 text-sm font-medium text-gray-900">Upload File</span>
              </div>
            </div>

            <div class={step_class(@step, :preview_and_confirm)}>
              <div class="flex items-center">
                <div class="flex items-center justify-center w-8 h-8 rounded-full border-2 border-cosmic-300 bg-white">
                  <span class="text-sm font-medium text-cosmic-600">3</span>
                </div>
                <span class="ml-2 text-sm font-medium text-gray-900">Preview & Confirm</span>
              </div>
            </div>

            <div class={step_class(@step, :import_complete)}>
              <div class="flex items-center">
                <div class="flex items-center justify-center w-8 h-8 rounded-full border-2 border-cosmic-300 bg-white">
                  <span class="text-sm font-medium text-cosmic-600">4</span>
                </div>
                <span class="ml-2 text-sm font-medium text-gray-900">Complete</span>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow border border-gray-200 p-6">
          <%= case @step do %>
            <% :select_source -> %>
              <.source_selection_step />
            <% :upload_file -> %>
              <.file_upload_step source_type={@source_type} uploads={@uploads} />
            <% :preview_and_confirm -> %>
              <.preview_and_confirm_step source_type={@source_type} preview_data={@preview_data} />
            <% :import_complete -> %>
              <.import_complete_step import_result={@import_result} />
          <% end %>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end

  defp step_class(current_step, step) do
    if current_step == step do
      "flex items-center text-cosmic-600"
    else
      "flex items-center text-gray-400"
    end
  end

  defp source_selection_step(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Choose Your Migration Source</h3>
      <p class="text-sm text-gray-600 mb-6">
        Select the productivity app you want to migrate from. The universe awaits your digital consciousness transfer.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <.source_card
          source="todoist"
          title="Todoist"
          description="Import tasks with priorities and projects"
          icon="hero-check-circle"
          file_format="JSON export file"
        />

        <.source_card
          source="notion"
          title="Notion"
          description="Import tasks and habits from database exports"
          icon="hero-document-text"
          file_format="JSON database export"
        />

        <.source_card
          source="apple_reminders"
          title="Apple Reminders"
          description="Import reminders from your Apple ecosystem"
          icon="hero-device-phone-mobile"
          file_format="JSON or plist export"
        />

        <.source_card
          source="csv"
          title="Generic CSV"
          description="Import from any app that exports CSV"
          icon="hero-table-cells"
          file_format="CSV file with headers"
        />

        <.source_card
          source="json"
          title="Generic JSON"
          description="Import habits from JSON format"
          icon="hero-code-bracket"
          file_format="JSON array format"
        />
      </div>
    </div>
    """
  end

  defp source_card(assigns) do
    ~H"""
    <button
      phx-click="select_source"
      phx-value-source={@source}
      class="p-4 border border-gray-200 rounded-lg hover:border-cosmic-300 hover:bg-cosmic-50 transition-colors text-left"
    >
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0">
          <div class="w-10 h-10 bg-cosmic-100 rounded-lg flex items-center justify-center">
            <.icon name={@icon} class="w-6 h-6 text-cosmic-600" />
          </div>
        </div>
        <div class="flex-1">
          <h4 class="text-sm font-semibold text-gray-900">{@title}</h4>
          <p class="text-xs text-gray-600 mt-1">{@description}</p>
          <p class="text-xs text-cosmic-600 mt-2 font-medium">Format: {@file_format}</p>
        </div>
      </div>
    </button>
    """
  end

  defp file_upload_step(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900">
          Upload Your {@source_type |> Atom.to_string() |> String.capitalize()} Export
        </h3>
        <button phx-click="back_to_source" class="text-sm text-cosmic-600 hover:text-cosmic-700">
          ← Change Source
        </button>
      </div>

      <.upload_instructions source_type={@source_type} />

      <div class="mt-6">
        <.live_file_input upload={@uploads.import_file} class="hidden" />

        <div
          class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-cosmic-300 transition-colors cursor-pointer"
          phx-drop-target={@uploads.import_file.ref}
          onclick="document.querySelector('input[type=file]').click()"
        >
          <.icon name="hero-cloud-arrow-up" class="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <p class="text-sm text-gray-600 mb-2">
            Click to upload or drag and drop your export file
          </p>
          <p class="text-xs text-gray-500">
            Maximum file size: 10MB
          </p>
        </div>

        <%= for entry <- @uploads.import_file.entries do %>
          <div class="mt-4 p-3 bg-gray-50 rounded border">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-2">
                <.icon name="hero-document" class="w-4 h-4 text-gray-500" />
                <span class="text-sm text-gray-900">{entry.client_name}</span>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-24 bg-gray-200 rounded-full h-2">
                  <div
                    class="bg-cosmic-600 h-2 rounded-full transition-all"
                    style={"width: #{entry.progress}%"}
                  >
                  </div>
                </div>
                <span class="text-xs text-gray-600">{entry.progress}%</span>
              </div>
            </div>

            <%= if entry.progress == 100 do %>
              <div class="mt-2">
                <button
                  phx-click="upload"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-cosmic-600 hover:bg-cosmic-700"
                >
                  <.icon name="hero-eye" class="w-4 h-4 mr-2" /> Preview Import
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp upload_instructions(assigns) do
    ~H"""
    <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
      <h4 class="text-sm font-semibold text-blue-900 mb-2">
        How to export from {@source_type |> Atom.to_string() |> String.capitalize()}
      </h4>
      <%= case @source_type do %>
        <% :todoist -> %>
          <ol class="text-sm text-blue-800 space-y-1 list-decimal list-inside">
            <li>Go to Todoist Settings → Backups</li>
            <li>Click "Create backup" to generate a JSON export</li>
            <li>Download the backup file and upload it here</li>
          </ol>
        <% :notion -> %>
          <ol class="text-sm text-blue-800 space-y-1 list-decimal list-inside">
            <li>Open your Notion task database</li>
            <li>Click the "..." menu → Export</li>
            <li>Select "JSON" format and export</li>
            <li>Upload the exported JSON file here</li>
          </ol>
        <% :apple_reminders -> %>
          <ol class="text-sm text-blue-800 space-y-1 list-decimal list-inside">
            <li>Use a third-party export tool to export Apple Reminders</li>
            <li>Export in JSON format if possible</li>
            <li>Upload the exported file here</li>
          </ol>
        <% :csv -> %>
          <ol class="text-sm text-blue-800 space-y-1 list-decimal list-inside">
            <li>Export your tasks to CSV format</li>
            <li>Ensure columns: title, description, priority, due_date, completed</li>
            <li>Upload the CSV file here</li>
          </ol>
        <% :json -> %>
          <ol class="text-sm text-blue-800 space-y-1 list-decimal list-inside">
            <li>Export your habits to JSON array format</li>
            <li>Include fields: name, description, frequency, category</li>
            <li>Upload the JSON file here</li>
          </ol>
      <% end %>
    </div>
    """
  end

  defp preview_and_confirm_step(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Preview Your Import</h3>

      <div class="bg-cosmic-50 border border-cosmic-200 rounded-lg p-4 mb-6">
        <p class="text-sm text-cosmic-800 italic">{@preview_data.cosmic_preview}</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div class="text-center p-4 bg-gray-50 rounded-lg">
          <div class="text-2xl font-bold text-gray-900">{@preview_data.total_items}</div>
          <div class="text-sm text-gray-600">Total Items</div>
        </div>

        <div class="text-center p-4 bg-gray-50 rounded-lg">
          <div class="text-2xl font-bold text-green-600">{@preview_data.completed_items}</div>
          <div class="text-sm text-gray-600">Completed</div>
        </div>

        <div class="text-center p-4 bg-gray-50 rounded-lg">
          <div class="text-2xl font-bold text-blue-600">
            {@preview_data.total_items - @preview_data.completed_items}
          </div>
          <div class="text-sm text-gray-600">Pending</div>
        </div>
      </div>

      <%= if length(@preview_data.sample_tasks) > 0 do %>
        <div class="mb-6">
          <h4 class="text-sm font-semibold text-gray-900 mb-3">Sample Items</h4>
          <div class="space-y-2">
            <div
              :for={task <- @preview_data.sample_tasks}
              class="p-3 bg-gray-50 rounded border-l-4 border-cosmic-300"
            >
              <div class="flex items-center justify-between">
                <div class="flex-1">
                  <h5 class="text-sm font-medium text-gray-900">{task.title}</h5>
                  <%= if task.description && task.description != "" do %>
                    <p class="text-xs text-gray-600 mt-1">{task.description}</p>
                  <% end %>
                </div>
                <div class="flex items-center space-x-2">
                  <.cosmic_priority_badge priority={task.priority} />
                  <%= if task.completed do %>
                    <.icon name="hero-check-circle" class="w-4 h-4 text-green-500" />
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <div class="flex items-center justify-between">
        <button
          phx-click="back_to_source"
          class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
        >
          ← Start Over
        </button>

        <button
          phx-click="confirm_import"
          class="inline-flex items-center px-6 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-cosmic-600 hover:bg-cosmic-700"
        >
          <.icon name="hero-rocket-launch" class="w-4 h-4 mr-2" /> Confirm Cosmic Migration
        </button>
      </div>
    </div>
    """
  end

  defp import_complete_step(assigns) do
    ~H"""
    <div class="text-center">
      <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <.icon name="hero-check-circle" class="w-8 h-8 text-green-600" />
      </div>

      <h3 class="text-lg font-semibold text-gray-900 mb-2">Migration Complete!</h3>
      <p class="text-sm text-gray-600 mb-6">
        Successfully imported {@import_result.imported_count} items into your cosmic productivity realm.
      </p>

      <div class="bg-cosmic-50 border border-cosmic-200 rounded-lg p-4 mb-6">
        <h4 class="text-sm font-semibold text-cosmic-900 mb-2">Cosmic Insights</h4>
        <p class="text-sm text-cosmic-800 italic mb-2">{@import_result.cosmic_insight.primary}</p>
        <p class="text-sm text-cosmic-700">{@import_result.cosmic_insight.philosophical}</p>
        <p class="text-xs text-cosmic-600 mt-2">{@import_result.cosmic_insight.gratitude}</p>
      </div>

      <div class="flex items-center justify-center space-x-4">
        <.link
          navigate={~p"/tasks"}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-cosmic-600 hover:bg-cosmic-700"
        >
          <.icon name="hero-check-circle" class="w-4 h-4 mr-2" /> View Tasks
        </.link>

        <.link
          navigate={~p"/dashboard"}
          class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
        >
          <.icon name="hero-home" class="w-4 h-4 mr-2" /> Dashboard
        </.link>

        <button
          phx-click="start_over"
          class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
        >
          <.icon name="hero-arrow-path" class="w-4 h-4 mr-2" /> Import More
        </button>
      </div>
    </div>
    """
  end

  defp cosmic_priority_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium",
      case @priority do
        :matters_10_years -> "bg-red-100 text-red-800"
        :matters_10_days -> "bg-yellow-100 text-yellow-800"
        :matters_to_nobody -> "bg-gray-100 text-gray-800"
        _ -> "bg-gray-100 text-gray-800"
      end
    ]}>
      {case @priority do
        :matters_10_years -> "10 Years"
        :matters_10_days -> "10 Days"
        :matters_to_nobody -> "To Nobody"
        _ -> "Unknown"
      end}
    </span>
    """
  end
end
