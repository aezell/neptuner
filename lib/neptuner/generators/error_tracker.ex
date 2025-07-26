defmodule Mix.Tasks.Neptuner.Gen.ErrorTracker do
  @moduledoc """
  Installs Error Tracker for the SaaS template using Igniter.

  This task:
  - Adds Error Tracker configuration to config.exs
  - Updates the router to include error tracker dashboard
  - Creates the error tracker migration

      $ mix neptuner.gen.error_tracker

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> add_error_tracker_dependency()
    |> add_error_tracker_config()
    |> update_router_with_error_tracker()
    |> create_error_tracker_migration()
    |> print_completion_notice()
  end

  defp add_error_tracker_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:error_tracker,") do
        # Dependency already exists
        source
      else
        # Add error_tracker dependency after fun_with_flags_ui
        updated_content =
          String.replace(
            content,
            ~r/(\{:fun_with_flags_ui, "~> 1\.1"\},)/,
            "\\1\n      # Error Tracking\n      {:error_tracker, \"~> 0.6\"},"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_error_tracker_config(igniter) do
    config_content = """
    config :error_tracker,
      repo: Neptuner.Repo,
      otp_app: :neptuner,
      enabled: true
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :error_tracker") do
        # Config already exists
        source
      else
        # Add Error Tracker config before the import_config line
        updated_content =
          String.replace(
            content,
            ~r/(# Import environment specific config\. This must remain at the bottom)/,
            "\n#{config_content}\n\n\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_router_with_error_tracker(igniter) do
    igniter
    |> Igniter.update_file("lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "use ErrorTracker.Web, :router") do
        # ErrorTracker router already added
        source
      else
        # Add ErrorTracker.Web use after the main router use
        updated_content =
          String.replace(
            content,
            ~r/(use NeptunerWeb, :router)/,
            "\\1\n  use ErrorTracker.Web, :router"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
    |> Igniter.update_file("lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "error_tracker_dashboard \"/errors\"") do
        # Dashboard route already exists
        source
      else
        # Add error tracker dashboard route in admin scope
        updated_content =
          String.replace(
            content,
            ~r/(scope "\/admin" do\n    pipe_through \[:browser, :admin_protected\])/,
            "\\1\n    error_tracker_dashboard \"/errors\""
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
    |> Igniter.update_file("lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "# Design system preview") and
           String.contains?(content, "error_tracker_dashboard \"/errors\"") do
        # Dev dashboard route already exists
        source
      else
        # Add error tracker dashboard route in development scope
        updated_content =
          String.replace(
            content,
            ~r/(# Design system preview\n      get "\/design-system", NeptunerWeb\.PageController, :design_system)/,
            "\\1\n\n      error_tracker_dashboard \"/errors\""
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_error_tracker_migration(igniter) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")

    migration_content = """
    defmodule Neptuner.Repo.Migrations.AddErrorTracker do
      use Ecto.Migration

      def up, do: ErrorTracker.Migration.up(version: 5)

      # We specify `version: 1` in `down`, to ensure we remove all migrations.
      def down, do: ErrorTracker.Migration.down(version: 1)
    end
    """

    Igniter.create_new_file(
      igniter,
      "priv/repo/migrations/#{timestamp}_add_error_tracker.exs",
      migration_content
    )
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Error Tracker Integration Complete! 🔍

    Error Tracker has been successfully integrated into your SaaS template. Here's what was configured:

    ### Configuration Added:
    - Error Tracker config in config/config.exs with your repo and app settings
    - Error tracking enabled for all environments
    - Database backend configured with your PostgreSQL repo

    ### Code Updates:
    - ErrorTracker router functionality added to router.ex
    - Error dashboard route added at /admin/errors (protected by admin auth)
    - Error dashboard route added at /dev/errors (development only)

    ### Files Created:
    - Database migration for Error Tracker tables

    ### Next Steps:
    1. Run `mix ecto.migrate` to create the error tracker tables
    2. Visit `/admin/errors` in production (requires admin auth)
    3. Visit `/dev/errors` in development to see the dashboard
    4. Error tracking will automatically capture:
       - Phoenix errors and exceptions
       - LiveView errors
       - Database errors
       - Custom errors you report

    ### Error Dashboard Features:
    - Real-time error tracking and monitoring
    - Error grouping and occurrence counting
    - Stack trace analysis
    - Error context and metadata
    - Historical error trends

    ### Admin Access:
    - Production: http://yourapp.com/admin/errors (requires admin password)
    - Development: http://localhost:4000/dev/errors

    🎉 Your app is now tracking errors automatically!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
