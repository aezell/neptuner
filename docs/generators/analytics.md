# Analytics Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

> **⚠️ Deployment Warning:** Fly.io does not support Phoenix Analytics at the time of writing. This generator should only be used if you plan to deploy outside of Fly.io or can use alternative hosting platforms - see [this Github Issue for more information](https://github.com/lalabuy948/PhoenixAnalytics/issues/31)

## Overview

The Analytics Generator integrates Phoenix Analytics into your SaaS template application, providing comprehensive web analytics tracking and a dashboard for monitoring user behavior, page views, and request metrics. This generator automates the entire setup process, including dependency management, configuration, database migrations, and routing.

## Installation

Run the generator using the Mix task:

```bash
mix neptuner.gen.analytics
```

After running the generator, you'll need to run the database migration:

```bash
mix ecto.migrate
```

## What It Does

The analytics generator performs the following automated setup:

### 1. **Dependency Management**
- Adds `{:phoenix_analytics, "~> 0.3"}` to your `mix.exs` dependencies
- Automatically detects if the dependency already exists to prevent duplicates

### 2. **Configuration Setup**
- Adds Phoenix Analytics configuration to `config/config.exs`
- Sets up default development database connection parameters
- Configures in-memory caching for development environment
- Sets default app domain to "example.com" (configurable via environment variables)

### 3. **Endpoint Integration**
- Adds `PhoenixAnalytics.Plugs.RequestTracker` plug to your endpoint
- Enables automatic request tracking for all incoming requests
- Integrates seamlessly with existing static file serving

### 4. **Router Updates**
- Adds `use PhoenixAnalytics.Web, :router` to enable analytics routing functionality
- Creates analytics dashboard route at `/analytics` for development access
- Maintains existing routing structure and functionality

### 5. **Database Migration**
- Creates a timestamped migration file for Phoenix Analytics database tables
- Uses Phoenix Analytics built-in migration functions for consistent schema setup
- Ensures proper database structure for analytics data storage

## Configuration

### Environment Variables

The generator supports the following environment variables for production configuration:

- **`PHX_HOST`**: Your production domain (defaults to "example.com")
- **`POSTGRES_CONN`**: Production database connection string
- **`CACHE_TTL`**: Cache timeout in seconds (defaults to 120)

### Default Configuration

The generator creates this configuration in `config/config.exs`:

```elixir
# Configure Phoenix Analytics - https://hexdocs.pm/phoenix_analytics/readme.html#installation
config :phoenix_analytics,
  app_domain: System.get_env("PHX_HOST") || "example.com",
  cache_ttl: System.get_env("CACHE_TTL") || 120,
  postgres_conn:
    System.get_env("POSTGRES_CONN") ||
      "dbname=neptuner_dev user=postgres password=postgres host=localhost",
  in_memory: true
```

### Production Configuration

For production environments, set the following environment variables:

```bash
export PHX_HOST="yourdomain.com"
export POSTGRES_CONN="dbname=your_prod_db user=your_user password=your_password host=your_host"
export CACHE_TTL=300
```

## Usage

### Accessing the Analytics Dashboard

After installation and migration, you can access the analytics dashboard at:

**Development:** `http://localhost:4000/analytics`

The dashboard provides:
- **Page Views**: Track which pages are most visited
- **User Sessions**: Monitor user engagement and session duration
- **Request Metrics**: Analyze request patterns and performance
- **Real-time Data**: Live updates as users interact with your application

### Analytics Data Collection

Phoenix Analytics automatically collects:
- Page view counts and paths
- User session information
- Request timing and frequency
- Referrer information
- User agent details

### Querying Analytics Data

You can programmatically access analytics data using Phoenix Analytics functions:

```elixir
# Get page view statistics
PhoenixAnalytics.get_page_views()

# Get session data
PhoenixAnalytics.get_sessions()

# Get request metrics
PhoenixAnalytics.get_request_metrics()
```

## Examples

### Custom Analytics Tracking

You can add custom analytics events in your LiveViews:

```elixir
defmodule MyAppWeb.ProductLive.Show do
  use MyAppWeb, :live_view

  def handle_event("track_product_view", %{"product_id" => product_id}, socket) do
    # Custom tracking logic can be added here
    PhoenixAnalytics.track_event("product_view", %{product_id: product_id})
    {:noreply, socket}
  end
end
```

### Analytics in Controllers

Track custom events in your controllers:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  def create(conn, %{"user" => user_params}) do
    case MyApp.Accounts.create_user(user_params) do
      {:ok, user} ->
        PhoenixAnalytics.track_event("user_registration", %{user_id: user.id})
        redirect(conn, to: ~p"/dashboard")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
```

## Next Steps

After successful installation:

1. **Run Database Migration**
   ```bash
   mix ecto.migrate
   ```

2. **Start Your Development Server**
   ```bash
   mix phx.server
   ```

3. **Visit the Analytics Dashboard**
   Navigate to `http://localhost:4000/analytics` to see your analytics dashboard

4. **Generate Some Traffic**
   Browse your application to generate sample analytics data

5. **Configure Production Environment**
   Set up production environment variables for your deployment:
   ```bash
   # Example production configuration
   export PHX_HOST="myapp.com"
   export POSTGRES_CONN="postgres://user:pass@db.example.com/myapp_prod"
   export CACHE_TTL=600
   ```

6. **Monitor and Optimize**
   Use the analytics data to understand user behavior and optimize your application performance

7. **Customize Analytics**
   Extend the analytics functionality by adding custom events and metrics specific to your SaaS application

The analytics system will now automatically track all user interactions and provide valuable insights into your application's usage patterns and performance metrics.
