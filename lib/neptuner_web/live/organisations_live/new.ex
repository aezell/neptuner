defmodule NeptunerWeb.OrganisationsLive.New do
  use NeptunerWeb, :live_view

  alias Neptuner.Organisations
  alias Neptuner.Organisations.Organisation

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="bg-base-100 p-6 border border-base-200 rounded-xl">
          <.header>
            Create your organisation
            <:subtitle>
              You need to create an organisation to continue.
              This will be your workspace for managing your account.
            </:subtitle>
          </.header>

          <.form for={@form} id="organisation_form" phx-submit="save" phx-change="validate">
            <.input
              field={@form[:name]}
              type="text"
              label="Organisation Name"
              placeholder="Enter your organisation name"
              required
              phx-mounted={JS.focus()}
            />

            <.button variant="primary" phx-disable-with="Creating organisation..." class="w-full">
              Create Organisation
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Organisations.change_organisation(%Organisation{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"organisation" => organisation_params}, socket) do
    user = socket.assigns.current_scope.user

    case Organisations.create_organisation_with_owner(organisation_params, user) do
      {:ok, organisation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organisation \"#{organisation.name}\" created successfully!")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"organisation" => organisation_params}, socket) do
    changeset = Organisations.change_organisation(%Organisation{}, organisation_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "organisation")
    assign(socket, form: form)
  end
end
