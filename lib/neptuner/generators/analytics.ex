defmodule Mix.Tasks.Neptuner.Gen.Analytics do
  @moduledoc """
  Installs Phoenix Analytics for the SaaS template using Igniter.

  This task:
  - Adds Phoenix Analytics configuration to config.exs
  - Updates the endpoint with RequestTracker plug
  - Updates the router to include analytics dashboard
  - Creates the analytics migration

      $ mix neptuner.gen.analytics

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> add_phoenix_analytics_dependency()
    |> add_phoenix_analytics_config()
    |> update_endpoint_with_tracker_plug()
    |> update_router_with_analytics()
    |> create_analytics_migration()
    |> print_completion_notice()
  end

  defp add_phoenix_analytics_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:phoenix_analytics,") do
        # Dependency already exists
        source
      else
        # Add phoenix_analytics dependency after fun_with_flags_ui
        updated_content =
          String.replace(
            content,
            ~r/(\{:fun_with_flags_ui, "~> 1\.1"\},)/,
            "\\1\n      # Analytics\n      {:phoenix_analytics, \"~> 0.3\"},"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_phoenix_analytics_config(igniter) do
    config_content = """
    # Configure Phoenix Analytics - https://hexdocs.pm/phoenix_analytics/readme.html#installation
    config :phoenix_analytics,
      app_domain: System.get_env("PHX_HOST") || "example.com",
      cache_ttl: System.get_env("CACHE_TTL") || 120,
      postgres_conn:
        System.get_env("POSTGRES_CONN") ||
          "dbname=neptuner_dev user=postgres password=postgres host=localhost",
      in_memory: true
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :phoenix_analytics") do
        # Config already exists
        source
      else
        # Add Phoenix Analytics config before the import_config line
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

  defp update_endpoint_with_tracker_plug(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/endpoint.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "plug PhoenixAnalytics.Plugs.RequestTracker") do
        # Plug already exists
        source
      else
        # Add RequestTracker plug after static plug
        updated_content =
          String.replace(
            content,
            ~r/(plug Plug\.Static,[\s\S]*?only: NeptunerWeb\.static_paths\(\))/,
            "\\1\n\n  plug PhoenixAnalytics.Plugs.RequestTracker"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_router_with_analytics(igniter) do
    igniter
    |> Igniter.update_file("lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "use PhoenixAnalytics.Web, :router") do
        # Analytics router already added
        source
      else
        # Add PhoenixAnalytics.Web use after the main router use
        updated_content =
          String.replace(
            content,
            ~r/(use NeptunerWeb, :router)/,
            "\\1\n  use PhoenixAnalytics.Web, :router"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
    |> Igniter.update_file("lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "phoenix_analytics_dashboard(\"/analytics\")") do
        # Dashboard route already exists
        source
      else
        # Add analytics dashboard route after design system route
        updated_content =
          String.replace(
            content,
            ~r/(get "\/design-system", NeptunerWeb\.PageController, :design_system)/,
            "\\1\n\n      # Phoenix Analytics dashboard\n      phoenix_analytics_dashboard(\"/analytics\")"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_analytics_migration(igniter) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")

    migration_content = """
    defmodule Neptuner.Repo.Migrations.AddPhoenixAnalytics do
      use Ecto.Migration

      def up, do: PhoenixAnalytics.Migration.up()
      def down, do: PhoenixAnalytics.Migration.down()
    end
    """

    Igniter.create_new_file(
      igniter,
      "priv/repo/migrations/#{timestamp}_add_phoenix_analytics.exs",
      migration_content
    )
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Phoenix Analytics Integration Complete! 📊

    ⚠️  **IMPORTANT WARNING**: Fly.io does not support Phoenix Analytics at the time of writing.
    This integration should only be used if you plan to deploy outside of Fly.io or can use alternative hosting.

    Phoenix Analytics has been successfully integrated into your SaaS template. Here's what was configured:

    ### Configuration Added:
    - Phoenix Analytics config in config/config.exs with development database settings
    - In-memory caching enabled for development
    - Default app domain set to "example.com" (configurable via PHX_HOST env var)

    ### Code Updates:
    - RequestTracker plug added to endpoint.ex
    - Analytics router functionality added to router.ex
    - Analytics dashboard route added at /dev/analytics

    ### Files Created:
    - Database migration for Phoenix Analytics tables

    ### Next Steps:
    1. Run `mix ecto.migrate` to create the analytics tables
    2. Visit `/dev/analytics` in development to see the dashboard
    3. Configure production environment variables:
       - PHX_HOST: Your production domain
       - POSTGRES_CONN: Production database connection string
       - CACHE_TTL: Cache timeout in seconds (optional)

    ### Analytics Dashboard:
    - Available at: http://localhost:4000/dev/analytics
    - Tracks page views, user sessions, and request metrics
    - Real-time analytics with automatic data collection

    🎉 Your app is now tracking analytics automatically!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
