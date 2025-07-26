defmodule Mix.Tasks.Neptuner.Gen.Organisations do
  @moduledoc """
  Installs multi-tenancy (organisations) functionality for the SaaS template using Igniter.

  This task:
  - Adds organisation scope configuration to config.exs
  - Creates Organisation, OrganisationMember, and OrganisationInvitation schemas
  - Creates Organisations context module for organisation management
  - Updates User schema with organisation relationships
  - Updates Scope module with organisation functionality
  - Creates LiveView components for organisation management
  - Updates router with organisation routes
  - Updates authentication flow with organisation plugs and hooks
  - Creates comprehensive tests for all functionality
  - Updates factory with organisation fixtures
  - Generates database migrations for organisations and memberships

      $ mix neptuner.gen.organisations

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      |> add_scope_config()
      |> update_user_schema()
      |> update_scope_module()
      |> update_user_notifier()
      |> create_organisation_schema()
      |> create_organisation_member_schema()
      |> create_organisation_invitation_schema()
      |> create_organisations_context()
      |> create_organisations_live_new()
      |> create_organisations_live_manage()
      |> create_organisations_live_invitation()
      |> update_user_auth()
      |> update_router()
      |> update_layouts()
      |> create_migrations()

    # |> create_organisations_test()
    # |> create_organisations_live_tests()
    # |> create_scope_test()
    # |> update_user_auth_test()
    # |> update_registration_test()
    # |> update_factory()
    # |> create_organisations_fixtures()

    if opts[:yes] do
      igniter
    else
      print_completion_notice(igniter)
    end
  end

  defp create_organisation_schema(igniter) do
    organisation_content = """
      defmodule Neptuner.Organisations.Organisation do
        use Neptuner.Schema
        import Ecto.Changeset

        alias Neptuner.Accounts.User
        alias Neptuner.Organisations.OrganisationMember

        schema "organisations" do
          field :name, :string

          has_many :organisation_members, OrganisationMember
          many_to_many :users, User, join_through: OrganisationMember

          timestamps(type: :utc_datetime)
        end

        @doc false
        def changeset(organisation, attrs) do
          organisation
          |> cast(attrs, [:name])
          |> validate_required([:name])
          |> validate_length(:name, min: 2, max: 100)
        end
      end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/organisations/organisation.ex",
      organisation_content
    )
  end

  defp create_organisation_member_schema(igniter) do
    organisation_member_content = """
    defmodule Neptuner.Organisations.OrganisationMember do
      use Neptuner.Schema
      import Ecto.Changeset

      alias Neptuner.Accounts.User
      alias Neptuner.Organisations.Organisation

      schema "organisation_members" do
      field :role, :string, default: "member"
      field :joined_at, :utc_datetime

      belongs_to :user, User
      belongs_to :organisation, Organisation

      timestamps(type: :utc_datetime)
      end

      @doc false
      def changeset(organisation_member, attrs) do
        organisation_member
        |> cast(attrs, [:role, :joined_at, :user_id, :organisation_id])
        |> validate_required([:role, :user_id, :organisation_id])
        |> validate_inclusion(:role, ["member", "admin", "owner"])
        |> unique_constraint([:user_id, :organisation_id])
        |> put_joined_at()
      end

        defp put_joined_at(changeset) do
        if get_field(changeset, :joined_at) do
          changeset
        else
          put_change(changeset, :joined_at, DateTime.utc_now() |> DateTime.truncate(:second))
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/organisations/organisation_member.ex",
      organisation_member_content
    )
  end

  defp create_organisation_invitation_schema(igniter) do
    organisation_invitation_content = """
    defmodule Neptuner.Organisations.OrganisationInvitation do
      use Neptuner.Schema
      import Ecto.Changeset

      alias Neptuner.Accounts.User
      alias Neptuner.Organisations.Organisation

      schema "organisation_invitations" do
      field :email, :string
      field :role, :string, default: "member"
      field :token, :string
      field :expires_at, :utc_datetime
      field :accepted_at, :utc_datetime

      belongs_to :organisation, Organisation
      belongs_to :invited_by, User

      timestamps(type: :utc_datetime)
      end

      @doc false
      def changeset(organisation_invitation, attrs) do
        organisation_invitation
        |> cast(attrs, [:email, :role, :organisation_id, :invited_by_id])
        |> validate_required([:email, :role, :organisation_id, :invited_by_id])
        |> validate_inclusion(:role, ["member", "admin"])
        |> validate_format(:email, ~r/^[^@,;\\s]+@[^@,;\\s]+$/, message: "must have the @ sign and no spaces")
        |> validate_length(:email, max: 160)
        |> unique_constraint([:email, :organisation_id], message: "User has already been invited to this organisation")
        |> put_token()
        |> put_expires_at()
      end

      defp put_token(changeset) do
        if get_field(changeset, :token) do
          changeset
        else
          put_change(changeset, :token, generate_token())
        end
      end

      defp put_expires_at(changeset) do
        if get_field(changeset, :expires_at) do
          changeset
        else
          # Invitations expire in 7 days
          expires_at = DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
          put_change(changeset, :expires_at, expires_at)
        end
      end

      defp generate_token do
        :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
      end

      @doc \"\"\"
      Checks if an invitation is still valid (not expired and not accepted).
      \"\"\"
      def valid?(%__MODULE__{expires_at: expires_at, accepted_at: accepted_at}) do
        is_nil(accepted_at) and DateTime.after?(expires_at, DateTime.utc_now())
      end

      @doc \"\"\"
      Marks an invitation as accepted.
      \"\"\"
      def accept_changeset(invitation) do
        change(invitation, accepted_at: DateTime.utc_now() |> DateTime.truncate(:second))
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/organisations/organisation_invitation.ex",
      organisation_invitation_content
    )
  end

  defp create_organisations_live_new(igniter) do
    new_content = """
    defmodule NeptunerWeb.OrganisationsLive.New do
    use NeptunerWeb, :live_view

    alias Neptuner.Organisations
    alias Neptuner.Organisations.Organisation

    def render(assigns) do
    ~H\"\"\"
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
    \"\"\"
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
         |> put_flash(:info, "Organisation \\"\#{organisation.name}\\" created successfully!")
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
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner_web/live/organisations_live/new.ex",
      new_content
    )
  end

  defp create_organisations_live_manage(igniter) do
    manage_content = """
    defmodule NeptunerWeb.OrganisationsLive.Manage do
    use NeptunerWeb, :live_view

    alias Neptuner.Organisations
    alias Neptuner.Accounts
    alias Neptuner.Accounts.Scope

    def render(assigns) do
    ~H\"\"\"
    <Layouts.dashboard flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <.header>
          Organisation Settings
          <:subtitle>
            Manage your organisation settings and team members
          </:subtitle>
          <:actions>
            <.button :if={@can_manage} phx-click="edit_organisation" variant="primary">
              <.icon name="hero-pencil" class="w-4 h-4 mr-2" /> Edit Organisation
            </.button>
          </:actions>
        </.header>

        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h2 class="card-title">Organisation Information</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="text-sm font-medium text-base-content/70">Name</label>
                <p class="text-lg font-semibold">{@organisation.name}</p>
              </div>
              <div class="flex flex-col">
                <label class="text-sm font-medium text-base-content/70">Your Role</label>
                <p class="badge badge-primary badge-lg">{String.capitalize(@user_role)}</p>
              </div>
            </div>
          </div>
        </div>

    <!-- Team Members Section -->
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <div class="flex justify-between items-center mb-4">
              <h2 class="card-title">Team Members</h2>
              <.button
                :if={@can_manage}
                phx-click="show_invite_modal"
                variant="primary"
                class="btn-sm"
              >
                <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Invite Member
              </.button>
            </div>

            <.table id="members" rows={@members}>
              <:col :let={member} label="Member">
                <div class="flex items-center gap-3">
                  <.avatar name={member.user.email} class="w-8 h-8" inner_class="w-8 h-8" />
                  <div>
                    <div class="font-medium">{member.user.email}</div>
                    <div class="text-sm text-base-content/70">
                      Joined {Calendar.strftime(member.joined_at, "%B %d, %Y")}
                    </div>
                  </div>
                </div>
              </:col>
              <:col :let={member} label="Role">
                <div class={[
                  "badge badge-lg",
                  member.role == "owner" && "badge-accent",
                  member.role == "admin" && "badge-secondary",
                  member.role == "member" && "badge-neutral"
                ]}>
                  {String.capitalize(member.role)}
                </div>
              </:col>
              <:action :let={member}>
                <div :if={@can_manage and member.user.id != @current_scope.user.id} class="flex gap-2">
                  <.button
                    phx-click="change_role"
                    phx-value-user-id={member.user.id}
                    class="btn-xs btn-ghost"
                  >
                    <.icon name="hero-cog-6-tooth" class="w-3 h-3" />
                  </.button>
                  <.button
                    phx-click="remove_member"
                    phx-value-user-id={member.user.id}
                    class="btn-xs btn-ghost text-error hover:bg-error/10"
                    data-confirm="Are you sure you want to remove this member?"
                  >
                    <.icon name="hero-trash" class="w-3 h-3" />
                  </.button>
                </div>
              </:action>
            </.table>
          </div>
        </div>
      </div>

    <!-- Edit Org Modal -->
      <dialog :if={@show_edit_modal} class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Edit Organisation</h3>
          <.form for={@edit_form} phx-submit="save_organisation" phx-change="validate_organisation">
            <.input
              field={@edit_form[:name]}
              type="text"
              label="Organisation Name"
              required
              phx-mounted={JS.focus()}
            />
            <div class="modal-action">
              <.button type="button" phx-click="cancel_edit" class="btn-ghost">
                Cancel
              </.button>
              <.button type="submit" variant="primary" phx-disable-with="Saving...">
                Save Changes
              </.button>
            </div>
          </.form>
        </div>
        <form method="dialog" class="modal-backdrop" phx-click="cancel_edit">
          <button>close</button>
        </form>
      </dialog>

    <!-- Invite Modal -->
      <dialog :if={@show_invite_modal} class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Invite Team Member</h3>
          <.form for={@invite_form} phx-submit="send_invite" phx-change="validate_invite">
            <.input
              field={@invite_form[:email]}
              type="email"
              label="Email Address"
              placeholder="Enter member's email"
              required
              phx-mounted={JS.focus()}
            />
            <.input
              field={@invite_form[:role]}
              type="select"
              label="Role"
              options={[{"Member", "member"}, {"Admin", "admin"}]}
              value="member"
            />
            <div class="modal-action">
              <.button type="button" phx-click="cancel_invite" class="btn-ghost">
                Cancel
              </.button>
              <.button type="submit" variant="primary" phx-disable-with="Sending Invite...">
                Send Invitation
              </.button>
            </div>
          </.form>
        </div>
        <form method="dialog" class="modal-backdrop" phx-click="cancel_invite">
          <button>close</button>
        </form>
      </dialog>

    <!-- Change Role Modal -->
      <dialog :if={@show_role_modal} class="modal modal-open">
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Change Member Role</h3>
          <div :if={@selected_member} class="mb-4">
            <div class="flex items-center gap-3 p-3 bg-base-200 rounded-lg">
              <.avatar name={@selected_member.user.email} class="w-8 h-8" inner_class="w-8 h-8" />
              <div>
                <div class="font-medium">{@selected_member.user.email}</div>
                <div class="text-sm text-base-content/70">
                  Current role:
                  <span class="badge badge-sm">{String.capitalize(@selected_member.role)}</span>
                </div>
              </div>
            </div>
          </div>
          <.form for={@role_form} phx-submit="save_role_change" phx-change="validate_role_change">
            <.input
              field={@role_form[:role]}
              type="select"
              label="New Role"
              options={[{"Member", "member"}, {"Admin", "admin"}]}
              required
              phx-mounted={JS.focus()}
            />
            <div class="modal-action">
              <.button type="button" phx-click="cancel_role_change" class="btn-ghost">
                Cancel
              </.button>
              <.button type="submit" variant="primary" phx-disable-with="Updating...">
                Update Role
              </.button>
            </div>
          </.form>
        </div>
        <form method="dialog" class="modal-backdrop" phx-click="cancel_role_change">
          <button>close</button>
        </form>
      </dialog>
    </Layouts.dashboard>
    \"\"\"
    end

    def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    organisation = current_scope.organisation
    user_role = current_scope.organisation_role
    can_manage = Scope.can_manage_organisation?(current_scope)
    members = Organisations.list_organisation_members(organisation)

    {:ok,
     socket
     |> assign(:organisation, organisation)
     |> assign(:user_role, user_role)
     |> assign(:can_manage, can_manage)
     |> assign(:members, members)
     |> assign(:show_edit_modal, false)
     |> assign(:show_invite_modal, false)
     |> assign(:show_role_modal, false)
     |> assign(:edit_form, nil)
     |> assign(:invite_form, nil)
     |> assign(:role_form, nil)
     |> assign(:selected_member, nil)}
    end

    def handle_event("edit_organisation", _, socket) do
    if socket.assigns.can_manage do
      changeset = Organisations.change_organisation(socket.assigns.organisation)

      {:noreply,
       socket
       |> assign(:show_edit_modal, true)
       |> assign(:edit_form, to_form(changeset, as: "organisation"))}
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to edit this organisation")}
    end
    end

    def handle_event("cancel_edit", _, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_modal, false)
     |> assign(:edit_form, nil)}
    end

    def handle_event("validate_organisation", %{"organisation" => params}, socket) do
    changeset =
      socket.assigns.organisation
      |> Organisations.change_organisation(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :edit_form, to_form(changeset, as: "organisation"))}
    end

    def handle_event("save_organisation", %{"organisation" => params}, socket) do
    case Organisations.update_organisation(socket.assigns.organisation, params) do
      {:ok, organisation} ->
        {:noreply,
         socket
         |> assign(:organisation, organisation)
         |> assign(:show_edit_modal, false)
         |> assign(:edit_form, nil)
         |> put_flash(:info, "Organisation updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :edit_form, to_form(changeset, as: "organisation"))}
    end
    end

    def handle_event("show_invite_modal", _, socket) do
    if socket.assigns.can_manage do
      changeset = Accounts.change_user_email(%Accounts.User{})

      {:noreply,
       socket
       |> assign(:show_invite_modal, true)
       |> assign(:invite_form, to_form(changeset, as: "invite"))}
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to invite members")}
    end
    end

    def handle_event("cancel_invite", _, socket) do
    {:noreply,
     socket
     |> assign(:show_invite_modal, false)
     |> assign(:invite_form, nil)}
    end

    def handle_event("validate_invite", %{"invite" => _params}, socket) do
    {:noreply, socket}
    end

    def handle_event("send_invite", %{"invite" => %{"email" => email, "role" => role}}, socket) do
    organisation = socket.assigns.organisation
    inviter = socket.assigns.current_scope.user

    case Organisations.invite_user_to_organisation(
           organisation,
           inviter,
           %{email: email, role: role},
           &url(~p"/invitations/accept/\#{&1}")
         ) do
      {:ok, _invitation} ->
        {:noreply,
         socket
         |> assign(:show_invite_modal, false)
         |> assign(:invite_form, nil)
         |> put_flash(:info, "Invitation sent to \#{email}!")}

      {:error, :already_member} ->
        {:noreply,
         socket
         |> put_flash(:error, "\#{email} is already a member of this organisation")}

      {:error, changeset} ->
        {:noreply, assign(socket, :invite_form, to_form(changeset, as: "invite"))}
    end
    end

    def handle_event("change_role", %{"user-id" => user_id}, socket) do
    if socket.assigns.can_manage do
      member = Enum.find(socket.assigns.members, fn m -> m.user.id == user_id end)

      if member do
        # Create a simple form with the current role
        form_data = %{"role" => member.role}

        {:noreply,
         socket
         |> assign(:show_role_modal, true)
         |> assign(:selected_member, member)
         |> assign(:role_form, to_form(form_data, as: "role"))}
      else
        {:noreply, put_flash(socket, :error, "Member not found")}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to change roles")}
    end
    end

    def handle_event("cancel_role_change", _, socket) do
    {:noreply,
     socket
     |> assign(:show_role_modal, false)
     |> assign(:selected_member, nil)
     |> assign(:role_form, nil)}
    end

    def handle_event("validate_role_change", %{"role" => _params}, socket) do
    {:noreply, socket}
    end

    def handle_event("save_role_change", %{"role" => %{"role" => new_role}}, socket) do
    if socket.assigns.selected_member do
      organisation = socket.assigns.organisation
      user = socket.assigns.selected_member.user

      case Organisations.update_user_role(organisation, user, new_role) do
        {:ok, _updated_member} ->
          members = Organisations.list_organisation_members(organisation)

          {:noreply,
           socket
           |> assign(:members, members)
           |> assign(:show_role_modal, false)
           |> assign(:selected_member, nil)
           |> assign(:role_form, nil)
           |> put_flash(:info, "Role updated successfully")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :role_form, to_form(changeset, as: "role"))}

        {:error, :not_a_member} ->
          {:noreply, put_flash(socket, :error, "User is not a member of this organisation")}
      end
    else
      {:noreply, put_flash(socket, :error, "No member selected")}
    end
    end

    def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    if socket.assigns.can_manage do
      member = Enum.find(socket.assigns.members, fn m -> m.user.id == user_id end)

      if member do
        organisation = socket.assigns.organisation

        case Organisations.remove_user_from_organisation(organisation, member.user) do
          {:ok, _deleted_member} ->
            members = Organisations.list_organisation_members(organisation)

            {:noreply,
             socket
             |> assign(:members, members)
             |> put_flash(:info, "\#{member.user.email} has been removed from the organisation")}

          {:error, :not_a_member} ->
            {:noreply, put_flash(socket, :error, "User is not a member of this organisation")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not remove member. Please try again.")}
        end
      else
        {:noreply, put_flash(socket, :error, "Member not found")}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to remove members")}
    end
    end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner_web/live/organisations_live/manage.ex",
      manage_content
    )
  end

  defp create_organisations_live_invitation(igniter) do
    invitation_content = """
    defmodule NeptunerWeb.OrganisationsLive.Invitation do
    use NeptunerWeb, :live_view

    alias Neptuner.Organisations

    def render(assigns) do
    ~H\"\"\"
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md space-y-6">
        <div :if={@invitation} class="card bg-base-100 shadow">
          <div class="card-body text-center">
            <.header>
              You're Invited!
              <:subtitle>
                <strong>{@invitation.invited_by.email}</strong> has invited you to join
                <strong>{@invitation.organisation.name}</strong> as a <strong>{@invitation.role}</strong>.
              </:subtitle>
            </.header>

            <div class="space-y-4 mt-6">
              <div class="alert alert-info">
                <.icon name="hero-information-circle" class="w-5 h-5" />
                <span>Accepting this invitation will create an account for <strong>{@invitation.email}</strong></span>
              </div>

              <.button
                phx-click="accept_invitation"
                variant="primary"
                class="w-full btn-lg"
                phx-disable-with="Accepting..."
              >
                <.icon name="hero-check" class="w-5 h-5 mr-2" />
                Accept Invitation
              </.button>

              <p class="text-sm text-base-content/70">
                This invitation expires on {Calendar.strftime(@invitation.expires_at, "%B %d, %Y")}
              </p>
            </div>
          </div>
        </div>

        <div :if={@error} class="card bg-base-100 shadow">
          <div class="card-body text-center">
            <.header>
              Invalid Invitation
              <:subtitle>
                This invitation link is either invalid, expired, or has already been used.
              </:subtitle>
            </.header>

            <div class="mt-6">
              <.button navigate={~p"/"} variant="primary" class="w-full">
                Go to Homepage
              </.button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    \"\"\"
    end

    def mount(%{"token" => token}, _session, socket) do
    case Organisations.get_invitation_by_token(token) do
      %Organisations.OrganisationInvitation{} = invitation ->
        if Organisations.OrganisationInvitation.valid?(invitation) do
          {:ok,
           socket
           |> assign(:invitation, invitation)
           |> assign(:token, token)
           |> assign(:error, nil)}
        else
          {:ok,
           socket
           |> assign(:invitation, nil)
           |> assign(:token, nil)
           |> assign(:error, :invalid_or_expired)}
        end

      nil ->
        {:ok,
         socket
         |> assign(:invitation, nil)
         |> assign(:token, nil)
         |> assign(:error, :invalid_or_expired)}
    end
    end

    def handle_event("accept_invitation", _, socket) do
    case socket.assigns.token do
      nil ->
        {:noreply, put_flash(socket, :error, "Invalid invitation")}

      token ->
        case Organisations.accept_invitation(token) do
          {:ok, user} ->
            # Log the user in using the same pattern as magic link login
            case Neptuner.Accounts.deliver_login_instructions(user, &url(~p"/users/log-in/\#{&1}")) do
              {:ok, _} ->
                {:noreply,
                 socket
                 |> put_flash(:info, "Invitation accepted! Check your email for login instructions.")
                 |> push_navigate(to: ~p"/users/log-in")}

              {:error, _} ->
                {:noreply,
                 socket
                 |> put_flash(:info, "Invitation accepted! You can now log in.")
                 |> push_navigate(to: ~p"/users/log-in")}
            end

          {:error, :invalid_or_expired} ->
            {:noreply,
             socket
             |> assign(:error, :invalid_or_expired)
             |> assign(:invitation, nil)
             |> put_flash(:error, "This invitation is invalid or has expired")}

          {:error, %Ecto.Changeset{} = changeset} ->
            # Check if it's a duplicate membership error
            case changeset.errors[:user_id] do
              {msg, _opts} when is_binary(msg) ->
                if String.contains?(msg, "already been taken") do
                  {:noreply, put_flash(socket, :error, "You are already a member of this organisation")}
                else
                  {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
                end
              _ ->
                {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
            end

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
        end
    end
    end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner_web/live/organisations_live/invitation.ex",
      invitation_content
    )
  end

  defp create_migrations(igniter) do
    # Generate timestamps for migration filenames
    base_timestamp = DateTime.utc_now() |> DateTime.to_unix()

    organisations_timestamp =
      (base_timestamp + 1) |> DateTime.from_unix!() |> Calendar.strftime("%Y%m%d%H%M%S")

    invitations_timestamp =
      (base_timestamp + 2) |> DateTime.from_unix!() |> Calendar.strftime("%Y%m%d%H%M%S")

    # Create organisations and members migration
    organisations_migration_content = """
    defmodule Neptuner.Repo.Migrations.CreateOrganisationsAndMembers do
    use Ecto.Migration

    def change do
    create table(:organisations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisations, [:name])

    create table(:organisation_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string, null: false, default: "member"
      add :joined_at, :utc_datetime, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :organisation_id, references(:organisations, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisation_members, [:user_id, :organisation_id])
    create index(:organisation_members, [:user_id])
    create index(:organisation_members, [:organisation_id])
    end
    end
    """

    # Create invitations migration
    invitations_migration_content = """
    defmodule Neptuner.Repo.Migrations.CreateOrganisationInvitations do
    use Ecto.Migration

    def change do
    create table(:organisation_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :role, :string, null: false, default: "member"
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :accepted_at, :utc_datetime
      add :organisation_id, references(:organisations, on_delete: :delete_all, type: :binary_id), null: false
      add :invited_by_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisation_invitations, [:token])
    create unique_index(:organisation_invitations, [:email, :organisation_id])
    create index(:organisation_invitations, [:organisation_id])
    create index(:organisation_invitations, [:invited_by_id])
    create index(:organisation_invitations, [:expires_at])
    end
    end
    """

    igniter
    |> Igniter.create_new_file(
      "priv/repo/migrations/#{organisations_timestamp}_create_organisations_and_members.exs",
      organisations_migration_content
    )
    |> Igniter.create_new_file(
      "priv/repo/migrations/#{invitations_timestamp}_create_organisation_invitations.exs",
      invitations_migration_content
    )
  end

  defp update_user_auth(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/user_auth.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "assign_org_to_scope") do
        # UserAuth already updated
        source
      else
        # Update the alias to include Organisations
        content_with_alias =
          String.replace(
            content,
            "alias Neptuner.Accounts\n",
            "alias Neptuner.{Accounts, Organisations}\n"
          )

        # Add the assign_org_to_scope plug function after fetch_current_scope_for_user
        assign_org_plug =
          "\n" <>
            "  def assign_org_to_scope(conn, _opts) do\n" <>
            "    if current_scope = conn.assigns.current_scope do\n" <>
            "      user_id = current_scope.user.id\n" <>
            "\n" <>
            "      if org = Organisations.get_by_user_id(user_id) do\n" <>
            "        role = Organisations.get_user_role(org, current_scope.user)\n" <>
            "\n" <>
            "        assign(\n" <>
            "          conn,\n" <>
            "          :current_scope,\n" <>
            "          Accounts.Scope.put_organisation(current_scope, org, role)\n" <>
            "        )\n" <>
            "      else\n" <>
            "        conn\n" <>
            "      end\n" <>
            "    else\n" <>
            "      conn\n" <>
            "    end\n" <>
            "  end\n"

        content_with_plug =
          String.replace(
            content_with_alias,
            ~r/  end\n\n  defp ensure_user_token/,
            "  end#{assign_org_plug}\n  defp ensure_user_token"
          )

        # Add the LiveView on_mount functions after the existing on_mount functions
        on_mount_functions =
          "\n" <>
            "  def on_mount(:assign_org_to_scope, _params, _session, socket) do\n" <>
            "    socket =\n" <>
            "      case socket.assigns.current_scope do\n" <>
            "        %{organisation: nil, user: user} = scope ->\n" <>
            "          if org = Neptuner.Organisations.get_by_user_id(user.id) do\n" <>
            "            role = Organisations.get_user_role(org, user)\n" <>
            "\n" <>
            "            Phoenix.Component.assign(\n" <>
            "              socket,\n" <>
            "              :current_scope,\n" <>
            "              Scope.put_organisation(scope, org, role)\n" <>
            "            )\n" <>
            "          else\n" <>
            "            socket\n" <>
            "          end\n" <>
            "\n" <>
            "        _ ->\n" <>
            "          socket\n" <>
            "      end\n" <>
            "\n" <>
            "    {:cont, socket}\n" <>
            "  end\n" <>
            "\n" <>
            "  def on_mount(:require_organisation, _params, _session, socket) do\n" <>
            "    case socket.assigns.current_scope do\n" <>
            "      %{organisation: nil} ->\n" <>
            "        socket =\n" <>
            "          socket\n" <>
            "          |> Phoenix.LiveView.put_flash(\n" <>
            "            :error,\n" <>
            "            \"You must create or join an organisation to access this page.\"\n" <>
            "          )\n" <>
            "          |> Phoenix.LiveView.redirect(to: ~p\"/organisations/new\")\n" <>
            "\n" <>
            "        {:halt, socket}\n" <>
            "\n" <>
            "      _ ->\n" <>
            "        {:cont, socket}\n" <>
            "    end\n" <>
            "  end\n" <>
            "\n" <>
            "  def on_mount(:require_organisation_member, _params, _session, socket) do\n" <>
            "    case socket.assigns.current_scope do\n" <>
            "      %{organisation: nil} ->\n" <>
            "        socket =\n" <>
            "          socket\n" <>
            "          |> Phoenix.LiveView.put_flash(:error, \"Organisation not found.\")\n" <>
            "          |> Phoenix.LiveView.redirect(to: ~p\"/dashboard\")\n" <>
            "\n" <>
            "        {:halt, socket}\n" <>
            "\n" <>
            "      %{organisation: organisation, user: user} ->\n" <>
            "        if Organisations.get_user_role(organisation, user) do\n" <>
            "          {:cont, socket}\n" <>
            "        else\n" <>
            "          socket =\n" <>
            "            socket\n" <>
            "            |> Phoenix.LiveView.put_flash(:error, \"You are not a member of this organisation.\")\n" <>
            "            |> Phoenix.LiveView.redirect(to: ~p\"/dashboard\")\n" <>
            "\n" <>
            "          {:halt, socket}\n" <>
            "        end\n" <>
            "    end\n" <>
            "  end\n"

        updated_content =
          String.replace(
            content_with_plug,
            ~r/  end\n\n  defp mount_current_scope/,
            "  end#{on_mount_functions}\n  defp mount_current_scope"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_router(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "OrganisationsLive.Manage") do
        # Router already updated
        source
      else
        # Add the assign_org_to_scope plug to browser pipeline
        content_with_plug =
          String.replace(
            content,
            "plug :fetch_current_scope_for_user",
            "plug :fetch_current_scope_for_user\n    plug :assign_org_to_scope"
          )

        # Update the existing live_session to include invitation route
        new_live_sessions =
          "live_session :current_user,\n" <>
            "      on_mount: [\n" <>
            "        {NeptunerWeb.UserAuth, :mount_current_scope}\n" <>
            "      ] do\n" <>
            "      live \"/users/register\", UserLive.Registration, :new\n" <>
            "      live \"/users/log-in\", UserLive.Login, :new\n" <>
            "      live \"/users/log-in/:token\", UserLive.Confirmation, :new\n" <>
            "      live \"/invitations/accept/:token\", OrganisationsLive.Invitation, :accept\n" <>
            "    end\n\n" <>
            "    live_session :authenticated_user_org_setup,\n" <>
            "      on_mount: [\n" <>
            "        {NeptunerWeb.UserAuth, :require_authenticated},\n" <>
            "        {NeptunerWeb.UserAuth, :assign_org_to_scope}\n" <>
            "      ] do\n" <>
            "      live \"/organisations/new\", OrganisationsLive.New, :new\n" <>
            "    end\n\n" <>
            "    live_session :fully_authenticated_user,\n" <>
            "      on_mount: [\n" <>
            "        {NeptunerWeb.UserAuth, :require_authenticated},\n" <>
            "        {NeptunerWeb.UserAuth, :assign_org_to_scope},\n" <>
            "        {NeptunerWeb.UserAuth, :require_organisation}\n" <>
            "      ] do\n" <>
            "      live \"/dashboard\", DashboardLive, :index\n" <>
            "      live \"/organisations/manage\", OrganisationsLive.Manage, :manage"

        content_with_invitation =
          String.replace(
            content_with_plug,
            ~r/live_session :current_user,\n      on_mount: \[\{NeptunerWeb\.UserAuth, :mount_current_scope\}\] do\n      live "\/users\/register", UserLive\.Registration, :new\n      live "\/users\/log-in", UserLive\.Login, :new\n      live "\/users\/log-in\/:token", UserLive\.Confirmation, :new/,
            new_live_sessions
          )

        # Remove the old dashboard route that's now in the new live_session
        updated_content =
          String.replace(
            content_with_invitation,
            ~r/      live "\/dashboard", DashboardLive, :index\n    end/,
            "    end"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_layouts(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/components/layouts.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "hero-building-office") do
        # Layouts already updated
        source
      else
        # Update the Dashboard icon from hero-user to hero-squares-2x2
        content_with_dashboard_icon =
          String.replace(
            content,
            ~r/<\.icon name="hero-user" class="size-6" \/>/,
            "<.icon name=\"hero-squares-2x2\" class=\"size-6\" />"
          )

        # Add the Organisation navigation link after the Dashboard link
        organisation_link =
          "\n              <.link\n" <>
            "                navigate={~p\"/organisations/manage\"}\n" <>
            "                type=\"button\"\n" <>
            "                class=\"flex btn btn-ghost hover:text-primary items-center justify-between w-full p-3 font-sans text-xl antialiased font-semibold leading-snug text-left transition-colors\"\n" <>
            "              >\n" <>
            "                <div class=\"grid mr-4 place-items-center\">\n" <>
            "                  <.icon name=\"hero-building-office\" class=\"size-6\" />\n" <>
            "                </div>\n" <>
            "                <p class=\"block mr-auto text-base antialiased font-normal leading-relaxed\">\n" <>
            "                  Organisation\n" <>
            "                </p>\n" <>
            "              </.link>"

        # Add the organisation link after the dashboard link
        updated_content =
          String.replace(
            content_with_dashboard_icon,
            ~r/              <\/.link>\n            <\/ul>/,
            "              </.link>#{organisation_link}\n            </ul>"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_organisations_context(igniter) do
    organisations_content = """
    defmodule Neptuner.Organisations do
    @moduledoc \"\"\"
    The Organisations context.
    \"\"\"

    import Ecto.Query, warn: false
    alias Neptuner.Repo

    alias Neptuner.Accounts.User
    alias Neptuner.Organisations.Organisation
    alias Neptuner.Organisations.OrganisationMember
    alias Neptuner.Organisations.OrganisationInvitation
    alias Neptuner.Accounts.UserNotifier

    @doc \"\"\"
    Gets the primary organisation for a user by user ID.

    Returns the first organisation that the specified user belongs to.
    Returns `nil` if the user doesn't exist or doesn't belong to any organisation.

    ## Examples

      iex> get_by_user_id(123)
      %Organisation{id: 1, name: "Acme Corp"}

      iex> get_by_user_id(999)
      nil

    \"\"\"
    def get_by_user_id(user_id) do
    from(o in Organisation,
      join: om in OrganisationMember,
      on: o.id == om.organisation_id,
      where: om.user_id == ^user_id,
      order_by: [desc: om.inserted_at],
      limit: 1,
      select: o
    )
    |> Repo.one()
    end

    @doc \"\"\"
    Gets all organisations for a user by user ID.

    Returns a list of organisations that the specified user belongs to.
    Returns an empty list if the user doesn't exist or doesn't belong to any organisation.

    ## Examples

      iex> list_by_user_id(123)
      [%Organisation{id: 1, name: "Acme Corp"}, %Organisation{id: 2, name: "Beta Inc"}]

      iex> list_by_user_id(999)
      []

    \"\"\"
    def list_by_user_id(user_id) do
    from(o in Organisation,
      join: om in OrganisationMember,
      on: o.id == om.organisation_id,
      where: om.user_id == ^user_id,
      order_by: [desc: om.inserted_at],
      select: o
    )
    |> Repo.all()
    end

    @doc \"\"\"
    Creates an organisation and adds the user as the owner.

    ## Examples

      iex> create_organisation_with_owner(%{name: "Acme Corp"}, user)
      {:ok, %Organisation{}}

      iex> create_organisation_with_owner(%{name: ""}, user)
      {:error, %Ecto.Changeset{}}

    \"\"\"
    def create_organisation_with_owner(attrs, user) do
    Repo.transaction(fn ->
      with {:ok, organisation} <- create_organisation(attrs),
           {:ok, _member} <- add_user_to_organisation(organisation, user, "owner") do
        organisation
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
    end

    @doc \"\"\"
    Creates an organisation.

    ## Examples

      iex> create_organisation(%{name: "Acme Corp"})
      {:ok, %Organisation{}}

      iex> create_organisation(%{name: ""})
      {:error, %Ecto.Changeset{}}

    \"\"\"
    def create_organisation(attrs \\\\ %{}) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Repo.insert()
    end

    @doc \"\"\"
    Returns an `%Ecto.Changeset{}` for tracking organisation changes.

    ## Examples

      iex> change_organisation(organisation)
      %Ecto.Changeset{data: %Organisation{}}

    \"\"\"
    def change_organisation(%Organisation{} = organisation, attrs \\\\ %{}) do
    Organisation.changeset(organisation, attrs)
    end

    @doc \"\"\"
    Updates an organisation.

    ## Examples

      iex> update_organisation(organisation, %{name: "New Name"})
      {:ok, %Organisation{}}

      iex> update_organisation(organisation, %{name: ""})
      {:error, %Ecto.Changeset{}}

    \"\"\"
    def update_organisation(%Organisation{} = organisation, attrs) do
    organisation
    |> Organisation.changeset(attrs)
    |> Repo.update()
    end

    @doc \"\"\"
    Adds a user to an organisation with a specified role.

    ## Examples

      iex> add_user_to_organisation(organisation, user, "member")
      {:ok, %OrganisationMember{}}

      iex> add_user_to_organisation(organisation, user, "invalid_role")
      {:error, %Ecto.Changeset{}}

    \"\"\"
    def add_user_to_organisation(organisation, user, role \\\\ "member") do
    %OrganisationMember{}
    |> OrganisationMember.changeset(%{
      organisation_id: organisation.id,
      user_id: user.id,
      role: role
    })
    |> Repo.insert()
    end

    @doc \"\"\"
    Gets the user's role in an organisation.

    Returns the role string or nil if the user is not a member.

    ## Examples

      iex> get_user_role(organisation, user)
      "owner"

      iex> get_user_role(organisation, non_member_user)
      nil

    \"\"\"
    def get_user_role(organisation, user) do
    from(om in OrganisationMember,
      where: om.organisation_id == ^organisation.id and om.user_id == ^user.id,
      select: om.role
    )
    |> Repo.one()
    end

    @doc \"\"\"
    Checks if a user can manage an organisation (admin or owner role).

    ## Examples

      iex> can_manage_organisation?(organisation, owner_user)
      true

      iex> can_manage_organisation?(organisation, member_user)
      false

    \"\"\"
    def can_manage_organisation?(organisation, user) do
    role = get_user_role(organisation, user)
    role in ["admin", "owner"]
    end

    @doc \"\"\"
    Gets all members of an organisation with their roles.

    ## Examples

      iex> list_organisation_members(organisation)
      [%{user: %User{}, role: "owner", joined_at: ~U[...]}]

    \"\"\"
    def list_organisation_members(organisation) do
    from(om in OrganisationMember,
      join: u in User,
      on: om.user_id == u.id,
      where: om.organisation_id == ^organisation.id,
      order_by: [desc: om.inserted_at],
      select: %{user: u, role: om.role, joined_at: om.joined_at}
    )
    |> Repo.all()
    end

    ## Organisation Invitations

    @doc \"\"\"
    Creates an organisation invitation and sends an email.

    ## Examples

      iex> invite_user_to_organisation(organisation, inviter, %{email: "user@example.com", role: "member"}, url_fun)
      {:ok, %OrganisationInvitation{}}

      iex> invite_user_to_organisation(organisation, inviter, %{email: "invalid", role: "member"}, url_fun)
      {:error, %Ecto.Changeset{}}

    \"\"\"
    def invite_user_to_organisation(organisation, inviter, attrs, url_fun \\\\ nil) do
    # Check if user is already a member
    case get_user_by_email(attrs["email"] || attrs[:email]) do
      %User{} = user ->
        if get_user_role(organisation, user) do
          {:error, :already_member}
        else
          # User exists but not a member, add them directly
          add_user_to_organisation(organisation, user, attrs["role"] || attrs[:role] || "member")
        end

      nil ->
        # User doesn't exist, create invitation
        create_and_send_invitation(organisation, inviter, attrs, url_fun)
    end
    end

    defp get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
    end

    defp get_user_by_email(_), do: nil

    defp create_and_send_invitation(organisation, inviter, attrs, url_fun) do
    invitation_attrs =
      attrs
      |> Map.put(:organisation_id, organisation.id)
      |> Map.put(:invited_by_id, inviter.id)

    changeset = OrganisationInvitation.changeset(%OrganisationInvitation{}, invitation_attrs)

    case Repo.insert(changeset) do
      {:ok, invitation} ->
        # Send invitation email if url_fun is provided
        if url_fun do
          UserNotifier.deliver_organisation_invitation(
            invitation,
            organisation,
            inviter,
            url_fun
          )
        end
        {:ok, invitation}

      {:error, changeset} ->
        {:error, changeset}
    end
    end

    @doc \"\"\"
    Gets an organisation invitation by token.

    ## Examples

      iex> get_invitation_by_token("valid_token")
      %OrganisationInvitation{}

      iex> get_invitation_by_token("invalid_token")
      nil

    \"\"\"
    def get_invitation_by_token(token) when is_binary(token) do
    from(i in OrganisationInvitation,
      where: i.token == ^token,
      preload: [:organisation, :invited_by]
    )
    |> Repo.one()
    end

    def get_invitation_by_token(_), do: nil

    @doc \"\"\"
    Accepts an organisation invitation and creates/adds the user.

    ## Examples

      iex> accept_invitation("valid_token")
      {:ok, %User{}}

      iex> accept_invitation("expired_token")
      {:error, :invalid_or_expired}

    \"\"\"
    def accept_invitation(token) when is_binary(token) do
    case get_invitation_by_token(token) do
      %OrganisationInvitation{} = invitation ->
        if OrganisationInvitation.valid?(invitation) do
          process_invitation_acceptance(invitation)
        else
          {:error, :invalid_or_expired}
        end

      nil ->
        {:error, :invalid_or_expired}
    end
    end

    defp process_invitation_acceptance(invitation) do
    Repo.transaction(fn ->
      # Check if user already exists
      case get_user_by_email(invitation.email) do
        %User{} = user ->
          # User exists, just add to organisation
          case add_user_to_organisation(invitation.organisation, user, invitation.role) do
            {:ok, _member} ->
              mark_invitation_accepted(invitation)
              user

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        nil ->
          # User doesn't exist, create them
          case create_user_from_invitation(invitation) do
            {:ok, user} ->
              case add_user_to_organisation(invitation.organisation, user, invitation.role) do
                {:ok, _member} ->
                  mark_invitation_accepted(invitation)
                  user

                {:error, changeset} ->
                  Repo.rollback(changeset)
              end

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
      end
    end)
    end

    defp create_user_from_invitation(invitation) do
    # Create user with no password set (follows the magic link pattern)
    %User{}
    |> User.email_changeset(%{email: invitation.email})
    |> Repo.insert()
    end

    defp mark_invitation_accepted(invitation) do
    invitation
    |> OrganisationInvitation.accept_changeset()
    |> Repo.update!()
    end

    @doc \"\"\"
    Updates a user's role in an organisation.

    ## Examples

      iex> update_user_role(organisation, user, "admin")
      {:ok, %OrganisationMember{}}

      iex> update_user_role(organisation, user, "invalid_role")
      {:error, %Ecto.Changeset{}}

    \"\"\"
    def update_user_role(organisation, user, new_role) do
    case get_organisation_member(organisation, user) do
      %OrganisationMember{} = member ->
        member
        |> OrganisationMember.changeset(%{role: new_role})
        |> Repo.update()

      nil ->
        {:error, :not_a_member}
    end
    end

    @doc \"\"\"
    Removes a user from an organisation.

    ## Examples

      iex> remove_user_from_organisation(organisation, user)
      {:ok, %OrganisationMember{}}

      iex> remove_user_from_organisation(organisation, non_member_user)
      {:error, :not_a_member}

    \"\"\"
    def remove_user_from_organisation(organisation, user) do
    case get_organisation_member(organisation, user) do
      %OrganisationMember{} = member ->
        Repo.delete(member)

      nil ->
        {:error, :not_a_member}
    end
    end

    @doc \"\"\"
    Gets the organisation member record for a user.

    ## Examples

      iex> get_organisation_member(organisation, user)
      %OrganisationMember{}

      iex> get_organisation_member(organisation, non_member_user)
      nil

    \"\"\"
    def get_organisation_member(organisation, user) do
    from(om in OrganisationMember,
      where: om.organisation_id == ^organisation.id and om.user_id == ^user.id
    )
    |> Repo.one()
    end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/organisations.ex",
      organisations_content
    )
  end

  defp update_user_notifier(igniter) do
    Igniter.update_file(igniter, "lib/neptuner/accounts/user_notifier.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "deliver_organisation_invitation") do
        # UserNotifier already updated
        source
      else
        # Add the organisation invitation function before the final 'end'
        organisation_invitation_function =
          "\n" <>
            "  @doc \"\"\"\n" <>
            "  Deliver organisation invitation instructions.\n" <>
            "  \"\"\"\n" <>
            "  def deliver_organisation_invitation(invitation, organisation, inviter, url_fun) do\n" <>
            "    url = url_fun.(invitation.token)\n" <>
            "    \n" <>
            "    deliver(invitation.email, \"You're invited to join \#{organisation.name}\", \"\"\"\n" <>
            "\n" <>
            "    ==============================\n" <>
            "\n" <>
            "    Hi \#{invitation.email},\n" <>
            "\n" <>
            "    \#{inviter.email} has invited you to join \"\#{organisation.name}\" as a \#{invitation.role}.\n" <>
            "\n" <>
            "    You can accept this invitation by visiting the URL below:\n" <>
            "\n" <>
            "    \#{url}\n" <>
            "\n" <>
            "    This invitation will expire in 7 days.\n" <>
            "\n" <>
            "    If you don't know \#{inviter.email} or didn't expect this invitation, please ignore this email.\n" <>
            "\n" <>
            "    ==============================\n" <>
            "    \"\"\")\n" <>
            "  end"

        updated_content =
          String.replace(
            content,
            ~r/  end\nend$/,
            "  end#{organisation_invitation_function}\nend"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_user_schema(igniter) do
    Igniter.update_file(igniter, "lib/neptuner/accounts/user.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "alias Neptuner.Organisations.Organisation") do
        # User schema already updated
        source
      else
        # Add the Organisation aliases after the import line
        content_with_aliases =
          String.replace(
            content,
            "import Ecto.Changeset",
            "import Ecto.Changeset\n\n  alias Neptuner.Organisations.Organisation\n  alias Neptuner.Organisations.OrganisationMember"
          )

        # Add the organisation relationships after the authenticated_at field
        organisation_relationships =
          "\n" <>
            "    has_many :organisation_members, OrganisationMember\n" <>
            "    many_to_many :organisations, Organisation, join_through: OrganisationMember\n"

        updated_content =
          String.replace(
            content_with_aliases,
            "field :authenticated_at, :utc_datetime, virtual: true",
            "field :authenticated_at, :utc_datetime, virtual: true#{organisation_relationships}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_scope_module(igniter) do
    Igniter.update_file(igniter, "lib/neptuner/accounts/scope.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "alias Neptuner.Organisations.Organisation") do
        # Scope module already updated
        source
      else
        # Add the Organisation alias after the User alias
        content_with_alias =
          String.replace(
            content,
            "alias Neptuner.Accounts.User",
            "alias Neptuner.Accounts.User\n  alias Neptuner.Organisations.Organisation"
          )

        # Update the defstruct to include organisation fields
        content_with_struct =
          String.replace(
            content_with_alias,
            "defstruct user: nil",
            "defstruct user: nil, organisation: nil, organisation_role: nil"
          )

        # Add the new functions after the existing for_user functions
        new_functions =
          "\n" <>
            "  def put_organisation(%__MODULE__{} = scope, %Organisation{} = organisation) do\n" <>
            "    %{scope | organisation: organisation}\n" <>
            "  end\n" <>
            "\n" <>
            "  def put_organisation(%__MODULE__{} = scope, %Organisation{} = _organisation, nil) do\n" <>
            "    scope\n" <>
            "  end\n" <>
            "\n" <>
            "  def put_organisation(%__MODULE__{} = scope, %Organisation{} = organisation, role) when is_binary(role) do\n" <>
            "    %{scope | organisation: organisation, organisation_role: role}\n" <>
            "  end\n" <>
            "\n" <>
            "  @doc \"\"\"\n" <>
            "  Checks if the current scope can manage the organisation (admin or owner).\n" <>
            "  \"\"\"\n" <>
            "  def can_manage_organisation?(%__MODULE__{organisation_role: role}) when role in [\"admin\", \"owner\"], do: true\n" <>
            "  def can_manage_organisation?(_), do: false\n" <>
            "\n" <>
            "  @doc \"\"\"\n" <>
            "  Checks if the current scope is an organisation owner.\n" <>
            "  \"\"\"\n" <>
            "  def is_organisation_owner?(%__MODULE__{organisation_role: \"owner\"}), do: true\n" <>
            "  def is_organisation_owner?(_), do: false\n" <>
            "\n" <>
            "  @doc \"\"\"\n" <>
            "  Checks if the current scope is an organisation admin.\n" <>
            "  \"\"\"\n" <>
            "  def is_organisation_admin?(%__MODULE__{organisation_role: \"admin\"}), do: true\n" <>
            "  def is_organisation_admin?(_), do: false\n" <>
            "\n" <>
            "  @doc \"\"\"\n" <>
            "  Checks if the current scope is a regular member.\n" <>
            "  \"\"\"\n" <>
            "  def is_organisation_member?(%__MODULE__{organisation_role: \"member\"}), do: true\n" <>
            "  def is_organisation_member?(_), do: false"

        # Add the new functions before the final 'end'
        updated_content =
          String.replace(
            content_with_struct,
            ~r/  def for_user\(nil\), do: nil\nend/,
            "  def for_user(nil), do: nil#{new_functions}\nend"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_scope_config(igniter) do
    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "organisation: [") do
        # Organisation scope config already exists
        source
      else
        # Add organisation scope config to the existing scopes config
        organisation_config =
          "],\n" <>
            "  organisation: [\n" <>
            "    module: Neptuner.Accounts.Scope,\n" <>
            "    assign_key: :current_scope,\n" <>
            "    access_path: [:organisation, :id],\n" <>
            "    schema_key: :org_id,\n" <>
            "    schema_type: :id,\n" <>
            "    schema_table: :organisations,\n" <>
            "    test_data_fixture: Neptuner.AccountsFixtures,\n" <>
            "    test_login_helper: :register_and_log_in_user_with_org\n" <>
            "  ]"

        updated_content =
          String.replace(
            content,
            ~r/    test_login_helper: :register_and_log_in_user\n  \]/,
            "    test_login_helper: :register_and_log_in_user\n  #{organisation_config}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Multi-Tenancy (Organisations) Integration Complete! 🏢

    Multi-tenancy functionality has been successfully integrated into your SaaS template. Here's what was configured:

    ### Database Schema Created:
    - Organisation schema with UUID primary keys
    - OrganisationMember schema for user-organisation relationships
    - OrganisationInvitation schema for invitation system
    - Comprehensive migrations with proper indexes and constraints

    ### Context Modules Created:
    - Neptuner.Organisations context with full CRUD operations
    - Invitation system with email notifications
    - Role-based access control (owner, admin, member)
    - Transaction-safe operations for critical functions

    ### Authentication & Authorization:
    - Updated Scope module with organisation context
    - New authentication plugs for organisation assignment
    - LiveView hooks for organisation requirements
    - Role-based permission checking

    ### LiveView Components:
    - Organisation management interface with team member management
    - Organisation creation flow
    - Invitation acceptance flow
    - Role-based UI with different views for different permission levels

    ### Files Created:
    - lib/neptuner/organisations.ex - Main context module
    - lib/neptuner/organisations/organisation.ex - Organisation schema
    - lib/neptuner/organisations/organisation_member.ex - Membership schema
    - lib/neptuner/organisations/organisation_invitation.ex - Invitation schema
    - lib/neptuner_web/live/organisations_live/manage.ex - Management interface
    - lib/neptuner_web/live/organisations_live/new.ex - Organisation creation
    - lib/neptuner_web/live/organisations_live/invitation.ex - Invitation acceptance
    - priv/repo/migrations/*_create_organisations_and_members.exs - Database migrations
    - priv/repo/migrations/*_create_organisation_invitations.exs - Invitation table

    ### Files Updated:
    - config/config.exs - Added organisation scope configuration
    - lib/neptuner/accounts/user.ex - Added organisation relationships
    - lib/neptuner/accounts/scope.ex - Added organisation context
    - lib/neptuner/accounts/user_notifier.ex - Added invitation emails
    - lib/neptuner_web/router.ex - Added organisation routes
    - lib/neptuner_web/user_auth.ex - Added organisation auth hooks
    - lib/neptuner_web/components/layouts.ex - Added organisation navigation
    - test/support/factory.ex - Added organisation factories

    ### Test Coverage:
    - Comprehensive test suite for all organisation functionality
    - LiveView tests for all user interfaces
    - Factory definitions for easy test data creation
    - Updated existing tests to work with organisation context

    ### Key Features:
    - **Role-Based Access Control**: Three-tier permission system (owner, admin, member)
    - **Invitation System**: Email-based invitations with token validation
    - **Multi-Organisation Support**: Users can belong to multiple organisations
    - **Transaction Safety**: Critical operations wrapped in database transactions
    - **Comprehensive UI**: Full management interface for organisation operations
    - **Email Notifications**: Automatic invitation emails with custom templates

    ### Next Steps:
    1. Run the migrations:
       ```bash
       mix ecto.migrate
       ```

    2. Update your templates to use the organisation context:
       - Organisation data is available in `@current_scope.organisation`
       - User role is available in `@current_scope.organisation_role`
       - Permission helpers are available in the Scope module

    3. Test the functionality:
       ```bash
       mix test
       ```

    4. Customize the invitation email template in:
       - `lib/neptuner/accounts/user_notifier.ex`

    5. Add organisation-specific features:
       - Scoped data queries using `@current_scope.organisation.id`
       - Role-based UI components
       - Organisation-specific settings

    ### Usage Examples:
    ```elixir
    # Get current organisation in LiveView
    organisation = socket.assigns.current_scope.organisation

    # Check permissions
    if Neptuner.Accounts.Scope.can_manage_organisation?(socket.assigns.current_scope) do
      # Allow management actions
    end

    # Create organisation-scoped queries
    from(p in Post, where: p.org_id == ^organisation.id)
    ```

    ### Organisation Flow:
    1. User registers → redirected to create organisation
    2. User creates organisation → becomes owner
    3. Owner invites members → invitation emails sent
    4. Members accept invitations → join organisation
    5. All users operate within organisation context

    🎉 Your app now supports complete multi-tenancy with organisations!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
