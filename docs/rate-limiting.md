# Rate Limiting

## Overview

The SaaS Template includes built-in rate limiting to protect your application from abuse, brute force attacks, and excessive API usage. The rate limiting system uses the Hammer library with an ETS backend to provide fast, in-memory rate limiting based on client IP addresses.

## How It Works

### Rate Limiting Strategy
- **IP-Based Limiting**: Rate limits are applied per client IP address
- **Sliding Window**: Uses a sliding time window for more accurate rate limiting
- **ETS Backend**: In-memory storage for high performance and low latency
- **Automatic Cleanup**: Periodically cleans up expired rate limit entries

### Default Configuration

The system is configured with sensible defaults in `config/config.exs`:

```elixir
config :neptuner,
  rate_limit: %{
    limit_per_time_period: 1000,
    time_period_minutes: 1
  }
```

This allows **1000 requests per minute** per IP address.

## Implementation Details

### Core Components

#### 1. Rate Limit Module (`lib/neptuner_web/rate_limit.ex`)
```elixir
defmodule Neptuner.RateLimit do
  use Hammer, backend: :ets
end
```

This module configures Hammer with an ETS backend for fast in-memory rate limiting.

#### 2. Application Supervision (`lib/neptuner/application.ex`)
The rate limiter is started as part of the supervision tree:

```elixir
{NeptunerWeb.RateLimit, clean_period: :timer.minutes(1)}
```

- **Clean Period**: Removes expired entries every minute to prevent memory bloat

#### 3. Endpoint Integration (`lib/neptuner_web/endpoint.ex`)
Rate limiting is enforced at the endpoint level before request processing:

```elixir
plug RemoteIp
plug :rate_limit
```

### Rate Limiting Logic

The rate limiting function in the endpoint:

```elixir
defp rate_limit(conn, _opts) do
  key = "web_requests:#{:inet.ntoa(conn.remote_ip)}"
  scale = :timer.minutes(@rate_limit_config[:time_period_minutes])
  limit = @rate_limit_config[:limit_per_time_period]

  case NeptunerWeb.RateLimit.hit(key, scale, limit) do
    {:allow, _count} ->
      conn

    {:deny, retry_after} ->
      retry_after_seconds = div(retry_after, 1000)

      conn
      |> put_resp_header("retry-after", Integer.to_string(retry_after_seconds))
      |> send_resp(429, [])
      |> halt()
  end
end
```

#### Key Generation
- Format: `"web_requests:{ip_address}"`
- Uses `RemoteIp` plug to get the real client IP (handles proxies and load balancers)

#### Response Handling
- **Allowed Requests**: Pass through normally
- **Rate Limited**: Return HTTP 429 (Too Many Requests) with `Retry-After` header

## Configuration

### Environment-Specific Settings

You can customize rate limiting per environment:

```elixir
# config/dev.exs - More lenient for development
config :neptuner,
  rate_limit: %{
    limit_per_time_period: 5000,
    time_period_minutes: 1
  }

# config/prod.exs - Stricter for production
config :neptuner,
  rate_limit: %{
    limit_per_time_period: 500,
    time_period_minutes: 1
  }

# config/test.exs - Very high limits for testing
config :neptuner,
  rate_limit: %{
    limit_per_time_period: 10000,
    time_period_minutes: 1
  }
```

### Rate Limit Parameters

| Parameter | Description | Default | Example Values |
|-----------|-------------|---------|----------------|
| `limit_per_time_period` | Number of requests allowed | 1000 | 100, 500, 2000 |
| `time_period_minutes` | Time window in minutes | 1 | 1, 5, 15, 60 |

### Advanced Configuration

For more sophisticated rate limiting, you can configure different limits for different endpoints:

```elixir
# In your router or controller
defp api_rate_limit(conn, _opts) do
  key = "api_requests:#{:inet.ntoa(conn.remote_ip)}"
  scale = :timer.minutes(1)
  limit = 100  # Stricter limit for API endpoints

  case NeptunerWeb.RateLimit.hit(key, scale, limit) do
    {:allow, _count} -> conn
    {:deny, retry_after} ->
      conn
      |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
      |> send_resp(429, Jason.encode!(%{error: "Rate limit exceeded"}))
      |> halt()
  end
end
```

## Dependencies

### Required Packages

The rate limiting system requires these dependencies (automatically added):

```elixir
# mix.exs
{:hammer, "~> 7.1.0"},    # Rate limiting library
{:remote_ip, "~> 1.2.0"}  # Real IP detection through proxies
```

### RemoteIp Configuration

For production deployments behind proxies or load balancers, configure RemoteIp:

```elixir
# config/prod.exs
config :remote_ip,
  headers: ["x-forwarded-for", "x-real-ip"],
  proxies: ["127.0.0.1/8", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
```

## Monitoring and Observability

### Telemetry Events

Hammer emits telemetry events you can use for monitoring:

```elixir
# Subscribe to rate limiting events
:telemetry.attach("rate-limit-monitor", [:hammer, :rate_limit], fn event, measurements, metadata, _config ->
  case metadata do
    %{result: :deny, key: key} ->
      Logger.warning("Rate limit exceeded for #{key}")
    _ ->
      :ok
  end
end, nil)
```

### Metrics to Monitor

- **Rate limit violations per minute**: Track how often clients hit limits
- **Top rate-limited IPs**: Identify potential abuse sources
- **Rate limit hit ratio**: Percentage of requests that are rate limited
- **Memory usage**: Monitor ETS table size for rate limit data

### Custom Logging

Add rate limiting logging to your endpoint:

```elixir
defp rate_limit(conn, _opts) do
  key = "web_requests:#{:inet.ntoa(conn.remote_ip)}"
  scale = :timer.minutes(@rate_limit_config[:time_period_minutes])
  limit = @rate_limit_config[:limit_per_time_period]

  case NeptunerWeb.RateLimit.hit(key, scale, limit) do
    {:allow, count} ->
      if count > limit * 0.8 do
        Logger.info("Rate limit warning: #{key} at #{count}/#{limit} requests")
      end
      conn

    {:deny, retry_after} ->
      Logger.warning("Rate limit exceeded: #{key}, retry after #{retry_after}ms")

      conn
      |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
      |> send_resp(429, [])
      |> halt()
  end
end
```

## Security Considerations

### Protection Against
- **Brute Force Attacks**: Limits login attempts per IP
- **DDoS Mitigation**: Prevents overwhelming the server with requests
- **API Abuse**: Protects against excessive API usage
- **Resource Exhaustion**: Prevents individual clients from consuming all resources

### Best Practices
- **Configure Appropriate Limits**: Balance user experience with protection
- **Monitor for Abuse**: Track rate limiting violations
- **Combine with Other Protections**: Use alongside authentication, CSRF, and input validation
- **Consider User Experience**: Provide clear error messages and retry guidance

### Limitations
- **Memory-Based**: Rate limits are lost on server restart
- **Single-Node**: ETS backend doesn't share limits across multiple nodes
- **IP-Based Only**: May not be suitable for shared IPs (corporate networks)

## Customization Examples

### Different Limits by User Type

```elixir
defp authenticated_rate_limit(conn, _opts) do
  {key, limit} = if user = conn.assigns[:current_user] do
    case user.subscription_tier do
      :premium -> {"premium_user:#{user.id}", 5000}
      :basic -> {"basic_user:#{user.id}", 1000}
      _ -> {"free_user:#{user.id}", 100}
    end
  else
    {"guest:#{:inet.ntoa(conn.remote_ip)}", 50}
  end

  case NeptunerWeb.RateLimit.hit(key, :timer.minutes(1), limit) do
    {:allow, _count} -> conn
    {:deny, retry_after} ->
      conn
      |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
      |> send_resp(429, Jason.encode!(%{
        error: "Rate limit exceeded",
        limit: limit,
        window: "1 minute"
      }))
      |> halt()
  end
end
```

### Endpoint-Specific Limits

```elixir
# In your router
pipeline :api_strict do
  plug :rate_limit_api
end

pipeline :web_lenient do
  plug :rate_limit_web
end

defp rate_limit_api(conn, _opts) do
  apply_rate_limit(conn, "api", 100, 1)
end

defp rate_limit_web(conn, _opts) do
  apply_rate_limit(conn, "web", 1000, 1)
end

defp apply_rate_limit(conn, prefix, limit, minutes) do
  key = "#{prefix}_requests:#{:inet.ntoa(conn.remote_ip)}"
  scale = :timer.minutes(minutes)

  case NeptunerWeb.RateLimit.hit(key, scale, limit) do
    {:allow, _count} -> conn
    {:deny, retry_after} ->
      conn
      |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
      |> send_resp(429, [])
      |> halt()
  end
end
```

## Production Deployment

### Scaling Considerations

For multi-node deployments, consider:

1. **Redis Backend**: Use `{:hammer_backend_redis, "~> 6.0"}` for shared rate limiting
2. **Load Balancer Configuration**: Ensure consistent IP forwarding
3. **Health Checks**: Exclude health check endpoints from rate limiting

### Redis Backend Setup

```elixir
# mix.exs
{:hammer_backend_redis, "~> 6.0"}

# config/prod.exs
config :hammer,
  backend: {Hammer.Backend.Redis, [
    expiry_ms: 60_000 * 60 * 2,  # 2 hours
    redix_config: [
      host: System.get_env("REDIS_HOST", "localhost"),
      port: String.to_integer(System.get_env("REDIS_PORT", "6379"))
    ]
  ]}
```

## Testing

### Unit Testing Rate Limits

```elixir
defmodule NeptunerWeb.RateLimitTest do
  use NeptunerWeb.ConnCase

  test "allows requests under rate limit", %{conn: conn} do
    # Make several requests under the limit
    for _ <- 1..10 do
      conn = get(conn, ~p"/")
      assert conn.status == 200
    end
  end

  test "blocks requests over rate limit", %{conn: conn} do
    # Configure very low limit for testing
    rate_limit_config = %{limit_per_time_period: 5, time_period_minutes: 1}

    # Make requests up to the limit
    for _ <- 1..5 do
      conn = get(conn, ~p"/")
      assert conn.status == 200
    end

    # Next request should be rate limited
    conn = get(conn, ~p"/")
    assert conn.status == 429
    assert get_resp_header(conn, "retry-after") != []
  end
end
```

### Load Testing

Use tools like `k6` or `wrk` to test rate limiting:

```bash
# Install k6 and test rate limiting
k6 run --vus 10 --duration 30s rate_limit_test.js
```

## Troubleshooting

### Common Issues

1. **Rate Limits Too Strict**: Users can't complete normal workflows
   - **Solution**: Increase `limit_per_time_period` or `time_period_minutes`

2. **Memory Usage Growing**: ETS table consuming too much memory
   - **Solution**: Decrease cleanup period or implement custom cleanup logic

3. **Load Balancer Issues**: Incorrect IP addresses being rate limited
   - **Solution**: Configure `RemoteIp` with correct proxy headers

4. **False Positives**: Legitimate users being blocked
   - **Solution**: Implement user-based rate limiting for authenticated users

### Debugging Rate Limits

```elixir
# Check current rate limit status
NeptunerWeb.RateLimit.inspect_bucket("web_requests:192.168.1.1", :timer.minutes(1))

# Manual rate limit testing in IEx
iex> NeptunerWeb.RateLimit.hit("test_key", :timer.minutes(1), 10)
{:allow, 1}

iex> NeptunerWeb.RateLimit.hit("test_key", :timer.minutes(1), 10)
{:allow, 2}
```

The rate limiting system provides robust protection against abuse while maintaining good performance and user experience. Monitor usage patterns and adjust limits based on your application's specific needs.
