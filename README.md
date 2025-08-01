# Neptuner - The Ironically Productive Task Management App

Where productivity meets existential dread. Most of this probably doesn't matter.

Neptuner is a comprehensive task management and productivity application that helps you organize your digital life while maintaining a healthy skepticism about the cosmic significance of it all. Built with Phoenix LiveView and powered by philosophical insights about modern productivity culture.

## Features

### Core Productivity (With Cosmic Perspective)
- **Cosmic Task Prioritization**: Tasks categorized as "Matters in 10 years", "Matters in 10 days", or "Matters to nobody"
- **Existential Habit Tracking**: Track habits with philosophical commentary on the nature of routine
- **Achievement Deflation Engine**: Earn achievements with appropriately backhanded congratulations
- **Productivity Theater Metrics**: Analyze how much of your activity is actual work vs. digital busy work

### Service Integrations
- **Email Intelligence**: Gmail/Outlook integration with email-to-task extraction and "could have been an email" analysis
- **Calendar Enlightenment**: Google Calendar & Microsoft Outlook sync with meeting productivity scoring
- **Apple/CalDAV Support**: Connect various calendar services for comprehensive time analysis
- **Multi-Account Support**: Connect multiple work and personal accounts per service

### Advanced Features  
- **AI-Powered Insights**: LangChain integration for task analysis and productivity observations
- **Premium Analytics**: Advanced metrics for subscribers, including cross-service productivity insights
- **Team Organizations**: Multi-tenant architecture for teams to share cosmic productivity wisdom
- **Background Sync**: Oban-powered background jobs for real-time data synchronization
- **Webhook Infrastructure**: Real-time updates from connected services

### Technical Excellence
- **Phoenix LiveView**: Real-time, interactive UI without JavaScript complexity
- **Modern Authentication**: Phoenix Auth with OAuth (Google, GitHub, Apple)
- **Payment Processing**: LemonSqueezy integration for premium subscriptions  
- **Comprehensive Monitoring**: Error tracking, telemetry, and performance analytics
- **Admin Interface**: Full-featured admin panel with user management and analytics

## Technology Stack

- **Backend**: Elixir 1.15+ with Phoenix Framework 1.8
- **Database**: PostgreSQL with Ecto ORM
- **Frontend**: Phoenix LiveView with Tailwind CSS v4
- **Background Jobs**: Oban for async processing
- **Authentication**: Phoenix Auth with OAuth (Google, GitHub)
- **Payments**: LemonSqueezy integration
- **Monitoring**: Telemetry, Error Tracker, Phoenix Analytics
- **Real-time**: Phoenix PubSub and WebSockets

## Quick Start

### Prerequisites

Ensure you have the following installed:

- **Elixir**: 1.15 or later
- **Erlang/OTP**: 26 or later  
- **Node.js**: 18+ (for asset compilation)
- **PostgreSQL**: 14+ 
- **Git**: For version control

You can check versions with:
```bash
elixir --version
node --version
psql --version
```

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd neptuner
   ```

2. **Install dependencies and setup**
   ```bash
   mix setup
   ```
   This command will:
   - Install Elixir dependencies
   - Create and migrate the database
   - Install and build assets
   - Run database seeds

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your configuration (see [Environment Configuration](#environment-configuration))

4. **Start the development server**
   ```bash
   mix phx.server
   ```
   
   Or with interactive shell:
   ```bash
   iex -S mix phx.server
   ```

5. **Access the application**
   - Main app: http://localhost:4000
   - Live Dashboard: http://localhost:4000/dev/dashboard
   - Mailbox (dev): http://localhost:4000/dev/mailbox
   - Oban Dashboard: http://localhost:4000/oban

## Environment Configuration

### Required Environment Variables

Copy `.env.example` to `.env` and configure the following:

#### Database
```bash
# Automatically configured for development
# DATABASE_URL=ecto://postgres:postgres@localhost/neptuner_dev
```

#### OAuth Configuration

**User Authentication (Login)**
```bash
# Google OAuth for user login
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# GitHub OAuth for user login  
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
```

**Service Integration (Calendar/Email)**
```bash
# Google OAuth for service connections (separate from user auth)
GOOGLE_OAUTH_CLIENT_ID=your_google_service_client_id
GOOGLE_OAUTH_CLIENT_SECRET=your_google_service_client_secret

# Microsoft OAuth for Outlook/Teams integration
MICROSOFT_OAUTH_CLIENT_ID=your_microsoft_client_id
MICROSOFT_OAUTH_CLIENT_SECRET=your_microsoft_client_secret
```

#### Payment & Subscriptions
```bash
# LemonSqueezy for payment processing
LEMONSQUEEZY_API_KEY=your_lemonsqueezy_api_key
LEMONSQUEEZY_WEBHOOK_SECRET=your_webhook_secret
```

#### AI Integration
```bash
# OpenAI for AI-powered features
OPENAI_API_KEY=your_openai_api_key
```

#### Application Settings
```bash
# Base URL for OAuth callbacks
APP_URL=http://localhost:4000

# Admin panel access
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_secure_admin_password
```

### OAuth Setup Guide

#### Google OAuth Setup

1. **Create Google Cloud Project**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project or select existing one
   - Enable Google+ API and Gmail API

2. **Create OAuth Credentials**
   - Go to "Credentials" in the API & Services section
   - Click "Create Credentials" → "OAuth 2.0 Client ID"
   - Application type: "Web application"
   - Add authorized redirect URIs:
     - `http://localhost:4000/auth/google/callback` (user auth)
     - `http://localhost:4000/oauth/google/callback` (service auth)
     - Add your production URLs when deploying

3. **Configure Scopes**
   - User auth: `email`, `profile`
   - Service auth: `https://www.googleapis.com/auth/calendar`, `https://www.googleapis.com/auth/gmail.readonly`

#### GitHub OAuth Setup

1. **Create GitHub OAuth App**
   - Go to GitHub Settings → Developer settings → OAuth Apps
   - Click "New OAuth App"
   - Authorization callback URL: `http://localhost:4000/auth/github/callback`

#### Microsoft OAuth Setup

1. **Register Azure AD App**
   - Go to [Azure Portal](https://portal.azure.com) → Azure Active Directory → App registrations
   - Click "New registration"
   - Add redirect URI: `http://localhost:4000/oauth/microsoft/callback`
   - Configure API permissions for Calendar and Mail access

## Database Setup

### Development Database

The development database is automatically created when running `mix setup`. If you need to reset it:

```bash
mix ecto.reset  # Drops, creates, migrates, and seeds
```

### Manual Database Operations

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Seed data
mix run priv/repo/seeds.exs

# Reset database
mix ecto.reset
```

### Database Schema

Key entities include:
- **Users**: Authentication and user profiles
- **Organizations**: Team/workspace management
- **Tasks**: Task management with priorities and deadlines
- **Habits**: Habit tracking with entries and streaks
- **Service Connections**: OAuth connections to external services
- **Meetings**: Calendar events and meeting data
- **Achievements**: Gamification and progress tracking
- **Webhook Subscriptions**: Real-time sync configurations

## Development Workflow

### Running Tests

```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/neptuner/tasks_test.exs

# Run tests in watch mode
mix test.watch
```

### Code Quality

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted

# Run static analysis (if configured)
mix credo
```

### Asset Development

```bash
# Install asset dependencies
mix assets.setup

# Build assets for development
mix assets.build

# Build assets for production
mix assets.deploy
```

### Background Jobs

Monitor background jobs with Oban:
- Development: http://localhost:4000/oban
- Jobs are processed automatically
- Key workers: SyncWorker, WebhookRenewalWorker, PeriodicSyncScheduler

## Available Mix Tasks

```bash
# Complete project setup
mix setup

# Neptuner-specific setup
mix neptuner.setup

# Database operations
mix ecto.setup
mix ecto.reset
mix ecto.migrate

# Asset operations  
mix assets.setup
mix assets.build
mix assets.deploy

# Development server
mix phx.server
```

## Admin Access

### Admin Panel

Access admin features at:
- Feature Flags: http://localhost:4000/feature-flags
- Content Management: http://localhost:4000/admin
- Error Tracking: http://localhost:4000/admin/errors
- Analytics: http://localhost:4000/admin/analytics

### Admin Authentication

Admin routes are protected with basic authentication:
- Username: Set via `ADMIN_USERNAME` (default: "admin")
- Password: Set via `ADMIN_PASSWORD`

## API Documentation

### Webhook Endpoints

#### Google Calendar Webhooks
```
POST /webhooks/google/calendar
```
Receives Google Calendar push notifications for real-time sync.

**Headers:**
- `x-goog-channel-id`: Channel identifier
- `x-goog-resource-id`: Resource identifier  
- `x-goog-channel-token`: Verification token

#### Gmail Webhooks
```
POST /webhooks/google/gmail
```
Receives Gmail push notifications for email-based task creation.

**Headers:**
- `x-goog-message-number`: Message sequence number
- `x-goog-channel-token`: Verification token

#### Microsoft Graph Webhooks
```
POST /webhooks/microsoft/graph
```
Receives Microsoft Graph notifications for Outlook/Teams integration.

#### Webhook Health Check
```
GET /webhooks/health
```
Returns webhook infrastructure status.

### Sync API

#### Manual Sync
```
POST /sync/connection/:connection_id
POST /sync/all
GET /sync/status
```

#### Test Endpoints
```
POST /sync/test/calendar/:connection_id
POST /sync/test/email/:connection_id
```

### Export API (Premium)
```
POST /export/all
POST /export/dataset
```

## Troubleshooting

### Common Issues

#### OAuth Configuration Problems

**Symptom**: OAuth login fails with "Invalid client" error
**Solution**: 
1. Verify client IDs and secrets in `.env`
2. Check redirect URIs match exactly in OAuth provider settings
3. Ensure OAuth APIs are enabled in provider console

**Symptom**: Service connections fail to authorize
**Solution**:
1. Verify service OAuth credentials are separate from user auth
2. Check API scopes are correctly configured
3. Ensure callback URLs are whitelisted

#### Database Connection Issues

**Symptom**: `connection refused` errors
**Solution**:
1. Ensure PostgreSQL is running: `brew services start postgresql` (macOS)
2. Check database credentials in config
3. Create database manually: `createdb neptuner_dev`

**Symptom**: Migration errors
**Solution**:
1. Reset database: `mix ecto.reset`
2. Check for conflicting migrations
3. Ensure database user has proper permissions

#### Asset Compilation Problems

**Symptom**: CSS/JS assets not loading
**Solution**:
1. Reinstall asset dependencies: `mix assets.setup`
2. Rebuild assets: `mix assets.build`
3. Check Node.js version compatibility

**Symptom**: Tailwind classes not applied
**Solution**:
1. Verify Tailwind configuration in `assets/css/app.css`
2. Check file paths in asset configuration
3. Ensure asset pipeline is running

#### Background Job Issues

**Symptom**: Jobs not processing
**Solution**:
1. Check Oban dashboard at `/oban`
2. Verify database connection for job queue
3. Check worker configurations in `application.ex`

**Symptom**: Webhook renewals failing
**Solution**:
1. Verify OAuth tokens are valid
2. Check webhook endpoint accessibility
3. Review WebhookRenewalWorker logs

#### Performance Issues

**Symptom**: Slow page loads
**Solution**:
1. Check database query performance
2. Monitor memory usage with `:observer.start()`
3. Review N+1 query patterns

**Symptom**: Memory leaks
**Solution**:
1. Monitor GenServer state size
2. Check for unclosed connections
3. Review LiveView assign patterns

### Development Tools

#### Interactive Debugging

```bash
# Start with IEx
iex -S mix phx.server

# In IEx:
:observer.start()  # System monitor
:debugger.start()  # Visual debugger
```

#### Logging

```bash
# Tail logs
tail -f _build/dev/lib/neptuner/consolidated/Elixir.Logger.*

# Enable debug logging
export LOG_LEVEL=debug
```

#### Database Inspection

```bash
# Connect to database
psql neptuner_dev

# In psql:
\dt          # List tables
\d users     # Describe table
SELECT * FROM users LIMIT 5;
```

## Next Steps

After setup, you can:

1. **Configure OAuth providers** for full integration functionality
2. **Set up webhook endpoints** for real-time synchronization  
3. **Configure payment processing** with LemonSqueezy
4. **Customize the application** for your specific needs
5. **Deploy to production** using the deployment guide

## Documentation

- **[Setup Guide](docs/SETUP.md)**: Comprehensive setup instructions with cosmic wisdom
- **[Deployment Guide](docs/DEPLOYMENT.md)**: Production deployment and infrastructure setup
- **[Dashboard Implementation](docs/dashboard-implementation.md)**: Understanding the cosmic dashboard
- **[OAuth Setup](docs/oauth-setup.md)**: Detailed OAuth configuration for all services
- **[Premium Features](docs/premium-features-implementation.md)**: Premium subscription features and analytics

For production deployment, see [DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure they pass
5. Submit a pull request

## License

[License information]

## Support

For support and questions:
- Check the troubleshooting guide above
- Review application logs
- Open an issue in the repository
