defmodule NeptunerWeb.UserLive.Registration do
  use NeptunerWeb, :live_view

  alias Neptuner.Accounts
  alias Neptuner.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="bg-base-100 p-6 border border-base-200 rounded-xl">
          <div role="tablist" class="tabs tabs-box w-fit mb-4">
            <.link role="tab" navigate={~p"/users/log-in"} class="tab">Log in</.link>
            <.link role="tab" navigate={~p"/users/register"} class="tab tab-active">Register</.link>
          </div>
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-accent hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>

          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
            />

            <.button variant="primary" phx-disable-with="Creating account..." class="w-full">
              Create an account
            </.button>
          </.form>

          <p class="text-xs mt-4">
            By registering you agree to our
            <.link navigate={~p"/terms"} class="text-accent hover:underline">
              terms and conditions
            </.link>
            and
            <.link navigate={~p"/privacy"} class="text-accent hover:underline">
              privacy policy.
            </.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: NeptunerWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
