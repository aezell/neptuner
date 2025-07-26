# Neptuner Setup Information

This file contains important setup information generated during the SaaS Template setup process.

## Setup Summary

- **Project Name**: Neptuner
- **Waitlist Mode**: Yes
- **Analytics**: Yes
- **Error Tracking**: Yes
- **Google OAuth**: Yes
- **GitHub OAuth**: Yes
- **LLM Integration**: Yes
- **Oban Background Jobs**: Yes
- **Multi-tenancy**: Yes
- **Blog System**: Yes
- **Payment Processor**: lemonsqueezy
- **Admin Password**: Custom

## What was set up

- Dependencies installed
- Database created and migrated
- Waitlist functionality enabled
- Waitlist mode activated
- Analytics tracking enabled
- Analytics dashboard configured
- Error tracking enabled
- Error dashboard configured
- Project renamed to Neptuner
- Admin password configured
- Assets compiled
- Git repository initialized for your project
- Template remote removed

## Waitlist Features

- Use `FunWithFlags.disable(:waitlist_mode)` to disable waitlist mode
- Available components: `<.simple_waitlist_form />`, `<.detailed_waitlist_form />`, `<.hero_waitlist_cta />`

## Analytics Features

- Visit http://localhost:4000/dev/analytics to view analytics dashboard
- Page views, sessions, and metrics are tracked automatically
- Configure PHX_HOST environment variable for production

## Error Tracking Features

- Visit http://localhost:4000/dev/errors to view error dashboard
- Visit http://localhost:4000/admin/errors (requires admin auth)
- Automatic error capture for Phoenix, LiveView, and Oban
- Error grouping, stack traces, and context information
- Manual error reporting with `ErrorTracker.report/2`

## OAuth Authentication

- Google OAuth integration enabled
- Create OAuth app at https://console.developers.google.com/
- Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env
- GitHub OAuth integration enabled
- Create OAuth app at https://github.com/settings/developers
- Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET in .env

- Users can now sign in with social accounts on the login page
- OAuth callback URLs: /auth/google/callback, /auth/github/callback

## LLM Integration

- LangChain integration with OpenAI support
- AI.LLM module for text and JSON responses
- Get API key at https://platform.openai.com/api-keys
- Set OPENAI_API_KEY in your environment variables
- Example usage: `SaasTemplate.AI.example_query()`

## Oban Background Jobs

- Oban job processing with PostgreSQL backend
- Oban Web UI for job monitoring and management
- Visit /oban to view the web interface
- Create jobs with: `%{} |> MyApp.Worker.new() |> Oban.insert()`
- Automatic job retries and dead letter queue

## Multi-Tenancy (Organisations)

- Organisation management with role-based access control
- Three-tier authentication system (basic → org assignment → org requirement)
- Email-based invitation system with token validation
- Role hierarchy: owner, admin, member with different permissions
- Visit /organisations/new to create your first organisation
- Invite users via /organisations/manage
- Comprehensive test suite included

## Blog System

- Complete blog system with admin interface
- Markdown content support with Earmark
- SEO optimization with meta tags and structured data
- Backpex-powered admin interface for blog management
- Visit /blog to view the public blog
- Visit /admin/posts to manage blog posts
- Auto-generated slugs, excerpts, and reading time
- Publishing workflow with draft/published states

## LemonSqueezy Payment Processing

- LemonSqueezy payment integration with webhooks
- Purchase and subscription tracking
- Get API keys at https://app.lemonsqueezy.com/settings/api
- Set LEMONSQUEEZY_API_KEY and LEMONSQUEEZY_WEBHOOK_SECRET in .env
- Webhook endpoint: /webhook/lemonsqueezy
- Example: `SaasTemplate.Purchases.list_purchases()`


## Admin Panel Access

- **Admin password**: REDACTED
- **Username**: `admin`
- **Feature flags UI**: http://localhost:4000/feature-flags
- Password stored in .env file for security

## Development Commands

- `mix phx.server` - Start development server
- `iex -S mix phx.server` - Start with interactive shell
- Visit http://localhost:4000 to see your application

---
*Generated on 2025-07-29 01:52:57.189424Z*
