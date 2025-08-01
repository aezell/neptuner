# Neptuner Deployment Guide

This guide covers deploying Neptuner, the ironically productive task management app that helps you navigate the cosmic significance (or lack thereof) of your digital tasks.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Development Setup](#development-setup)
- [OAuth Configuration](#oauth-configuration)
- [Database Setup](#database-setup)
- [Production Deployment](#production-deployment)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Elixir**: 1.15+ with OTP 26+
- **Phoenix**: 1.8.0-rc.0
- **Node.js**: 18+ (for asset compilation)
- **PostgreSQL**: 14+ 
- **Redis**: 6+ (for background jobs via Oban)

### Development Tools

```bash
# Install Elixir and Erlang via asdf (recommended)
asdf plugin add erlang
asdf plugin add elixir
asdf install erlang 26.2.1
asdf install elixir 1.15.7-otp-26
asdf global erlang 26.2.1
asdf global elixir 1.15.7-otp-26

# Install Phoenix
mix archive.install hex phx_new

# Install Node.js for asset compilation
asdf plugin add nodejs
asdf install nodejs 18.19.0
asdf global nodejs 18.19.0
```

## Environment Setup

### Environment Variables

Create a `.env` file in your project root:

```bash
# Database Configuration
DATABASE_URL="postgresql://username:password@localhost/neptuner_dev"
DATABASE_URL_TEST="postgresql://username:password@localhost/neptuner_test"

# Application URL (for OAuth callbacks)
APP_URL="http://localhost:4000"
PHX_HOST="localhost"
PORT="4000"

# Secret Keys (generate with: mix phx.gen.secret)
SECRET_KEY_BASE="your-secret-key-base-here"
LIVE_VIEW_SIGNING_SALT="your-live-view-salt-here"

# Google OAuth Configuration
GOOGLE_OAUTH_CLIENT_ID="your-google-client-id"
GOOGLE_OAUTH_CLIENT_SECRET="your-google-client-secret"

# Microsoft OAuth Configuration  
MICROSOFT_OAUTH_CLIENT_ID="your-microsoft-client-id"
MICROSOFT_OAUTH_CLIENT_SECRET="your-microsoft-client-secret"

# Apple OAuth Configuration
APPLE_OAUTH_CLIENT_ID="your-apple-service-id"
APPLE_OAUTH_TEAM_ID="your-apple-team-id"
APPLE_OAUTH_KEY_ID="your-apple-key-id"
APPLE_OAUTH_PRIVATE_KEY_PATH="/path/to/AuthKey_KEYID.p8"

# Email Configuration (for notifications)
SMTP_HOST="smtp.example.com"
SMTP_PORT="587"
SMTP_USERNAME="your-smtp-username"
SMTP_PASSWORD="your-smtp-password"
FROM_EMAIL="noreply@neptuner.app"

# Stripe Configuration (for subscriptions)
STRIPE_PUBLISHABLE_KEY="pk_test_..."
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."

# Error Tracking
SENTRY_DSN="https://your-sentry-dsn"

# Background Jobs
REDIS_URL="redis://localhost:6379/0"

# Feature Flags
FUN_WITH_FLAGS_REDIS_URL="redis://localhost:6379/1"
```

### Production Environment Variables

For production, ensure these additional variables are set:

```bash
# Production Database
DATABASE_URL="postgresql://user:pass@db-host:5432/neptuner_prod"

# Production URLs
APP_URL="https://your-domain.com"
PHX_HOST="your-domain.com"

# SSL Configuration
FORCE_SSL="true"

# Production Secrets (generate new ones!)
SECRET_KEY_BASE="production-secret-key-base"
LIVE_VIEW_SIGNING_SALT="production-live-view-salt"

# Asset CDN (optional)
STATIC_URL="https://cdn.your-domain.com"

# Monitoring
OTEL_EXPORTER_OTLP_ENDPOINT="https://your-monitoring-endpoint"
```

## Development Setup

### Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/neptuner.git
cd neptuner

# Install dependencies and set up database
mix setup

# Start the development server
mix phx.server
```

The application will be available at `http://localhost:4000`.

### Step-by-Step Setup

1. **Install Dependencies**
   ```bash
   mix deps.get
   ```

2. **Database Setup**
   ```bash
   # Create and migrate database
   mix ecto.setup
   
   # Run Neptuner-specific seeds
   mix run priv/repo/seeds_neptuner.exs
   ```

3. **Asset Setup**
   ```bash
   # Install and build assets
   mix assets.setup
   mix assets.build
   ```

4. **Development Tools**
   ```bash
   # Install development tools
   mix deps.get --only dev
   
   # Set up pre-commit hooks (optional)
   mix deps.compile
   ```

## OAuth Configuration

### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Gmail API and Google Calendar API
4. Create OAuth 2.0 credentials:
   - Application type: Web application
   - Authorized redirect URIs: `http://localhost:4000/oauth/google/callback` (dev)
   - For production: `https://your-domain.com/oauth/google/callback`
5. Copy Client ID and Client Secret to your `.env` file

**Required Scopes:**
- `https://www.googleapis.com/auth/gmail.readonly`
- `https://www.googleapis.com/auth/calendar.readonly`
- `email`
- `profile`

### Microsoft OAuth Setup

1. Go to [Azure App Registrations](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps)
2. Register a new application
3. Add redirect URI: `http://localhost:4000/oauth/microsoft/callback`
4. Grant API permissions:
   - Microsoft Graph: `Mail.Read`
   - Microsoft Graph: `Calendars.Read`
   - Microsoft Graph: `User.Read`
5. Create a client secret
6. Copy Application (client) ID and client secret to `.env`

### Apple Sign In Setup

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Create a Services ID under "Certificates, Identifiers & Profiles"
3. Configure Sign In with Apple:
   - Domains: `your-domain.com`
   - Return URLs: `https://your-domain.com/oauth/apple/callback`
4. Create a private key for Sign In with Apple
5. Download the `.p8` key file and set the path in `APPLE_OAUTH_PRIVATE_KEY_PATH`

### CalDAV Configuration

CalDAV connections use basic authentication. Users will need:
- CalDAV server URL (e.g., `https://caldav.icloud.com/` for iCloud)
- Username/email
- Password or app-specific password

Popular CalDAV servers:
- **iCloud**: `https://caldav.icloud.com/`
- **Google Calendar**: Use OAuth instead for better integration
- **Nextcloud**: `https://your-nextcloud.com/remote.php/dav/calendars/username/`

## Database Setup

### Development Database

```bash
# Create development database
createdb neptuner_dev

# Run migrations
mix ecto.migrate

# Seed with sample data
mix run priv/repo/seeds_neptuner.exs
```

### Production Database

```bash
# Create production database
createdb neptuner_prod

# Run migrations
MIX_ENV=prod mix ecto.migrate

# Optional: Create admin user
MIX_ENV=prod mix run -e "Neptuner.Accounts.create_admin_user(\"admin@example.com\", \"secure_password\")"
```

### Database Migrations

Key migrations include:
- User extensions for cosmic perspective tracking
- Task management with cosmic prioritization
- Habit tracking with existential commentary
- Service connections for OAuth integrations
- Email summaries with productivity analysis
- Achievement system with deflating congratulations

### Backup Strategy

```bash
# Create backup
pg_dump neptuner_prod > neptuner_backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
psql neptuner_prod < neptuner_backup_20240101_120000.sql
```

## Production Deployment

### Platform Options

#### Fly.io Deployment

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Initialize Fly App**
   ```bash
   fly launch
   ```

3. **Set Environment Variables**
   ```bash
   fly secrets set SECRET_KEY_BASE="your-production-secret"
   fly secrets set DATABASE_URL="your-production-database-url"
   fly secrets set GOOGLE_OAUTH_CLIENT_ID="your-google-client-id"
   # ... set all other production secrets
   ```

4. **Deploy**
   ```bash
   fly deploy
   ```

#### Heroku Deployment

1. **Create Heroku App**
   ```bash
   heroku create neptuner-prod
   heroku addons:create heroku-postgresql:hobby-dev
   heroku addons:create heroku-redis:hobby-dev
   ```

2. **Set Environment Variables**
   ```bash
   heroku config:set SECRET_KEY_BASE="your-production-secret"
   heroku config:set PHX_HOST="neptuner-prod.herokuapp.com"
   # ... set all other config vars
   ```

3. **Deploy**
   ```bash
   git push heroku main
   heroku run mix ecto.migrate
   ```

#### Docker Deployment

1. **Build Docker Image**
   ```bash
   docker build -t neptuner .
   ```

2. **Run with Docker Compose**
   ```yaml
   version: '3.8'
   services:
     app:
       image: neptuner:latest
       ports:
         - "4000:4000"
       environment:
         - DATABASE_URL=postgresql://postgres:postgres@db:5432/neptuner_prod
         - SECRET_KEY_BASE=your-secret-key
       depends_on:
         - db
         - redis
     
     db:
       image: postgres:14
       environment:
         - POSTGRES_DB=neptuner_prod
         - POSTGRES_PASSWORD=postgres
       volumes:
         - postgres_data:/var/lib/postgresql/data
     
     redis:
       image: redis:6
       
   volumes:
     postgres_data:
   ```

### Asset Compilation

For production deployment:

```bash
# Compile and optimize assets
MIX_ENV=prod mix assets.deploy

# This runs:
# - tailwind neptuner --minify
# - esbuild neptuner --minify  
# - phx.digest (for cache busting)
```

### SSL/HTTPS Configuration

#### Let's Encrypt with Certbot

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal (add to crontab)
0 12 * * * /usr/bin/certbot renew --quiet
```

#### Application Configuration

```elixir
# config/prod.exs
config :neptuner, NeptunerWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  url: [host: "your-domain.com", port: 443, scheme: "https"],
  check_origin: ["https://your-domain.com"]
```

## Monitoring & Maintenance

### Health Checks

The application provides several health check endpoints:

```bash
# Application health
curl https://your-domain.com/webhooks/health

# Database connectivity
curl https://your-domain.com/health/db

# Background job status
curl https://your-domain.com/health/jobs
```

### Background Jobs

Neptuner uses Oban for background job processing:

```bash
# Monitor job queue
curl https://your-domain.com/oban

# Process stuck jobs
MIX_ENV=prod mix oban.drain

# Scale workers in production
# config/prod.exs
config :neptuner, Oban,
  queues: [
    email_sync: 5,      # Email synchronization
    calendar_sync: 3,    # Calendar synchronization  
    achievements: 2,     # Achievement processing
    notifications: 1     # Email notifications
  ]
```

### Log Management

Application logs include:
- OAuth connection events
- Email/calendar sync status
- Achievement triggers
- Error tracking via Sentry

```bash
# View recent logs (Heroku)
heroku logs --tail

# View logs (Fly.io)
fly logs

# Application-specific logging
tail -f log/prod.log
```

### Performance Monitoring

Key metrics to monitor:
- Database query performance
- Background job processing time
- OAuth API rate limits
- Memory usage and GC pressure
- Response times for LiveView updates

### Database Maintenance

```bash
# Analyze database performance
MIX_ENV=prod mix ecto.analyze

# Vacuum and reindex (PostgreSQL)
psql neptuner_prod -c "VACUUM ANALYZE;"
psql neptuner_prod -c "REINDEX DATABASE neptuner_prod;"

# Clean up old email summaries (older than 90 days)
MIX_ENV=prod mix neptuner.cleanup_old_emails --days 90
```

## Troubleshooting

### Common Issues

#### OAuth Connection Problems

**Issue**: "Invalid redirect URI" error during OAuth flow
**Solution**: 
- Verify redirect URI matches exactly in OAuth provider settings
- Check APP_URL environment variable
- Ensure HTTPS in production

**Issue**: Token refresh failures
**Solution**:
- Check if refresh tokens are being stored properly
- Verify OAuth scopes haven't changed
- Check API rate limits

#### Database Connection Issues

**Issue**: "Connection refused" errors
**Solution**:
- Verify DATABASE_URL format: `postgresql://user:pass@host:port/database`
- Check if database server is running
- Verify network connectivity and firewall settings

**Issue**: Migration failures
**Solution**:
```bash
# Check migration status
mix ecto.migrations

# Rollback problematic migration
mix ecto.rollback --step 1

# Fix migration and re-run
mix ecto.migrate
```

#### Asset Compilation Problems

**Issue**: CSS/JS not loading in production
**Solution**:
- Ensure `mix assets.deploy` was run
- Check if assets are in `priv/static/assets/`
- Verify CDN configuration if using external asset hosting

**Issue**: Tailwind classes not working
**Solution**:
- Check `assets/css/app.css` for proper Tailwind imports
- Verify `tailwind.config.js` includes all template paths
- Run `mix assets.build` to recompile

#### Background Job Issues

**Issue**: Jobs not processing
**Solution**:
- Check Redis connectivity: `redis-cli ping`
- Verify Oban configuration in `config/prod.exs`
- Check for failed jobs in Oban dashboard

**Issue**: Email sync failures
**Solution**:
- Verify OAuth tokens are valid
- Check API rate limits for Gmail/Outlook
- Review connection status in dashboard

### Email Integration Troubleshooting

#### Gmail API Issues

- **Rate limiting**: Gmail API has quotas (default: 250 quota units per user per 100 seconds)
- **Token expiration**: Refresh tokens may expire after 7 days of inactivity
- **Scope changes**: Changing scopes requires re-authorization

#### Microsoft Graph Issues

- **App permissions**: Ensure delegated permissions are granted
- **Tenant configuration**: Some organizations restrict third-party apps
- **Token lifetime**: Access tokens expire after 1 hour

### Performance Troubleshooting

#### Slow Database Queries

```sql
-- Find slow queries
SELECT query, mean_time, calls, total_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_email_summaries_user_received 
ON email_summaries(user_id, received_at DESC);
```

#### Memory Issues

```bash
# Monitor memory usage
mix observer.start

# Check for memory leaks in production
watch -n 5 'ps aux | grep beam'

# Tune Erlang VM memory settings
export ERL_MAX_PORTS=8192
export ERL_PROCESS_LIMIT=1048576
```

### Debugging Tools

#### Development Debugging

```bash
# Interactive debugging in development
iex -S mix phx.server

# Enable detailed logging
config :logger, level: :debug

# Database query debugging
config :neptuner, Neptuner.Repo, log: :debug
```

#### Production Debugging

```bash
# Connect to production console (be careful!)
fly ssh console --pty -C "iex -S mix"

# Remote observer (use sparingly)
fly ssh console --pty -C "iex -S mix -e ':observer.start()'"

# Check system metrics
fly ssh console --pty -C "htop"
```

### Getting Help

- **Documentation**: Check `docs/` directory for additional guides
- **Logs**: Always check application logs first
- **Community**: Phoenix and Elixir forums for general issues
- **Issues**: Report bugs via GitHub issues

Remember: In the cosmic scale of debugging, most issues are temporary disturbances in the digital void. Stay calm, check the logs, and trust in the eventual heat death of the universe to solve all problems.