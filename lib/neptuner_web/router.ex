defmodule NeptunerWeb.Router do
  use NeptunerWeb, :router
  import Oban.Web.Router
  use ErrorTracker.Web, :router
  use PhoenixAnalytics.Web, :router

  import NeptunerWeb.UserAuth
  import Backpex.Router

  pipeline :mounted_apps do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug :assign_org_to_scope
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NeptunerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug :assign_org_to_scope
  end

  pipeline :admin_protected do
    plug NeptunerWeb.Plugs.AdminAuthentication
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NeptunerWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/blog", BlogController, :index
    get "/blog/:slug", BlogController, :show
    post "/waitlist", WaitlistController, :join
    get "/terms", LegalController, :terms
    get "/privacy", LegalController, :privacy
    get "/changelog", ChangelogController, :index
    get "/sitemap.xml", SitemapController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", NeptunerWeb do
  #   pipe_through :api
  # end

  # Feature flags UI panel - admin protected
  scope path: "/feature-flags" do
    pipe_through [:browser, :admin_protected]
    forward "/", FunWithFlags.UI.Router, namespace: "feature-flags"
  end

  # Other admin protected pages
  scope "/admin" do
    pipe_through [:browser, :admin_protected]

    backpex_routes()

    live_session :default, on_mount: Backpex.InitAssigns do
      live_resources("/posts", NeptunerWeb.Live.Admin.PostLive)
    end

    error_tracker_dashboard("/errors")

    # Design system preview
    get "/design-system", NeptunerWeb.PageController, :design_system

    # Phoenix Analytics dashboard
    phoenix_analytics_dashboard("/analytics")
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:neptuner, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      # LiveDashboard
      live_dashboard "/dashboard", metrics: NeptunerWeb.Telemetry

      # Swoosh mailbox preview
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/" do
      pipe_through :browser

      oban_dashboard("/oban")
    end
  end

  ## Authentication routes

  scope "/", NeptunerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{NeptunerWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", NeptunerWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [
        {NeptunerWeb.UserAuth, :mount_current_scope}
      ] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/invitations/accept/:token", OrganisationsLive.Invitation, :accept
    end

    live_session :authenticated_user_org_setup,
      on_mount: [
        {NeptunerWeb.UserAuth, :require_authenticated},
        {NeptunerWeb.UserAuth, :assign_org_to_scope}
      ] do
      live "/organisations/new", OrganisationsLive.New, :new
    end

    # Onboarding route (no onboarding check for obvious reasons)
    live_session :onboarding_flow,
      on_mount: [
        {NeptunerWeb.UserAuth, :require_authenticated},
        {NeptunerWeb.UserAuth, :assign_org_to_scope},
        {NeptunerWeb.UserAuth, :require_organisation}
      ] do
      live "/onboarding", OnboardingLive, :index
    end

    # Main app routes that check for onboarding completion
    live_session :fully_authenticated_user,
      on_mount: [
        {NeptunerWeb.UserAuth, :require_authenticated},
        {NeptunerWeb.UserAuth, :assign_org_to_scope},
        {NeptunerWeb.UserAuth, :require_organisation},
        {NeptunerWeb.UserAuth, :redirect_if_onboarding_needed}
      ] do
      live "/dashboard", DashboardLive, :index
      live "/organisations/manage", OrganisationsLive.Manage, :manage
      live "/connections", ConnectionsLive.Index, :index
      live "/tasks", TasksLive.Index, :index
      live "/tasks/new", TasksLive.Index, :new
      live "/tasks/:id/edit", TasksLive.Index, :edit
      live "/habits", HabitsLive.Index, :index
      live "/habits/new", HabitsLive.Index, :new
      live "/habits/:id/edit", HabitsLive.Index, :edit
      live "/calendar", CalendarLive.Index, :index
      live "/communications", CommunicationsLive.Index, :index
      live "/achievements", AchievementsLive.Index, :index
      live "/import", ImportLive.Index, :index
      live "/subscription", SubscriptionLive, :index

      # CalDAV connection form
      live "/connections/caldav/new", ConnectionsLive.CalDAVNew, :new

      # Premium data export
      get "/export", ExportController, :export_options
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete

    scope "/auth" do
      get "/google", GoogleAuthController, :request
      get "/google/callback", GoogleAuthController, :callback
      get "/github", GitHubAuthController, :request
      get "/github/callback", GitHubAuthController, :callback
    end
  end

  # Service OAuth (separate from user auth)
  scope "/oauth", NeptunerWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/:provider/connect", ServiceOAuthController, :connect
    get "/:provider/callback", ServiceOAuthController, :callback
    delete "/:id/disconnect", ServiceOAuthController, :disconnect
  end

  # Sync API endpoints
  scope "/sync", NeptunerWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/connection/:connection_id", SyncController, :sync_connection
    post "/all", SyncController, :sync_all_connections
    get "/status", SyncController, :sync_status

    # Test endpoints for integration debugging
    post "/test/calendar/:connection_id", SyncController, :test_calendar_sync
    post "/test/email/:connection_id", SyncController, :test_email_sync
  end

  # Data export endpoints (premium feature)
  scope "/export", NeptunerWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/all", ExportController, :export_all
    post "/dataset", ExportController, :export_dataset
  end

  # Webhook endpoints (no authentication required for external services)
  scope "/webhooks", NeptunerWeb do
    pipe_through :api

    post "/google/calendar", WebhookController, :google_calendar
    post "/google/gmail", WebhookController, :gmail
    post "/microsoft/graph", WebhookController, :microsoft_graph
    get "/health", WebhookController, :health
  end
end
