defmodule Mix.Tasks.Neptuner.Gen.OauthGoogle do
  @moduledoc """
  Installs Google OAuth authentication for the SaaS template using Igniter.

  This task:
  - Adds ueberauth_google dependency to mix.exs
  - Adds Ueberauth configuration to config.exs
  - Updates the User schema with OAuth fields
  - Adds OAuth registration functionality to Accounts context
  - Creates GoogleAuthController for handling OAuth flow
  - Updates router with OAuth routes
  - Adds Google login button to login page
  - Creates database migration for OAuth fields

      $ mix neptuner.gen.oauth_google

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      |> add_ueberauth_google_dependency()
      |> add_ueberauth_config()
      |> update_user_schema()
      |> update_accounts_context()
      |> create_google_auth_controller()
      |> update_router()
      |> update_login_page()
      |> create_oauth_migration()
      |> update_env_example()

    if opts[:yes] do
      igniter
    else
      print_completion_notice(igniter)
    end
  end

  defp add_ueberauth_google_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:ueberauth_google,") do
        # Dependency already exists
        source
      else
        # Add ueberauth_google dependency after fun_with_flags_ui
        updated_content =
          String.replace(
            content,
            ~r/(\{:fun_with_flags_ui, "~> 1\.1"\},)/,
            "\\1\n      # Social Auth Google\n      {:ueberauth_google, \"~> 0.10\"},"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_ueberauth_config(igniter) do
    config_content = """
    config :ueberauth, Ueberauth,
      providers: [
        google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
      ]

    config :ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: System.get_env("GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("GOOGLE_CLIENT_SECRET")
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :ueberauth, Ueberauth") do
        # Config already exists
        source
      else
        # Add Ueberauth config before the import_config line
        updated_content =
          String.replace(
            content,
            ~r/(# Import environment specific config\. This must remain at the bottom)/,
            "\n#{config_content}\n\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_user_schema(igniter) do
    igniter
    |> Igniter.update_file("lib/neptuner/accounts/user.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "field :is_oauth_user") do
        # OAuth fields already exist
        source
      else
        # Add OAuth fields after authenticated_at field
        updated_content =
          String.replace(
            content,
            ~r/(field :authenticated_at, :utc_datetime, virtual: true)/,
            "\\1\n\n    field :is_oauth_user, :boolean, default: false\n    field :oauth_provider, :string"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
    |> Igniter.update_file("lib/neptuner/accounts/user.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "def oauth_registration_changeset") do
        # OAuth changeset function already exists
        source
      else
        # Add oauth_registration_changeset function after email_changeset
        updated_content =
          String.replace(
            content,
            ~r/(def email_changeset\(user, attrs, opts \\\\ \[\]\) do[\s\S]*?end)/,
            "\\1\n\n  @doc \"\"\"\n  A user changeset for OAuth registration.\n\n  It validates the email and oauth_provider fields and sets is_oauth_user to true.\n  \"\"\"\n  def oauth_registration_changeset(user, attrs, opts \\\\\\\\ []) do\n    user\n    |> cast(attrs, [:email, :oauth_provider])\n    |> validate_required([:email, :oauth_provider])\n    |> validate_email(opts)\n    |> put_change(:is_oauth_user, true)\n  end"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_accounts_context(igniter) do
    Igniter.update_file(igniter, "lib/neptuner/accounts.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "def register_oauth_user") do
        # OAuth registration function already exists
        source
      else
        # Add register_oauth_user function after register_user
        updated_content =
          String.replace(
            content,
            ~r/(def register_user\(attrs\) do[\s\S]*?\n  end)/,
            "\\1\n\n  def register_oauth_user(attrs) do\n    %User{}\n    |> User.oauth_registration_changeset(attrs)\n    |> Repo.insert()\n  end"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_google_auth_controller(igniter) do
    controller_content = """
    defmodule NeptunerWeb.GoogleAuthController do
      alias NeptunerWeb.UserAuth
      alias Neptuner.Accounts
      use NeptunerWeb, :controller
      require Logger

      plug Ueberauth

      def request(conn, _params) do
        Phoenix.Controller.redirect(conn, to: Ueberauth.Strategy.Helpers.callback_url(conn))
      end

      def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
        email = auth.info.email

        case Accounts.get_user_by_email(email) do
          nil ->
            # User does not exist, so create a new user
            user_params = %{
              email: email,
              oauth_provider: "google"
            }

            case Accounts.register_oauth_user(user_params) do
              {:ok, user} ->
                UserAuth.log_in_user(conn, user)

              {:error, changeset} ->
                Logger.error("Failed to create user \#{inspect(changeset)}.")

                conn
                |> put_flash(:error, "Failed to create user.")
                |> redirect(to: ~p"/")
            end

          user ->
            # User exists, update session or other details if necessary
            UserAuth.log_in_user(conn, user)
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner_web/controllers/google_auth_controller.ex",
      controller_content
    )
  end

  defp update_router(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "scope \"/auth\"") do
        # OAuth routes already exist
        source
      else
        # Add OAuth routes after the log-out route
        updated_content =
          String.replace(
            content,
            ~r/(delete "\/users\/log-out", UserSessionController, :delete)/,
            "\\1\n\n    scope \"/auth\" do\n      get \"/google\", GoogleAuthController, :request\n      get \"/google/callback\", GoogleAuthController, :callback\n    end"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_login_page(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/live/user_live/login.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "Login with Google") do
        # Google login button already exists
        source
      else
        # Add Google login button after the password form
        updated_content =
          String.replace(
            content,
            ~r/(<\.\/form>\s+<\.\/div>)/,
            "\\1\n\n          <.button href={~p\"/auth/google\"}>Login with Google</.button>"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_oauth_migration(igniter) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")

    migration_content = """
    defmodule Neptuner.Repo.Migrations.AddOauthUser do
      use Ecto.Migration

      def up do
        alter table(:users) do
          add :is_oauth_user, :boolean, default: false
          add :oauth_provider, :string, null: true
          modify :hashed_password, :string, null: true
        end
      end

      def down do
        alter table(:users) do
          remove :is_oauth_user
          remove :oauth_provider
          modify :hashed_password, :string, null: false
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "priv/repo/migrations/#{timestamp}_add_oauth_user.exs",
      migration_content
    )
  end

  defp update_env_example(igniter) do
    Igniter.update_file(igniter, ".env.example", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "GOOGLE_CLIENT_ID") do
        # Google OAuth env vars already exist
        source
      else
        # Add Google OAuth environment variables at the top
        google_env_vars = """
        # Google OAuth Configuration
        GOOGLE_CLIENT_ID=your_google_client_id
        GOOGLE_CLIENT_SECRET=your_google_client_secret

        """

        updated_content =
          if String.trim(content) == "" do
            google_env_vars
          else
            google_env_vars <> content
          end

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Google OAuth Integration Complete! 🔐

    Google OAuth authentication has been successfully integrated into your SaaS template. Here's what was configured:

    ### Dependencies Added:
    - ueberauth_google (~> 0.10) for Google OAuth strategy

    ### Configuration Added:
    - Ueberauth configuration in config/config.exs
    - Google OAuth strategy with email and profile scopes
    - Environment variables for Google OAuth credentials

    ### Code Updates:
    - User schema updated with OAuth fields (is_oauth_user, oauth_provider)
    - Accounts context extended with register_oauth_user/1 function
    - GoogleAuthController created for handling OAuth flow
    - Router updated with OAuth routes (/auth/google, /auth/google/callback)
    - Login page updated with Google login button

    ### Files Created:
    - lib/neptuner_web/controllers/google_auth_controller.ex
    - Database migration for OAuth user fields

    ### Files Updated:
    - .env.example with Google OAuth environment variables

    ### Next Steps:
    1. Set up Google OAuth credentials:
       - Visit https://console.developers.google.com/
       - Create a new project or select existing one
       - Enable Google+ API
       - Create OAuth 2.0 credentials
       - Set authorized redirect URI: http://localhost:4000/auth/google/callback

    2. Configure environment variables:
       - GOOGLE_CLIENT_ID: Your Google OAuth client ID
       - GOOGLE_CLIENT_SECRET: Your Google OAuth client secret

    3. Run the migration:
       - mix ecto.migrate

    4. Update your production redirect URI when deploying

    ### OAuth Flow:
    - Users can now click "Login with Google" on the login page
    - New users will be automatically registered with OAuth
    - Existing users with matching email will be logged in

    🎉 Your app now supports Google OAuth authentication!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
