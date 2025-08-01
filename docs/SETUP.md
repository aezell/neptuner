# Neptuner Setup Guide

Welcome to Neptuner - the ironically productive task management app that helps you understand the cosmic significance (or complete meaninglessness) of your digital productivity theater.

## Quick Start

```bash
# Clone and set up the project
git clone https://github.com/your-org/neptuner.git
cd neptuner

# One-command setup
mix setup

# Start the server
mix phx.server
```

Visit `http://localhost:4000` to begin your journey into cosmic productivity enlightenment.

## Detailed Setup Instructions

### 1. Prerequisites

Before embarking on this digital productivity journey, ensure you have:

- **Elixir 1.15+** with OTP 26+ (the programming language that powers our cosmic insights)
- **Phoenix 1.8+** (the web framework for our existential web interface)
- **PostgreSQL 14+** (to store your tasks in the vast database void)
- **Node.js 18+** (for asset compilation in the JavaScript cosmos)
- **Git** (for version control of your productivity evolution)

#### Installing Prerequisites

**Using asdf (Recommended)**
```bash
# Install asdf version manager
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

# Add asdf to your shell (bash/zsh)
echo '. ~/.asdf/asdf.sh' >> ~/.bashrc  # or ~/.zshrc

# Install plugins
asdf plugin add erlang
asdf plugin add elixir
asdf plugin add nodejs
asdf plugin add postgres

# Install versions
asdf install erlang 26.2.1
asdf install elixir 1.15.7-otp-26
asdf install nodejs 18.19.0
asdf install postgres 14.10

# Set global versions
asdf global erlang 26.2.1
asdf global elixir 1.15.7-otp-26
asdf global nodejs 18.19.0
asdf global postgres 14.10
```

**Alternative: Homebrew (macOS)**
```bash
brew install elixir postgresql@14 node@18
brew services start postgresql@14
```

**Alternative: Package Managers (Linux)**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install elixir postgresql postgresql-contrib nodejs npm

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Project Setup

#### Clone the Repository
```bash
git clone https://github.com/your-org/neptuner.git
cd neptuner
```

#### Install Phoenix
```bash
mix archive.install hex phx_new
```

#### Environment Configuration

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` with your cosmic configuration:

```bash
# Database (adjust username/password as needed)
DATABASE_URL="postgresql://postgres:postgres@localhost/neptuner_dev"

# Application settings
APP_URL="http://localhost:4000"
SECRET_KEY_BASE="generate-with-mix-phx-gen-secret"

# OAuth credentials (see OAuth Setup section below)
GOOGLE_OAUTH_CLIENT_ID="your-google-client-id"
GOOGLE_OAUTH_CLIENT_SECRET="your-google-client-secret"
MICROSOFT_OAUTH_CLIENT_ID="your-microsoft-client-id"
MICROSOFT_OAUTH_CLIENT_SECRET="your-microsoft-client-secret"
```

Generate a secret key:
```bash
mix phx.gen.secret
```

### 3. Database Setup

#### Create Database
```bash
# Create development database
createdb neptuner_dev

# Create test database
createdb neptuner_test
```

If you encounter permission issues:
```bash
# Create postgres user (if needed)
sudo -u postgres createuser -s $(whoami)

# Set password for your user
sudo -u postgres psql -c "ALTER USER $(whoami) PASSWORD 'your_password';"
```

#### Run Migrations
```bash
# Install dependencies first
mix deps.get

# Set up database with migrations and seeds
mix ecto.setup

# Or run steps individually
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

#### Load Neptuner-Specific Data
```bash
# Load achievements, sample tasks, and cosmic wisdom
mix run priv/repo/seeds_neptuner.exs
```

### 4. Asset Setup

Install and compile frontend assets:

```bash
# Install Tailwind and esbuild
mix assets.setup

# Build assets for development
mix assets.build
```

### 5. OAuth Service Configuration

To unlock the full cosmic potential of Neptuner's integrations, you'll need to configure OAuth with various service providers.

#### Google OAuth Setup

1. **Create Google Cloud Project**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Note your Project ID

2. **Enable APIs**
   - Navigate to "APIs & Services" > "Library"
   - Enable the following APIs:
     - Gmail API
     - Google Calendar API
     - Google People API

3. **Create OAuth Credentials**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Choose "Web application"
   - Add authorized redirect URI: `http://localhost:4000/oauth/google/callback`
   - Copy the Client ID and Client Secret to your `.env` file

4. **Configure OAuth Consent Screen**
   - Go to "APIs & Services" > "OAuth consent screen"
   - Fill in app information
   - Add your email to test users
   - Add the following scopes:
     - `email`
     - `profile` 
     - `https://www.googleapis.com/auth/gmail.readonly`
     - `https://www.googleapis.com/auth/calendar.readonly`

#### Microsoft OAuth Setup

1. **Create Azure App Registration**
   - Go to [Azure Portal](https://portal.azure.com/)
   - Navigate to "Azure Active Directory" > "App registrations"
   - Click "New registration"
   - Name: "Neptuner"
   - Redirect URI: `http://localhost:4000/oauth/microsoft/callback`

2. **Configure API Permissions**
   - In your app registration, go to "API permissions"
   - Add permissions for Microsoft Graph:
     - `Mail.Read` (Delegated)
     - `Calendars.Read` (Delegated)
     - `User.Read` (Delegated)
   - Grant admin consent (if required)

3. **Create Client Secret**
   - Go to "Certificates & secrets"
   - Create a new client secret
   - Copy the secret value to your `.env` file
   - Note the Application (client) ID for your `.env` file

#### Apple Sign In Setup (Optional)

1. **Create Apple Developer Account**
   - You need a paid Apple Developer account

2. **Create Service ID**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Navigate to "Certificates, Identifiers & Profiles"
   - Create a new Services ID
   - Configure for Sign In with Apple

3. **Generate Private Key**
   - Create a private key for Sign In with Apple
   - Download the `.p8` file
   - Note the Key ID and Team ID

4. **Update Environment**
   ```bash
   APPLE_OAUTH_CLIENT_ID="your.service.id"
   APPLE_OAUTH_TEAM_ID="YOUR_TEAM_ID"
   APPLE_OAUTH_KEY_ID="YOUR_KEY_ID"
   APPLE_OAUTH_PRIVATE_KEY_PATH="/path/to/AuthKey_KEYID.p8"
   ```

### 6. Development Server

Start your cosmic productivity server:

```bash
# Start the Phoenix server
mix phx.server

# Or start with interactive Elixir shell
iex -S mix phx.server
```

The application will be available at:
- **Main app**: http://localhost:4000
- **LiveDashboard**: http://localhost:4000/dev/dashboard (development only)
- **Mailbox Preview**: http://localhost:4000/dev/mailbox (development only)
- **Oban Dashboard**: http://localhost:4000/oban (development only)

### 7. First-Time Setup

1. **Create an Account**
   - Visit http://localhost:4000
   - Click "Sign up" and create your account
   - Check the mailbox preview for confirmation emails

2. **Set Up Your Cosmic Profile**
   - Choose your cosmic perspective level (Skeptical, Resigned, or Enlightened)
   - Complete the onboarding flow

3. **Connect Your Services**
   - Go to Dashboard > Connections
   - Connect your Google account for Gmail and Calendar sync
   - Connect Microsoft account if desired
   - Add CalDAV connections for other calendar services

4. **Create Your First Task**
   - Navigate to Tasks
   - Create a task and assign it a cosmic priority:
     - "Matters in 10 years" - Genuinely important
     - "Matters in 10 days" - Short-term significance  
     - "Matters to nobody" - Digital busy work

5. **Start a Habit**
   - Go to Habits section
   - Create a habit and categorize it:
     - Basic Human Function (drink water, sleep)
     - Self-Improvement Theater (meditation apps, productivity podcasts)
     - Actually Useful (exercise, learning)

6. **Explore the Dashboard**
   - View your cosmic productivity metrics
   - Read philosophical observations about your digital habits
   - Check achievement progress (with appropriately deflating congratulations)

## Development Workflow

### Useful Commands

```bash
# Start development server with auto-reload
mix phx.server

# Run tests
mix test

# Run tests with file watching
mix test.watch

# Format code
mix format

# Run type checking (if Dialyzer is configured)
mix dialyzer

# Update dependencies
mix deps.update --all

# Database operations
mix ecto.migrate          # Run pending migrations
mix ecto.rollback         # Rollback last migration
mix ecto.reset            # Drop, create, migrate, and seed

# Asset operations
mix assets.build          # Build assets for development
mix assets.deploy         # Build and optimize for production
```

### Development Tools

#### LiveDashboard
Access comprehensive application metrics at http://localhost:4000/dev/dashboard

Features include:
- Real-time process monitoring
- Memory usage visualization
- Database query analysis
- Request/response metrics

#### Interactive Console
```bash
# Start IEx with application loaded
iex -S mix

# In the console, you can:
alias Neptuner.{Accounts, Tasks, Habits, Communications}

# Create test data
user = Accounts.get_user_by_email("your@email.com")
Tasks.create_task(user.id, %{
  title: "Test cosmic significance",
  cosmic_priority: :matters_to_nobody
})
```

#### Background Jobs Monitoring
Visit http://localhost:4000/oban to monitor:
- Email synchronization jobs
- Calendar sync tasks
- Achievement processing
- Notification delivery

### File Structure

```
neptuner/
├── assets/              # Frontend assets
│   ├── css/            # Tailwind CSS files
│   ├── js/             # JavaScript files
│   └── fonts/          # Haskoy font family
├── config/             # Application configuration
├── docs/               # Documentation
├── lib/
│   ├── neptuner/       # Core business logic
│   │   ├── accounts/   # User management
│   │   ├── achievements/ # Achievement system
│   │   ├── calendar/   # Calendar integration
│   │   ├── communications/ # Email analysis
│   │   ├── connections/ # OAuth service connections
│   │   ├── habits/     # Habit tracking
│   │   ├── integrations/ # External API integrations
│   │   └── tasks/      # Task management
│   └── neptuner_web/   # Web interface
│       ├── components/ # Reusable UI components
│       ├── controllers/ # HTTP controllers
│       └── live/       # LiveView modules
├── priv/
│   ├── repo/migrations/ # Database migrations
│   ├── static/         # Static assets
│   └── gettext/        # Internationalization
└── test/               # Test files
```

### Customizing the Cosmic Experience

#### Adding New Achievements
```elixir
# In priv/repo/seeds_achievements.exs
%{
  key: "your_new_achievement",
  title: "Cosmic Achievement Title",
  description: "Ironically congratulatory description of the accomplishment.",
  trigger_condition: "conditions that unlock this achievement",
  cosmic_humor_level: 85,
  deflation_factor: 0.7,
  category: "productivity_theater",
  badge_emoji: "🌌"
}
```

#### Modifying Existential Commentary
Edit the philosophical observations in:
- `lib/neptuner/integrations/advanced_email_analysis.ex`
- `lib/neptuner/habits/habit_entry.ex`
- `lib/neptuner/achievements.ex`

#### Customizing the UI Theme
The application uses a custom Tailwind configuration with DaisyUI themes:
- Edit `assets/css/app.css` for theme customization
- Modify `lib/neptuner_web/components/core_components.ex` for component styling

## Troubleshooting

### Common Setup Issues

#### Database Connection Issues
```bash
# Error: "database does not exist"
createdb neptuner_dev

# Error: "role does not exist"  
sudo -u postgres createuser $(whoami)

# Error: "password authentication failed"
sudo -u postgres psql -c "ALTER USER $(whoami) PASSWORD 'password';"
```

#### Asset Compilation Issues
```bash
# Error: "esbuild not found"
mix assets.setup

# Error: "tailwind command not found"
mix deps.get
mix assets.setup

# Clear asset cache
rm -rf _build/dev/lib/*/priv/static/
mix assets.build
```

#### OAuth Configuration Issues
- Verify redirect URIs match exactly (including trailing slashes)
- Check that APIs are enabled in Google Cloud Console
- Ensure OAuth consent screen is properly configured
- Verify client secrets are correct and not expired

#### Port Already in Use
```bash
# Find process using port 4000
lsof -ti:4000

# Kill the process
kill -9 $(lsof -ti:4000)

# Or use a different port
PORT=4001 mix phx.server
```

### Getting Help

- **Documentation**: Check the `docs/` directory for additional guides
- **Phoenix Guides**: https://hexdocs.pm/phoenix/overview.html
- **Elixir Documentation**: https://elixir-lang.org/docs.html
- **Community**: Join the Phoenix and Elixir communities on Discord/Slack

## What's Next?

Once you have Neptuner running locally:

1. **Explore the Features**: Create tasks, track habits, and connect your email/calendar
2. **Review the Code**: Understand how cosmic productivity insights are generated
3. **Customize**: Add your own achievements, modify the existential commentary
4. **Deploy**: Follow the [Deployment Guide](DEPLOYMENT.md) to share your cosmic productivity insights with the world

Remember: In the grand scheme of the universe, setting up a productivity app is both infinitely important and completely meaningless. Embrace the paradox and enjoy the journey into digital enlightenment.

## Philosophical Closing Thoughts

You have successfully set up Neptuner, a digital productivity system that simultaneously celebrates and mocks our obsession with optimization. 

As you embark on this journey of cosmic task management, remember:
- Every task you create is both urgent and insignificant
- Your habits are simultaneously life-changing and completely arbitrary
- The achievements you unlock are both meaningful milestones and elaborate self-deception

In the end, Neptuner is not just a productivity app—it's a meditation on the beautiful absurdity of trying to organize chaos in a universe that tends toward entropy.

May your tasks be cosmically prioritized and your productivity theater be ever enlightening. 🌌