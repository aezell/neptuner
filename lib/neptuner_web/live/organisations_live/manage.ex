defmodule NeptunerWeb.OrganisationsLive.Manage do
  use NeptunerWeb, :live_view

  alias Neptuner.Organisations
  alias Neptuner.Accounts
  alias Neptuner.Accounts.Scope

  def render(assigns) do
    ~H"""
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
    """
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
           &url(~p"/invitations/accept/#{&1}")
         ) do
      {:ok, _invitation} ->
        {:noreply,
         socket
         |> assign(:show_invite_modal, false)
         |> assign(:invite_form, nil)
         |> put_flash(:info, "Invitation sent to #{email}!")}

      {:error, :already_member} ->
        {:noreply,
         socket
         |> put_flash(:error, "#{email} is already a member of this organisation")}

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
             |> put_flash(:info, "#{member.user.email} has been removed from the organisation")}

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
