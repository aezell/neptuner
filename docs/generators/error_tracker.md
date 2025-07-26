# Error Tracker Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Error Tracker Generator integrates Error Tracker into your SaaS template application, providing comprehensive error monitoring, tracking, and analysis capabilities. This generator automates the entire setup process, including dependency management, configuration, database migrations, and routing for both development and production environments.

## Installation

Run the generator using the Mix task:

```bash
mix neptuner.gen.error_tracker
```

After running the generator, you'll need to run the database migration:

```bash
mix ecto.migrate
```

## What It Does

The error tracker generator performs the following automated setup:

### 1. **Dependency Management**
- Adds `{:error_tracker, "~> 0.6"}` to your `mix.exs` dependencies
- Automatically detects if the dependency already exists to prevent duplicates

### 2. **Configuration Setup**
- Adds Error Tracker configuration to `config/config.exs`
- Configures the database repository and OTP application
- Enables error tracking for all environments

### 3. **Router Updates**
- Adds `use ErrorTracker.Web, :router` to enable error tracking routing functionality
- Creates admin-protected error dashboard route at `/admin/errors`
- Creates development-only error dashboard route at `/dev/errors`
- Maintains existing routing structure and functionality

### 4. **Database Migration**
- Creates a timestamped migration file for Error Tracker database tables
- Uses Error Tracker built-in migration functions for consistent schema setup
- Ensures proper database structure for error data storage

## Configuration

### Default Configuration

The generator creates this configuration in `config/config.exs`:

```elixir
config :error_tracker,
  repo: Neptuner.Repo,
  otp_app: :neptuner,
  enabled: true
```

### Environment-Specific Configuration

You can customize error tracking behavior per environment by adding configuration in your environment-specific config files:

```elixir
# config/prod.exs
config :error_tracker,
  enabled: true,
  ignore_errors: [Phoenix.Router.NoRouteError],
  automatic_pruning: [
    max_age: 90 * 24 * 60 * 60,  # 90 days in seconds
    frequency: 24 * 60 * 60       # daily pruning
  ]

# config/dev.exs  
config :error_tracker,
  enabled: true

# config/test.exs
config :error_tracker,
  enabled: false
```

### Additional Configuration Options

Error Tracker supports additional configuration options:

- **`ignore_errors`**: List of error types to ignore
- **`automatic_pruning`**: Configure automatic cleanup of old errors
- **`breadcrumb_size`**: Maximum number of breadcrumbs to store
- **`context_size`**: Maximum size of error context data
- **`telemetry_enabled`**: Enable/disable telemetry events

## Usage

### Accessing the Error Dashboard

After installation and migration, you can access the error dashboard at:

**Development:** `http://localhost:4000/dev/errors`
**Production:** `http://yourapp.com/admin/errors` (requires admin authentication)

The dashboard provides:
- **Error Overview**: Real-time error tracking with occurrence counts
- **Error Grouping**: Similar errors grouped together for easier analysis
- **Stack Traces**: Full stack trace information for debugging
- **Error Context**: Request information, user data, and metadata
- **Historical Data**: Error trends and patterns over time

### Automatic Error Tracking

Error Tracker automatically captures errors from:
- **Phoenix Controllers**: All controller errors and exceptions
- **LiveViews**: LiveView process crashes and errors
- **Oban Jobs**: Background job failures (when Oban is configured)
- **Plug Pipeline**: Errors in the Plug pipeline
- **Database Operations**: Ecto query errors and connection issues

All automatic tracking includes:
- Full stack traces with code context
- Request information (when applicable)
- Process information
- Timestamps and occurrence counting

### Manual Error Reporting

You can manually report errors in your application code using the `ErrorTracker.report/2` and `ErrorTracker.report/3` functions:

```elixir
# Report an error with stack trace
try do
  dangerous_operation()
catch
  error ->
    ErrorTracker.report(error, __STACKTRACE__)
    reraise error, __STACKTRACE__
end

# Report an error with additional context
try do
  dangerous_operation()
catch
  error ->
    ErrorTracker.report(error, __STACKTRACE__, %{user_id: user.id, action: "create_post"})
    reraise error, __STACKTRACE__
end
```

### Error Context Enrichment

You can enrich error context globally using `ErrorTracker.set_context/1`:

```elixir
# Set context that will be included in all subsequent errors
ErrorTracker.set_context(%{user_id: current_user.id, request_id: request_id})
```

## Examples

### Context Enrichment in LiveViews

You can enrich error context in your LiveViews so all errors include relevant information:

```elixir
defmodule MyAppWeb.ProductLive.Show do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    # Set context for all errors in this LiveView
    ErrorTracker.set_context(%{
      user_id: socket.assigns.current_user.id,
      live_view: "ProductLive.Show"
    })
    
    {:ok, socket}
  end

  def handle_event("delete_product", %{"id" => id}, socket) do
    try do
      case MyApp.Products.delete_product(id) do
        {:ok, _product} ->
          {:noreply, put_flash(socket, :info, "Product deleted successfully")}
        {:error, changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to delete product")}
      end
    catch
      error ->
        # Report the error with additional context
        ErrorTracker.report(error, __STACKTRACE__, %{product_id: id, action: "delete_product"})
        {:noreply, put_flash(socket, :error, "An unexpected error occurred")}
    end
  end
end
```

### Error Tracking in Background Jobs

Error Tracker automatically integrates with Oban jobs, but you can also manually report errors with additional context:

```elixir
defmodule MyApp.Workers.EmailWorker do
  use Oban.Worker, queue: :emails

  def perform(%Oban.Job{args: %{"email_id" => email_id}}) do
    # Set context for this job
    ErrorTracker.set_context(%{
      job: "EmailWorker",
      email_id: email_id,
      queue: "emails"
    })

    try do
      MyApp.Emails.send_email(email_id)
    catch
      error ->
        # Additional context for this specific error
        ErrorTracker.report(error, __STACKTRACE__, %{operation: "send_email"})
        {:error, "Email sending failed"}
    end
  end
end
```

### Error Context in Controllers

Add custom context to controller errors using context enrichment:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  def create(conn, %{"user" => user_params}) do
    # Set context for all errors in this request
    ErrorTracker.set_context(%{
      controller: "UserController",
      action: "create",
      ip_address: get_peer_data(conn).address
    })

    try do
      case MyApp.Accounts.create_user(user_params) do
        {:ok, user} ->
          redirect(conn, to: ~p"/dashboard")
        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    catch
      error ->
        # Report error with additional context
        ErrorTracker.report(error, __STACKTRACE__, %{
          user_params: user_params,
          operation: "create_user"
        })
        conn
        |> put_flash(:error, "An unexpected error occurred")
        |> render(:new, changeset: %Ecto.Changeset{})
    end
  end
end
```

## Dashboard Features

### Error Overview
- **Total Errors**: Count of all errors in selected time period
- **Unique Errors**: Count of distinct error types
- **Error Rate**: Errors per minute/hour/day
- **Most Frequent**: Top error types by occurrence

### Error Details
- **Stack Traces**: Full stack trace with code context
- **Request Information**: HTTP method, path, params, headers
- **User Context**: User ID, session data, and custom context
- **Environment**: Server information, versions, and configuration

### Error Management
- **Mark as Resolved**: Mark errors as fixed
- **Ignore Errors**: Ignore specific error types
- **Error Grouping**: Automatic grouping of similar errors
- **Search and Filter**: Find specific errors quickly

## Advanced Features

### Telemetry Integration

Error Tracker emits telemetry events that you can use for monitoring and alerting:

```elixir
# Subscribe to error tracking events
:telemetry.attach("error-tracker-handler", [:error_tracker, :error, :new], fn event, measurements, metadata, _config ->
  # Handle error event - send to monitoring service, alert, etc.
  IO.inspect({event, measurements, metadata})
end, nil)
```

### Automatic Error Pruning

Configure automatic cleanup of old errors to prevent database bloat:

```elixir
config :error_tracker,
  automatic_pruning: [
    max_age: 90 * 24 * 60 * 60,  # Keep errors for 90 days
    frequency: 24 * 60 * 60,      # Run cleanup daily
    limit: 1000                   # Process max 1000 errors per cleanup
  ]
```

## Production Considerations

### Security
- Error dashboard is protected by admin authentication in production
- Stack traces and sensitive data are safely displayed to authorized users only
- Configure context size limits to prevent sensitive data leakage

### Performance
- Error tracking has minimal performance impact
- Database queries are optimized for fast error reporting
- Automatic cleanup of old error records to prevent database bloat
- Configurable context and breadcrumb size limits

### Monitoring
- Use telemetry events for real-time monitoring and alerting
- Monitor error trends to identify issues early
- Set up automated alerts for critical error patterns
- Use error data to improve application reliability

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

3. **Visit the Error Dashboard**
   - Development: Navigate to `http://localhost:4000/dev/errors`
   - Production: Navigate to `http://yourapp.com/admin/errors` (requires admin auth)

4. **Test Error Tracking**
   - Trigger an error in your application to see it appear in the dashboard
   - Check that errors are properly grouped and displayed

5. **Configure Production Environment**
   - Review error tracking settings for production
   - Set up alerts for critical errors
   - Configure error retention policies

6. **Customize Error Handling**
   - Add custom error reporting in critical parts of your application
   - Configure error ignoring for known, non-critical errors
   - Set up error notifications for your team

7. **Monitor and Analyze**
   - Use the dashboard to identify common error patterns
   - Track error trends over time
   - Use error data to prioritize bug fixes and improvements

The error tracking system will now automatically monitor your application, providing valuable insights into application health and helping you quickly identify and resolve issues.