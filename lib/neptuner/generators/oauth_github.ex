defmodule Mix.Tasks.Neptuner.Gen.OauthGithub do
  @moduledoc """
  Installs GitHub OAuth authentication for the SaaS template using Igniter.

  This task:
  - Adds ueberauth_github dependency to mix.exs
  - Adds or updates Ueberauth configuration to include GitHub
  - Updates the User schema with OAuth fields (if not already present)
  - Adds OAuth registration functionality to Accounts context (if not already present)
  - Creates GitHubAuthController for handling OAuth flow
  - Updates router with OAuth routes (if not already present)
  - Adds GitHub login button to login page
  - Creates database migration for OAuth fields (if not already present)
  - Updates .env.example with GitHub OAuth environment variables

      $ mix neptuner.gen.oauth_github

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      |> add_ueberauth_github_dependency()
      |> add_or_update_ueberauth_config()
      |> update_user_schema()
      |> update_accounts_context()
      |> create_github_auth_controller()
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

  defp add_ueberauth_github_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:ueberauth_github,") do
        # Dependency already exists
        source
      else
        # Add ueberauth_github dependency
        cond do
          String.contains?(content, "{:ueberauth_google,") ->
            # Google OAuth already exists, add GitHub after it
            updated_content =
              String.replace(
                content,
                ~r/(\{:ueberauth_google, "~> 0\.10"\},)/,
                "\\1\n      {:ueberauth_github, \"~> 0.8\"},"
              )

            Rewrite.Source.update(source, :content, updated_content)

          String.contains?(content, "{:fun_with_flags_ui,") ->
            # Add after fun_with_flags_ui
            updated_content =
              String.replace(
                content,
                ~r/(\{:fun_with_flags_ui, "~> 1\.1"\},)/,
                "\\1\n      # Social Auth GitHub\n      {:ueberauth_github, \"~> 0.8\"},"
              )

            Rewrite.Source.update(source, :content, updated_content)

          true ->
            source
        end
      end
    end)
  end

  defp add_or_update_ueberauth_config(igniter) do
    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      cond do
        String.contains?(content, "github: {Ueberauth.Strategy.Github") ->
          # GitHub already configured
          source

        String.contains?(content, "config :ueberauth, Ueberauth") ->
          # Ueberauth config exists, add GitHub to providers
          if String.contains?(content, "providers: [") do
            # Add GitHub to existing providers list
            updated_content =
              String.replace(
                content,
                ~r/(providers: \[\s*)/,
                "\\1github: {Ueberauth.Strategy.Github, [default_scope: \"user\"]},\n    "
              )

            # Add GitHub OAuth config after existing Ueberauth config
            updated_content =
              String.replace(
                updated_content,
                ~r/(config :ueberauth, Ueberauth\.Strategy\.Google\.OAuth,[\s\S]*?client_secret: System\.get_env\("GOOGLE_CLIENT_SECRET"\))/,
                "\\1\n\nconfig :ueberauth, Ueberauth.Strategy.Github.OAuth,\n  client_id: System.get_env(\"GITHUB_CLIENT_ID\"),\n  client_secret: System.get_env(\"GITHUB_CLIENT_SECRET\")"
              )

            Rewrite.Source.update(source, :content, updated_content)
          else
            source
          end

        true ->
          # No Ueberauth config exists, create it
          config_content = """
          config :ueberauth, Ueberauth,
            providers: [
              github: {Ueberauth.Strategy.Github, [default_scope: "user"]}
            ]

          config :ueberauth, Ueberauth.Strategy.Github.OAuth,
            client_id: System.get_env("GITHUB_CLIENT_ID"),
            client_secret: System.get_env("GITHUB_CLIENT_SECRET")
          """

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
        oauth_changeset_function = """

        @doc \"\"\"
        A user changeset for OAuth registration.

        It validates the email and oauth_provider fields and sets is_oauth_user to true.
        \"\"\"
        def oauth_registration_changeset(user, attrs, opts \\\\\\\\ []) do
        user
        |> cast(attrs, [:email, :oauth_provider])
        |> validate_required([:email, :oauth_provider])
        |> validate_email(opts)
        |> put_change(:is_oauth_user, true)
        end
        """

        updated_content =
          String.replace(
            content,
            ~r/(def email_changeset\(user, attrs, opts \\\\ \[\]\) do[\s\S]*?end)/,
            "\\1#{oauth_changeset_function}"
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

  defp create_github_auth_controller(igniter) do
    controller_content = """
    defmodule NeptunerWeb.GitHubAuthController do
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
              oauth_provider: "github"
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
      "lib/neptuner_web/controllers/github_auth_controller.ex",
      controller_content
    )
  end

  defp update_router(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "GitHubAuthController") do
        # GitHub routes already exist
        source
      else
        # Add GitHub routes after the log-out route
        if String.contains?(content, "scope \"/auth\"") do
          # Auth scope exists, add GitHub routes inside it
          updated_content =
            String.replace(
              content,
              ~r/(scope "\/auth" do[\s\S]*?)(    end)/,
              "\\1      get \"/github\", GitHubAuthController, :request\n      get \"/github/callback\", GitHubAuthController, :callback\n\\2"
            )

          Rewrite.Source.update(source, :content, updated_content)
        else
          # No auth scope exists, create it with GitHub routes
          updated_content =
            String.replace(
              content,
              ~r/(delete "\/users\/log-out", UserSessionController, :delete)/,
              "\\1\n\n    scope \"/auth\" do\n      get \"/github\", GitHubAuthController, :request\n      get \"/github/callback\", GitHubAuthController, :callback\n    end"
            )

          Rewrite.Source.update(source, :content, updated_content)
        end
      end
    end)
  end

  defp update_login_page(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/live/user_live/login.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "Login with GitHub") do
        # GitHub login button already exists
        source
      else
        # Add GitHub login button
        if String.contains?(content, "Login with Google") do
          # Google button exists, add GitHub button after it
          updated_content =
            String.replace(
              content,
              ~r/(<\.button href=\{~p"\/auth\/google"\}>Login with Google<\/\.button>)/,
              "\\1\n          <.button href={~p\"/auth/github\"}>Login with GitHub</.button>"
            )

          Rewrite.Source.update(source, :content, updated_content)
        else
          # No OAuth buttons exist, add GitHub button after password form
          updated_content =
            String.replace(
              content,
              ~r/(<\.\/form>\s+<\.\/div>)/,
              "\\1\n\n          <.button href={~p\"/auth/github\"}>Login with GitHub</.button>"
            )

          Rewrite.Source.update(source, :content, updated_content)
        end
      end
    end)
  end

  defp create_oauth_migration(igniter) do
    # Check if OAuth migration already exists by looking for files containing AddOauthUser
    if File.exists?("priv/repo/migrations") do
      existing_migration =
        File.ls!("priv/repo/migrations")
        |> Enum.find(fn file -> String.contains?(file, "add_oauth_user") end)

      if existing_migration do
        # OAuth migration already exists
        igniter
      else
        # Create OAuth migration
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
    else
      # Migrations directory doesn't exist, create it and the migration
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
  end

  defp update_env_example(igniter) do
    Igniter.update_file(igniter, ".env.example", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "GITHUB_CLIENT_ID") do
        source
      else
        github_env_vars =
          "# GitHub OAuth Configuration\nGITHUB_CLIENT_ID=your_github_client_id\nGITHUB_CLIENT_SECRET=your_github_client_secret\n\n"

        updated_content = github_env_vars <> content
        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## GitHub OAuth Integration Complete! 🔐

    GitHub OAuth authentication has been successfully integrated into your SaaS template. Here's what was configured:

    ### Dependencies Added:
    - ueberauth_github (~> 0.8) for GitHub OAuth strategy

    ### Configuration Added/Updated:
    - Ueberauth configuration updated to include GitHub provider
    - GitHub OAuth strategy configuration
    - Environment variables for GitHub OAuth credentials

    ### Code Updates:
    - User schema updated with OAuth fields (if not already present)
    - Accounts context extended with register_oauth_user/1 function (if not already present)
    - GitHubAuthController created for handling OAuth flow
    - Router updated with GitHub OAuth routes
    - Login page updated with GitHub login button

    ### Files Created:
    - lib/neptuner_web/controllers/github_auth_controller.ex
    - Database migration for OAuth user fields (if not already present)

    ### Files Updated:
    - .env.example with GitHub OAuth environment variables (prepended to top)

    ### Next Steps:
    1. Set up GitHub OAuth application:
       - Visit https://github.com/settings/applications/new
       - Create a new OAuth App
       - Set Authorization callback URL: http://localhost:4000/auth/github/callback

    2. Configure environment variables:
       - GITHUB_CLIENT_ID: Your GitHub OAuth client ID
       - GITHUB_CLIENT_SECRET: Your GitHub OAuth client secret

    3. Run the migration (if not already run):
       - mix ecto.migrate

    4. Update your production callback URL when deploying

    ### OAuth Flow:
    - Users can now click "Login with GitHub" on the login page
    - New users will be automatically registered with OAuth
    - Existing users with matching email will be logged in

    🎉 Your app now supports GitHub OAuth authentication!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
