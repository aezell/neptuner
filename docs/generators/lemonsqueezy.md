# LemonSqueezy Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The LemonSqueezy generator integrates LemonSqueezy payment processing into your Phoenix SaaS template. It provides a complete payment solution including order tracking, subscription management, webhook handling, and comprehensive database schema for storing purchase data.

## Installation

Run the generator from your project root:

```bash
mix neptuner.gen.lemonsqueezy
```

Use the `--yes` flag to skip the completion notice:

```bash
mix neptuner.gen.lemonsqueezy --yes
```

## What It Does

The generator makes comprehensive changes to your application:

### Dependencies Added
- **lemon_ex** (~> 0.2.4) - LemonSqueezy API integration library
- **httpoison** (~> 2.2.3) - HTTP client for API requests

### Configuration Files Updated
- **config/config.exs** - Production LemonSqueezy configuration with environment variables
- **config/dev.exs** - Development configuration with test API keys
- **.env.example** - Added required environment variables

### Database Schema Created
- **Purchase schema** (`lib/neptuner/purchases/purchase.ex`) - Comprehensive schema for LemonSqueezy order data
- **Migration file** (`priv/repo/migrations/*_add_purchases.exs`) - Database migration with proper indexes
- **User relationship** - Links purchases to existing User model

### Core Modules Created
- **Neptuner.Purchases** (`lib/neptuner/purchases.ex`) - Context module for purchase management
- **LemonSqueezyWebhookHandler** (`lib/neptuner_web/controllers/lemon_squeezy_webhooks_controller.ex`) - Webhook event handler

### Application Updates
- **Endpoint** (`lib/neptuner_web/endpoint.ex`) - Webhook plug added at `/webhook/lemonsqueezy`
- **Factory** (`test/support/factory.ex`) - Test factories for purchases and webhook events

### Test Suite
- **Purchase tests** (`test/neptuner/purchases_test.exs`) - Unit tests for purchase context
- **Webhook handler tests** (`test/neptuner_web/lemon_squeezy_webhook_handler_test.exs`) - Integration tests for webhook handling

## Configuration

### Environment Variables Required

```bash
# Production environment
LEMONSQUEEZY_API_KEY=your_live_api_key_here
LEMONSQUEEZY_WEBHOOK_SECRET=your_webhook_secret_here
```

### Development Configuration

The generator automatically sets up development configuration with test keys:

```elixir
# config/dev.exs
config :lemon_ex,
  api_key: "test_api_key",
  webhook_secret: "test_webhook_secret"
```

### Production Configuration

```elixir
# config/config.exs
config :lemon_ex,
  api_key: System.get_env("LEMONSQUEEZY_API_KEY"),
  webhook_secret: System.get_env("LEMONSQUEEZY_WEBHOOK_SECRET"),
  request_options: [timeout: 10_000]
```

## Usage

### After Installation

1. **Run the database migration:**
   ```bash
   mix ecto.migrate
   ```

2. **Set up LemonSqueezy API keys:**
   - Visit https://app.lemonsqueezy.com/settings/api
   - Create a new API key
   - Set environment variables in your deployment

3. **Configure webhook endpoint:**
   - Go to https://app.lemonsqueezy.com/settings/webhooks
   - Add endpoint: `https://yourdomain.com/webhook/lemonsqueezy`
   - Select relevant events (order_created, order_refunded, subscription events)

### Purchase Management

```elixir
# List all purchases
Neptuner.Purchases.list_purchases()

# Get purchase by LemonSqueezy order ID
Neptuner.Purchases.get_purchase_by_lemonsqueezy_order_id(123456)

# Get purchase by order identifier
Neptuner.Purchases.get_purchase_by_order_identifier("uuid-123-456-789")

# Create or update purchase from LemonSqueezy order data
Neptuner.Purchases.create_or_update_purchase_from_order(order_data)
```

### Webhook Events Handled

The webhook handler automatically processes these LemonSqueezy events:

- **order_created** - Creates new purchase records
- **order_refunded** - Updates purchase status and refund amounts
- **subscription_created** - Handles new subscription creation
- **subscription_updated** - Processes subscription changes
- **subscription_payment_success** - Records successful subscription payments
- **subscription_payment_failed** - Handles failed payment attempts
- **subscription_payment_recovered** - Processes recovered failed payments
- **subscription_cancelled** - Handles subscription cancellations
- **subscription_resumed** - Processes subscription resumptions
- **subscription_expired** - Handles expired subscriptions

## Examples

### Purchase Schema Fields

The Purchase schema includes comprehensive fields for LemonSqueezy data:

```elixir
# Financial fields (all amounts in cents)
field :total, :integer
field :subtotal, :integer
field :tax, :integer
field :setup_fee, :integer
field :discount_total, :integer
field :refunded_amount, :integer

# Status and metadata
field :status, :string  # "pending", "paid", "refunded", "partial_refund", "void"
field :refunded, :boolean
field :test_mode, :boolean

# Customer information
field :user_email, :string
field :user_name, :string

# Product information
field :product_name, :string
field :variant_name, :string
```

### Testing Webhook Endpoint

```bash
# Test webhook endpoint locally
curl -X POST http://localhost:4000/webhook/lemonsqueezy \
  -H "Content-Type: application/json" \
  -d '{
    "meta": {"event_name": "order_created"},
    "data": {
      "id": 123456,
      "user_email": "test@example.com",
      "total": 2999,
      "currency": "USD",
      "status": "paid"
    }
  }'
```

### Factory Usage in Tests

```elixir
# Create test purchase
purchase = insert(:purchase)

# Create test purchase with specific status
refunded_purchase = insert(:refunded_purchase)

# Create webhook event for testing
webhook_event = build(:lemonsqueezy_webhook_event)
```

## Next Steps

1. **Customize purchase processing** - Modify the `Neptuner.Purchases` context to fit your business logic
2. **Add user notifications** - Send emails or in-app notifications when purchases are completed
3. **Implement access control** - Use purchase data to grant/revoke user permissions
4. **Set up monitoring** - Add logging and error tracking for payment events
5. **Create admin interface** - Build admin views to manage purchases and subscriptions

### Integration with User System

The Purchase schema includes a `user_id` field that links to your existing User model:

```elixir
# In your user registration flow
user = get_user_by_email(purchase.user_email)
purchase |> Ecto.Changeset.change(user_id: user.id) |> Repo.update()
```

### Security Considerations

- Webhook signature verification is enabled in production
- All webhook events are logged for audit purposes
- Test mode purchases are clearly marked
- Sensitive data is not logged in production

The LemonSqueezy integration provides a solid foundation for payment processing in your SaaS application while maintaining security and comprehensive audit trails.