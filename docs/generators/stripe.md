# Stripe Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Stripe generator integrates comprehensive Stripe payment processing into your Phoenix SaaS template. It sets up everything needed to handle payments, webhooks, and purchase tracking with minimal configuration required.

## Installation

Run the generator from your project root:

```bash
mix neptuner.gen.stripe
```

After installation, run the database migration:

```bash
mix ecto.migrate
```

## What It Does

The generator performs the following operations:

### Dependencies
- **Adds stripity_stripe (~> 3.2.0)** to `mix.exs` for Stripe API integration

### Configuration Files
- **Updates `config/config.exs`** with production Stripe configuration using environment variables
- **Updates `config/dev.exs`** with development configuration pointing to mock server
- **Updates `.env.example`** with required Stripe environment variables

### Database Schema
- **Creates `purchases` table migration** with comprehensive Stripe data fields
- **Adds indexes** for performance on frequently queried fields
- **Links to User model** for purchase tracking

### Code Files Created

#### Purchase Schema (`lib/neptuner/purchases/purchase.ex`)
```elixir
defmodule Neptuner.Purchases.Purchase do
  use Ecto.Schema
  import Ecto.Changeset

  schema "purchases" do
    field :stripe_payment_intent_id, :string
    field :stripe_charge_id, :string
    field :stripe_customer_id, :string
    field :amount, :integer
    field :currency, :string
    field :status, :string
    field :description, :string
    field :metadata, :map, default: %{}
    field :receipt_url, :string
    field :payment_method_type, :string

    belongs_to :user, Neptuner.Accounts.User
    timestamps()
  end
end
```

#### Purchases Context (`lib/neptuner/purchases.ex`)
Provides functions for:
- Creating and updating purchases
- Finding purchases by payment intent ID
- Converting Stripe payment intent data to purchase records

#### Stripe Webhook Controller (`lib/neptuner_web/controllers/stripe_webhook_controller.ex`)
Handles incoming Stripe webhook events with:
- Signature verification in production
- Mock-friendly development mode
- Event processing for payment lifecycle

### Routing
- **Adds webhook route** `/api/stripe/webhooks` to handle Stripe webhook events
- **Uncomments API scope** in router if it doesn't exist

## Configuration

### Environment Variables

Add these to your production environment:

```bash
STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_endpoint_secret
```

### Development Configuration

The generator automatically configures development mode to use:
- Mock API endpoint: `http://localhost:12111`
- Test API key: `sk_test_thisisaboguskey`
- Mock webhook secret: `whsec_test_bogus_secret`

### Stripe Dashboard Setup

1. **Get API Keys**:
   - Visit https://dashboard.stripe.com/apikeys
   - Copy your secret key and set `STRIPE_SECRET_KEY`

2. **Set up Webhook Endpoint**:
   - Go to https://dashboard.stripe.com/webhooks
   - Add endpoint: `https://yourdomain.com/api/stripe/webhooks`
   - Select events: `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.succeeded`, `charge.refunded`
   - Copy the webhook signing secret and set `STRIPE_WEBHOOK_SECRET`

## Usage

### Basic Purchase Operations

```elixir
# List all purchases
Neptuner.Purchases.list_purchases()

# Get specific purchase
Neptuner.Purchases.get_purchase!(123)

# Find purchase by payment intent
Neptuner.Purchases.get_purchase_by_payment_intent("pi_123")

# Create new purchase
Neptuner.Purchases.create_purchase(%{
  stripe_payment_intent_id: "pi_123",
  amount: 2000,  # $20.00 in cents
  currency: "usd",
  status: "succeeded"
})
```

### Webhook Event Handling

The webhook controller automatically handles these Stripe events:

- **`payment_intent.succeeded`** - Creates or updates purchase record
- **`payment_intent.payment_failed`** - Updates purchase status to failed
- **`charge.succeeded`** - Logs successful charge
- **`charge.refunded`** - Handles refund events

### Development with Mock Server

For development and testing, use the Stripe mock server:

```bash
# Start mock server
docker run --rm -it -p 12111:12111 stripemock/stripe-mock:latest

# Test webhook endpoint
curl -X POST http://localhost:4000/api/stripe/webhooks \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment_intent.succeeded",
    "data": {
      "object": {
        "id": "pi_test_123",
        "amount": 2000,
        "currency": "usd",
        "status": "succeeded"
      }
    }
  }'
```

## Examples

### Processing a Payment Intent

```elixir
# When a payment intent succeeds, the webhook will automatically:
# 1. Parse the Stripe event
# 2. Create or update a purchase record
# 3. Log the transaction

# You can also manually process payment intents:
{:ok, purchase} = Neptuner.Purchases.create_or_update_purchase_from_payment_intent(payment_intent)
```

### Querying Purchase Data

```elixir
# Get all purchases for a user
user = Neptuner.Accounts.get_user!(1)
purchases = Neptuner.Purchases.list_purchases()
|> Enum.filter(&(&1.user_id == user.id))

# Get purchase metadata
purchase = Neptuner.Purchases.get_purchase!(123)
IO.inspect(purchase.metadata)
IO.inspect(purchase.receipt_url)
```

### Custom Webhook Processing

Extend the webhook controller to handle additional events:

```elixir
# Add to StripeWebhookController
defp process_event(%Stripe.Event{type: "customer.subscription.created", data: %{object: subscription}}) do
  # Handle subscription creation
  Logger.info("New subscription created: #{subscription.id}")
  # Add your subscription logic here
  :ok
end
```

## Next Steps

1. **Set up Stripe API keys** in your production environment
2. **Configure webhook endpoint** in Stripe Dashboard
3. **Run the migration** to create the purchases table
4. **Test webhook processing** with the mock server
5. **Customize purchase workflow** for your specific business needs
6. **Add subscription handling** if you need recurring payments
7. **Implement customer management** for better user experience
8. **Set up email notifications** for successful payments
9. **Add refund handling** for customer service workflows
10. **Monitor webhook reliability** and add retry logic if needed

The Stripe integration provides a solid foundation for payment processing that can be extended based on your specific SaaS requirements.