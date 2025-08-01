# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :neptuner, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10, token_refresh: 5],
  repo: Neptuner.Repo

config :neptuner, :scopes,
  user: [
    default: true,
    module: Neptuner.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Neptuner.AccountsFixtures,
    test_login_helper: :register_and_log_in_user
  ],
  organisation: [
    module: Neptuner.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:organisation, :id],
    schema_key: :org_id,
    schema_type: :id,
    schema_table: :organisations,
    test_data_fixture: Neptuner.AccountsFixtures,
    test_login_helper: :register_and_log_in_user_with_org
  ]

config :neptuner,
  ecto_repos: [Neptuner.Repo],
  generators: [timestamp_type: :utc_datetime],
  app_name: "Neptuner",
  socials: [
    twitter_handle: "@social_handle",
    instagram_handle: "@social_handle",
    linkedin_handle: "@social_handle",
    bluesky_handle: "@social_handle"
  ],
  rate_limit: %{
    limit_per_time_period: 1000,
    time_period_minutes: 1
  }

# Configures the endpoint
config :neptuner, NeptunerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: NeptunerWeb.ErrorHTML, json: NeptunerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Neptuner.PubSub,
  live_view: [signing_salt: "WjF7P0jb"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :neptuner, Neptuner.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  neptuner: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  neptuner: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures FunWithFlags
config :fun_with_flags, :cache,
  enabled: true,
  ttl: 900

config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: Neptuner.Repo,
  ecto_table_name: "feature_flags",
  ecto_primary_key_type: :binary_id

config :fun_with_flags, :cache_bust_notifications, enabled: false

# Configure Phoenix Analytics - https://hexdocs.pm/phoenix_analytics/readme.html#installation
config :phoenix_analytics,
  app_domain: System.get_env("PHX_HOST") || "example.com",
  cache_ttl: System.get_env("CACHE_TTL") || 120,
  postgres_conn:
    System.get_env("POSTGRES_CONN") ||
      "dbname=neptuner_dev user=postgres password=postgres host=localhost",
  in_memory: true

config :error_tracker,
  repo: Neptuner.Repo,
  otp_app: :neptuner,
  enabled: true

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user"]},
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")

config :langchain, openai_key: System.get_env("OPENAI_API_KEY")

config :backpex, :pubsub_server, Neptuner.PubSub

config :backpex,
  translator_function: {NeptunerWeb.CoreComponents, :translate_backpex},
  error_translator_function: {NeptunerWeb.CoreComponents, :translate_error}

config :lemon_ex,
  api_key: System.get_env("LEMONSQUEEZY_API_KEY"),
  webhook_secret: System.get_env("LEMONSQUEEZY_WEBHOOK_SECRET"),
  # (Optional) You can provide HTTPoison options which are added to every request.
  # See all options here: https://hexdocs.pm/httpoison/HTTPoison.Request.html#content
  request_options: [timeout: 10_000]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Configures Basic Auth for Admin page access
config :neptuner, :basic_auth,
  username: "admin",
  password: System.get_env("ADMIN_PASSWORD", "admin123")
