# Modular Setup

> **⚠️ Important Note:** This modular setup system only works with fresh installations of the project or when features are manually installed using the Igniter functions. Installation of features can only be guaranteed on fresh usage of the project. If you've already modified the template, some generators may not work as expected.

The Phoenix SaaS Template includes a modular setup system that allows you to customize which features you want to add to your application. This system is built using [Igniter](https://github.com/ash-project/igniter) and provides a command-line interface for adding functionality incrementally.

## Getting Started

### Initial Setup

After cloning the template, run the main setup command:

```bash
mix neptuner.setup
```

This command will:
- Install dependencies with `mix deps.get`
- Set up the database with `mix ecto.setup`
- Build assets with `mix assets.setup`
- Present you with a menu of available features to install

### Manual Feature Installation

You can also install individual features manually using the generator commands:

```bash
# Install a specific feature
mix neptuner.gen.stripe

# Install with automatic confirmation (skip prompts)
mix neptuner.gen.stripe --yes
```

## Available Features

The template includes the following modular features:

### Authentication & Security
- **Admin Password** - Secure admin panel access with environment-based password configuration
- **OAuth GitHub** - GitHub OAuth authentication integration
- **OAuth Google** - Google OAuth authentication integration

### Multi-tenancy
- **Organisations** - Complete multi-tenant organization system with roles and invitations
- **Organisations Test** - Comprehensive test suite for the organizations functionality

### Payment Processing
- **Stripe** - Stripe payment integration with webhook handling
- **LemonSqueezy** - LemonSqueezy payment processing integration
- **Polar** - Polar.sh payment integration

### Analytics & Monitoring
- **Analytics** - Phoenix Analytics integration for tracking and metrics

### AI & Machine Learning
- **LLM** - Large Language Model integration using LangChain

### Marketing & Growth
- **Waitlist** - Waitlist functionality with feature flags

### Content Management
- **Blog** - Complete blog system with admin interface, markdown support, and SEO optimization

## Feature Dependencies

Some features work better together or have dependencies:

- **Organisations** should be installed before payment features if you want organization-scoped billing
- **OAuth** features can be combined (both GitHub and Google)
- **Analytics** works independently but provides better insights when combined with other features

## Command Reference

### Main Commands

```bash
# Interactive setup with feature selection
mix neptuner.setup

# Run only the basic setup (deps, database, assets)
mix neptuner.setup --basic
```

### Generator Commands

```bash
# Admin & Security
mix neptuner.gen.admin_password
mix neptuner.gen.oauth_github
mix neptuner.gen.oauth_google

# Organizations & Multi-tenancy
mix neptuner.gen.organisations
mix neptuner.gen.organisations_test

# Payment Processing
mix neptuner.gen.stripe
mix neptuner.gen.lemonsqueezy
mix neptuner.gen.polar

# Analytics & Monitoring
mix neptuner.gen.analytics

# AI & ML
mix neptuner.gen.llm

# Marketing & Growth
mix neptuner.gen.waitlist

# Content Management
mix neptuner.gen.blog
```

## Best Practices

### Installation Order

1. **Core Features First**: Install authentication and organizations early
2. **Payment Integration**: Add payment processing after core features
3. **Content Management**: Install blog system for marketing and content strategy
4. **Analytics**: Install analytics to track usage from the start
5. **AI Features**: Add LLM capabilities as needed for your use case

### Environment Setup

After installing features, make sure to:

1. **Update Environment Variables**: Check `.env.example` for new required variables
2. **Run Migrations**: Execute `mix ecto.migrate` after database changes
3. **Test Installation**: Run `mix test` to ensure everything works correctly
4. **Review Documentation**: Check the generated documentation for feature-specific setup

### Development Workflow

```bash
# 1. Fresh installation
git clone your-template
cd your-template

# 2. Run interactive setup
mix neptuner.setup

# 3. Select features you need
# Follow the prompts to choose features

# 4. Complete environment setup
cp .env.example .env
# Edit .env with your actual values

# 5. Run migrations and tests
mix ecto.migrate
mix test

# 6. Start development
mix phx.server
```

## Troubleshooting

### Common Issues

- **Generator Conflicts**: If you've modified template files, generators may not work correctly
- **Missing Dependencies**: Some features require external services (Stripe, OAuth providers)
- **Database Issues**: Run `mix ecto.reset` if you encounter migration problems

### Getting Help

- Check the individual feature documentation in `/docs/`
- Review the generated code for implementation details
- Use `mix help neptuner.gen.FEATURE` for specific command help

## Advanced Usage

### Custom Feature Development

You can create your own generators by following the existing patterns in `lib/neptuner/generators/`. Each generator should:

1. Use `Igniter.Mix.Task` as the base
2. Implement the `igniter/1` function
3. Follow the template's conventions
4. Include comprehensive tests

### Selective Feature Installation

For production deployments, you might want to install only specific features:

```bash
# Minimal setup for API-only applications
mix neptuner.gen.stripe
mix neptuner.gen.analytics

# Full-featured SaaS setup
mix neptuner.gen.organisations
mix neptuner.gen.stripe
mix neptuner.gen.oauth_github
mix neptuner.gen.blog
mix neptuner.gen.analytics
```

The modular setup system makes it easy to tailor the template to your specific needs while maintaining code quality and following Phoenix best practices.