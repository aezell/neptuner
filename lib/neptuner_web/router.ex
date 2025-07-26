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

    live_session :fully_authenticated_user,
      on_mount: [
        {NeptunerWeb.UserAuth, :require_authenticated},
        {NeptunerWeb.UserAuth, :assign_org_to_scope},
        {NeptunerWeb.UserAuth, :require_organisation}
      ] do
      live "/dashboard", DashboardLive, :index
      live "/organisations/manage", OrganisationsLive.Manage, :manage
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
end
