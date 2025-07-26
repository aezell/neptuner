defmodule NeptunerWeb.OrganisationsLive.Invitation do
  use NeptunerWeb, :live_view

  alias Neptuner.Organisations

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md space-y-6">
        <div :if={@invitation} class="card bg-base-100 shadow">
          <div class="card-body text-center">
            <.header>
              You're Invited!
              <:subtitle>
                <strong>{@invitation.invited_by.email}</strong>
                has invited you to join <strong>{@invitation.organisation.name}</strong>
                as a <strong>{@invitation.role}</strong>.
              </:subtitle>
            </.header>

            <div class="space-y-4 mt-6">
              <div class="alert alert-info">
                <.icon name="hero-information-circle" class="w-5 h-5" />
                <span>
                  Accepting this invitation will create an account for
                  <strong>{@invitation.email}</strong>
                </span>
              </div>

              <.button
                phx-click="accept_invitation"
                variant="primary"
                class="w-full btn-lg"
                phx-disable-with="Accepting..."
              >
                <.icon name="hero-check" class="w-5 h-5 mr-2" /> Accept Invitation
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
    """
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
            case Neptuner.Accounts.deliver_login_instructions(
                   user,
                   &url(~p"/users/log-in/#{&1}")
                 ) do
              {:ok, _} ->
                {:noreply,
                 socket
                 |> put_flash(
                   :info,
                   "Invitation accepted! Check your email for login instructions."
                 )
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
                  {:noreply,
                   put_flash(socket, :error, "You are already a member of this organisation")}
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
