# Polar Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Polar generator integrates Polar.sh payment processing into your SaaS template, providing comprehensive support for orders, checkouts, subscriptions, and webhooks. It creates a complete payment infrastructure with database schema, context modules, webhook handlers, and comprehensive test coverage.

## Installation

Run the generator from your project root:

```bash
mix neptuner.gen.polar
```

The generator uses Igniter to safely modify your codebase and will show you what changes will be made before applying them.

## What It Does

The generator performs the following modifications to your project:

### Dependencies Added
- **polarex (~> 0.2.0)** - Elixir client for Polar.sh API integration

### Configuration Files Modified
- **config/config.exs** - Adds Polar.sh configuration for production environment
- **config/dev.exs** - Adds development configuration with test credentials
- **.env.example** - Adds required environment variables

### Database Schema Created
- **Purchase schema** (`lib/neptuner/purchases/purchase.ex`) - Comprehensive schema for storing Polar.sh transaction data
- **Migration file** (`priv/repo/migrations/*_add_polar_purchases.exs`) - Database migration with proper indexes
- **Purchases context** (`lib/neptuner/purchases.ex`) - Context module for purchase management

### Web Layer Components
- **PolarWebhookController** (`lib/neptuner_web/controllers/polar_webhook_controller.ex`) - Handles incoming Polar.sh webhooks
- **Router updates** (`lib/neptuner_web/router.ex`) - Adds webhook endpoint at `/api/webhooks/polar`

### Test Support
- **Purchase tests** (`test/neptuner/purchases_test.exs`) - Comprehensive test coverage for purchase context
- **Webhook tests** (`test/neptuner_web/polar_webhook_controller_test.exs`) - Test coverage for webhook handling
- **Factory updates** (`test/support/factory.ex`) - Factory definitions for testing Polar.sh data structures

## Configuration

### Environment Variables

The generator adds the following environment variables to your `.env.example`:

```env
POLAR_ACCESS_TOKEN=
POLAR_WEBHOOK_SECRET=
```

### Configuration Details

**Production Configuration (config/config.exs):**
```elixir
config :polarex,
  server: System.get_env("POLAR_SERVER_URL", "https://sandbox-api.polar.sh"),
  access_token: System.get_env("POLAR_ACCESS_TOKEN")

config :neptuner,
  polar_webhook_secret: System.get_env("POLAR_WEBHOOK_SECRET")
```

**Development Configuration (config/dev.exs):**
```elixir
config :polarex,
  server: "https://sandbox-api.polar.sh",
  access_token: "test_access_token"

config :neptuner,
  polar_webhook_secret: "test_webhook_secret"
```

### Database Schema

The Purchase schema includes comprehensive fields for tracking Polar.sh transactions:

- **Polar Identifiers**: `polar_order_id`, `polar_customer_id`, `polar_checkout_id`, `polar_subscription_id`
- **Customer Information**: `user_name`, `user_email`
- **Financial Fields**: `amount`, `tax_amount`, `platform_fee_amount`, `currency` (all amounts in cents)
- **Status Tracking**: `status`, `billing_reason`
- **Product Information**: `product_name`, `product_price_id`
- **Metadata**: `metadata`, `custom_data`, `billing_address`
- **Relationships**: `user_id` (belongs to User model)

## Usage

### Context Module Functions

The `Neptuner.Purchases` context provides the following functions:

```elixir
# List all purchases
Neptuner.Purchases.list_purchases()

# Get purchase by ID
Neptuner.Purchases.get_purchase!(id)

# Get purchase by Polar order ID
Neptuner.Purchases.get_purchase_by_polar_order_id("po_123456")

# Get purchase by Polar checkout ID
Neptuner.Purchases.get_purchase_by_polar_checkout_id("ch_123456")

# Create a new purchase
Neptuner.Purchases.create_purchase(%{
  user_email: "user@example.com",
  amount: 2999,
  currency: "USD",
  status: "succeeded"
})

# Update existing purchase
Neptuner.Purchases.update_purchase(purchase, %{status: "succeeded"})

# Create or update from Polar order data
Neptuner.Purchases.create_or_update_purchase_from_order(order_data)

# Create or update from Polar checkout data
Neptuner.Purchases.create_or_update_purchase_from_checkout(checkout_data)
```

### Webhook Events Handled

The webhook controller handles the following Polar.sh events:

**Order Events:**
- `order.created` - Creates new purchase record
- `order.paid` - Updates purchase status for payment
- `order.updated` - Updates purchase information
- `order.refunded` - Handles order refunds

**Checkout Events:**
- `checkout.created` - Creates purchase from checkout
- `checkout.updated` - Updates checkout information

**Subscription Events:**
- `subscription.created` - Handles subscription creation
- `subscription.updated` - Handles subscription updates
- `subscription.active` - Handles active subscriptions
- `subscription.canceled` - Handles subscription cancellations
- `subscription.uncanceled` - Handles subscription uncancellations
- `subscription.revoked` - Handles subscription revocations

**Customer Events:**
- `customer.created` - Handles customer creation
- `customer.updated` - Handles customer updates
- `customer.deleted` - Handles customer deletions
- `customer.state_changed` - Handles customer state changes

**Benefit Grant Events:**
- `benefit_grant.created` - Handles benefit grant creation
- `benefit_grant.updated` - Handles benefit grant updates
- `benefit_grant.revoked` - Handles benefit grant revocations

**Refund Events:**
- `refund.created` - Handles refund creation
- `refund.updated` - Handles refund updates

## Examples

### Testing Webhook Endpoint

```bash
# Test webhook endpoint locally
curl -X POST http://localhost:4000/api/webhooks/polar \
  -H "Content-Type: application/json" \
  -d '{
    "type": "order.created",
    "data": {
      "id": "po_123456",
      "customer": {
        "id": "cu_123456",
        "email": "customer@example.com",
        "name": "John Doe"
      },
      "amount": 2999,
      "currency": "USD",
      "status": "succeeded",
      "product": {
        "name": "Premium Plan"
      }
    }
  }'
```

### Using Factory in Tests

```elixir
# Create test purchase
purchase = insert(:purchase)

# Create test purchase with specific status
purchase = insert(:purchase, status: "pending")

# Create test data for webhook testing
order_data = build(:polar_order_data)
checkout_data = build(:polar_checkout_data)
subscription_data = build(:polar_subscription_data)

# Use factory traits
pending_purchase = insert(:pending_purchase)
succeeded_purchase = insert(:succeeded_purchase)
subscription_purchase = insert(:subscription_purchase)
```

### Database Queries

```elixir
# Find all purchases for a user
purchases = from(p in Purchase, where: p.user_id == ^user_id) |> Repo.all()

# Find successful purchases
successful_purchases = from(p in Purchase, where: p.status == "succeeded") |> Repo.all()

# Find subscription purchases
subscription_purchases = from(p in Purchase, where: p.billing_reason == "subscription_create") |> Repo.all()

# Find purchases by product
product_purchases = from(p in Purchase, where: p.product_name == ^product_name) |> Repo.all()
```

## Next Steps

### 1. Set up Polar.sh API Keys

1. Visit [https://polar.sh/settings](https://polar.sh/settings)
2. Create a new access token
3. Set `POLAR_ACCESS_TOKEN` and `POLAR_WEBHOOK_SECRET` in your environment

### 2. Run Database Migration

```bash
mix ecto.migrate
```

### 3. Configure Webhook Endpoint

1. Go to [https://polar.sh/settings/webhooks](https://polar.sh/settings/webhooks)
2. Add endpoint: `https://yourdomain.com/api/webhooks/polar`
3. Select the events you want to receive (orders, checkouts, subscriptions, etc.)

### 4. Development Setup

For development and testing:
- Use the test access token provided in `dev.exs`
- The webhook endpoint works with both sandbox and live Polar.sh
- Use the factory definitions in tests to create realistic test data

### 5. Production Considerations

- Ensure proper webhook signature verification in production
- Monitor webhook endpoint performance and error rates
- Set up proper logging and monitoring for payment events
- Consider implementing idempotency for webhook processing
- Set up proper error handling and retry logic for failed webhook processing

### 6. Security Notes

- The generator includes webhook signature verification framework
- In production, implement proper Standard Webhooks signature verification
- Ensure webhook secret is properly configured and secure
- Consider rate limiting for webhook endpoints
- Log security events for monitoring and debugging

The Polar.sh integration provides a robust foundation for handling payments, subscriptions, and customer management in your SaaS application.