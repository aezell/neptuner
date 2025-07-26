# Phoenix SaaS Template

A comprehensive Phoenix LiveView template for building Software as a Service applications with modern tooling, authentication, multi-tenancy, and payment processing capabilities.

## Features

This template includes:

- **Phoenix LiveView** - Real-time, interactive UI without JavaScript
- **Tailwind CSS v4** - Modern utility-first CSS framework with custom theme
- **Authentication System** - Email/password and OAuth (GitHub, Google)
- **Multi-tenancy** - Organization-based multi-tenant architecture
- **Payment Processing** - Stripe, LemonSqueezy, and Polar.sh integrations
- **Analytics** - Phoenix Analytics for usage tracking
- **AI/LLM Integration** - LangChain for OpenAI GPT models
- **Feature Flags** - Fun with Flags for feature management
- **Admin Panel** - Secure admin interface with basic auth
- **Blog System** - Complete blog with markdown support and admin interface
- **Changelog** - Built-in changelog with dummy data (update before launch)
- **Legal Pages** - Terms of service and privacy policy templates (update before launch)
- **Waitlist System** - Pre-launch user collection
- **Comprehensive Testing** - Full test coverage with factories
- **Development Tools** - LiveDashboard, code reloading, and more

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/codestirring/phoenix_neptuner.git <DestinationDirectory>
cd <DestinationDirectory>
```

### 2. Install Dependencies

```bash
mix deps.get
```

### 3. Interactive Setup

Run the interactive setup script to choose which features you want:

```bash
mix neptuner.setup
```

This will:
- Set up your database and run migrations
- Rename your project to whatever you choose
- Build and optimize assets
- Present you with a menu of available features to install
- Configure your environment based on your selections

### 4. Start the Server

```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Pay attention to the end result when the setup has completed to see if there are any additional .env values to add to complete the setup of some of the features.

## Documentation

### Setup and Configuration
- [Modular Setup Guide](docs/modular-setup.md) - Complete guide to the CLI setup system
- [Claude Commands](docs/claude.md) - AI-powered development commands

### Available Generators
- [Admin Password](docs/generators/admin-password.md) - Secure admin panel access
- [Analytics](docs/generators/analytics.md) - Phoenix Analytics integration
- [Blog](docs/generators/blog.md) - Complete blog system with admin interface
- [LemonSqueezy](docs/generators/lemonsqueezy.md) - LemonSqueezy payment processing
- [LLM Integration](docs/generators/llm.md) - LangChain and OpenAI GPT models
- [OAuth GitHub](docs/generators/oauth-github.md) - GitHub OAuth authentication
- [OAuth Google](docs/generators/oauth-google.md) - Google OAuth authentication
- [Organisations](docs/generators/organisations.md) - Multi-tenant organization system
- [Polar](docs/generators/polar.md) - Polar.sh payment integration
- [Stripe](docs/generators/stripe.md) - Stripe payment processing
- [Waitlist](docs/generators/waitlist.md) - Pre-launch waitlist functionality

## Manual Feature Installation

You can also install individual features manually:

```bash
# Install specific features
mix neptuner.gen.stripe
mix neptuner.gen.organisations
mix neptuner.gen.oauth_github

# Install with automatic confirmation
mix neptuner.gen.analytics --yes
```

## Environment Configuration

After running setup, configure your environment variables:

```bash
cp .env.example .env
# Edit .env with your actual values
```

Common environment variables include:
- Database configuration
- OAuth provider credentials (GitHub, Google)
- Payment processor API keys (Stripe, LemonSqueezy, Polar)
- OpenAI API key for LLM features
- Admin panel password

## Development

### Running Tests

```bash
mix test
```

### Code Formatting

```bash
mix format
```

### Database Operations

```bash
mix ecto.migrate          # Run migrations
mix ecto.reset            # Reset database
mix ecto.setup            # Create database and run migrations
```

### Asset Management

```bash
mix assets.build          # Build assets for development
mix assets.deploy         # Build and optimize assets for production
```

## Production Deployment

Ready to run in production? We recommend [Fly.io](https://fly.io).

Make sure to:
1. Set all required environment variables
2. Run `mix assets.deploy` to optimize assets
3. Run `mix ecto.migrate` to update the database
4. Configure your web server and SSL certificates

## Learn More About Phoenix & Recommended Packages

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
* Elixir Slack: https://elixir-slack.community/
* Liveview Cookbook: https://www.liveviewcookbook.com/
* Bloom UI Library: https://bloom-ui.fly.dev/
