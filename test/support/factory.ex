defmodule Neptuner.Factory do
  use ExMachina.Ecto, repo: Neptuner.Repo
  alias Neptuner.Purchases.Purchase

  def purchase_factory do
    order_id = Faker.random_between(100_000, 999_999)
    total_cents = Faker.random_between(500, 50_000)

    %Purchase{
      lemonsqueezy_order_id: order_id,
      lemonsqueezy_customer_id: Faker.random_between(10_000, 99_999),
      order_identifier: "uuid-#{Faker.UUID.v4()}",
      order_number: Faker.random_between(1000, 9999),
      user_name: Faker.Person.name(),
      user_email: Faker.Internet.email(),
      currency: Enum.random(["USD", "EUR", "GBP"]),
      currency_rate: 1.0,
      subtotal: total_cents - Faker.random_between(0, div(total_cents, 10)),
      setup_fee: Faker.random_between(0, 500),
      discount_total: Faker.random_between(0, div(total_cents, 5)),
      tax: Faker.random_between(0, div(total_cents, 8)),
      total: total_cents,
      refunded_amount: 0,
      status: "paid",
      refunded: false,
      refunded_at: nil,
      test_mode: true,
      tax_name: Enum.random(["VAT", "GST", "Sales Tax", "Income Tax"]),
      tax_rate: Enum.random([0.0, 0.05, 0.10, 0.15, 0.20]),
      tax_inclusive: Enum.random([true, false]),
      product_name: Faker.Commerce.product_name(),
      variant_name: Enum.random(["Standard", "Premium", "Basic", "Pro"]),
      metadata: %{},
      custom_data: %{"user_id" => to_string(Faker.random_between(1, 1000))},
      receipt_url: "https://lemonsqueezy.com/receipts/#{order_id}",
      customer_portal_url: "https://lemonsqueezy.com/portal/#{order_id}"
    }
  end

  def purchase_order_data_factory do
    order_id = Faker.random_between(100_000, 999_999)
    total_cents = Faker.random_between(500, 50_000)
    subtotal = total_cents - Faker.random_between(0, div(total_cents, 10))
    tax = Faker.random_between(0, div(total_cents, 8))

    %{
      "id" => order_id,
      "customer_id" => Faker.random_between(10_000, 99_999),
      "identifier" => "uuid-#{Faker.UUID.v4()}",
      "order_number" => Faker.random_between(1000, 9999),
      "user_name" => Faker.Person.name(),
      "user_email" => Faker.Internet.email(),
      "currency" => Enum.random(["USD", "EUR", "GBP"]),
      "currency_rate" => 1.0,
      "subtotal" => subtotal,
      "setup_fee" => Faker.random_between(0, 500),
      "discount_total" => Faker.random_between(0, div(total_cents, 5)),
      "tax" => tax,
      "total" => total_cents,
      "refunded_amount" => 0,
      "status" => "paid",
      "refunded" => false,
      "refunded_at" => nil,
      "test_mode" => true,
      "tax_name" => Enum.random(["VAT", "GST", "Sales Tax", "Income Tax"]),
      "tax_rate" => Enum.random([0.0, 0.05, 0.10, 0.15, 0.20]),
      "tax_inclusive" => Enum.random([true, false]),
      "first_order_item" => %{
        "product_name" => Faker.Commerce.product_name(),
        "variant_name" => Enum.random(["Standard", "Premium", "Basic", "Pro"]),
        "custom_data" => %{"user_id" => to_string(Faker.random_between(1, 1000))}
      },
      "urls" => %{
        "receipt" => "https://lemonsqueezy.com/receipts/#{order_id}",
        "customer_portal" => "https://lemonsqueezy.com/portal/#{order_id}"
      }
    }
  end

  def lemonsqueezy_webhook_event_factory do
    %LemonEx.Webhooks.Event{
      name: "order_created",
      data: build(:purchase_order_data),
      meta: %{}
    }
  end

  # Traits for different purchase states
  def pending_purchase_factory do
    build(:purchase, status: "pending", refunded: false, refunded_amount: 0)
  end

  def refunded_purchase_factory do
    purchase = build(:purchase)

    %{
      purchase
      | status: "refunded",
        refunded: true,
        refunded_amount: purchase.total,
        refunded_at: DateTime.utc_now()
    }
  end

  def partial_refund_purchase_factory do
    purchase = build(:purchase)
    partial_amount = div(purchase.total, 2)

    %{
      purchase
      | status: "partial_refund",
        refunded: true,
        refunded_amount: partial_amount,
        refunded_at: DateTime.utc_now()
    }
  end

  def production_purchase_factory do
    build(:purchase, test_mode: false)
  end

  # Webhook event traits
  def refunded_webhook_event_factory do
    order_data =
      build(:purchase_order_data, %{
        "status" => "refunded",
        "refunded" => true,
        "refunded_amount" => build(:purchase_order_data)["total"]
      })

    %LemonEx.Webhooks.Event{
      name: "order_refunded",
      data: order_data,
      meta: %{}
    }
  end

  def subscription_webhook_event_factory do
    %LemonEx.Webhooks.Event{
      name: "subscription_created",
      data: %{
        "id" => Faker.random_between(100, 999),
        "customer_id" => Faker.random_between(10_000, 99_999),
        "status" => "active"
      },
      meta: %{}
    }
  end

  alias Neptuner.Accounts.User
  alias Neptuner.Organisations.{Organisation, OrganisationMember, OrganisationInvitation}

  def user_factory do
    %User{
      email: sequence(:email, &"user#{&1}@example.com"),
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end

  def organisation_factory do
    %Organisation{
      name: sequence(:organisation_name, &"Organisation #{&1}")
    }
  end

  def organisation_member_factory do
    %OrganisationMember{
      role: "member",
      joined_at: DateTime.utc_now() |> DateTime.truncate(:second),
      user: build(:user),
      organisation: build(:organisation)
    }
  end

  def organisation_invitation_factory do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    expires_at = DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)

    %OrganisationInvitation{
      email: sequence(:invitation_email, &"invite#{&1}@example.com"),
      role: "member",
      token: token,
      expires_at: expires_at,
      organisation: build(:organisation),
      invited_by: build(:user)
    }
  end

  def owner_member_factory do
    build(:organisation_member, role: "owner")
  end

  def admin_member_factory do
    build(:organisation_member, role: "admin")
  end

  def expired_invitation_factory do
    expires_at = DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
    build(:organisation_invitation, expires_at: expires_at)
  end

  def accepted_invitation_factory do
    accepted_at = DateTime.utc_now() |> DateTime.truncate(:second)
    build(:organisation_invitation, accepted_at: accepted_at)
  end
end
