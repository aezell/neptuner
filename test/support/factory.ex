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

  # Achievement factories
  alias Neptuner.Achievements.{Achievement, UserAchievement}

  def achievement_factory do
    %Achievement{
      key: sequence(:achievement_key, &"achievement_#{&1}"),
      title: sequence(:achievement_title, &"Achievement #{&1}"),
      description: Faker.Lorem.sentence(5..10),
      ironic_description: Faker.Lorem.sentence(5..10),
      category: Enum.random(["tasks", "habits", "meetings", "emails", "connections", "productivity_theater"]),
      icon: "hero-trophy",
      color: Enum.random(["red", "yellow", "green", "blue", "purple"]),
      threshold_value: Faker.random_between(1, 100),
      threshold_type: Enum.random(["count", "streak", "percentage", "hours", "ratio"]),
      is_active: true
    }
  end

  def user_achievement_factory do
    %UserAchievement{
      progress_value: Faker.random_between(0, 50),
      completed_at: nil,
      notified_at: nil,
      user: build(:user),
      achievement: build(:achievement)
    }
  end

  # Achievement category variants
  def task_achievement_factory do
    build(:achievement, 
      category: "tasks",
      key: "task_achievement",
      title: "Task Master",
      description: "Complete tasks like a digital rectangle mover"
    )
  end

  def habit_achievement_factory do
    build(:achievement,
      category: "habits", 
      key: "habit_achievement",
      title: "Habit Tracker",
      description: "Track habits consistently"
    )
  end

  def meeting_achievement_factory do
    build(:achievement,
      category: "meetings",
      key: "meeting_achievement", 
      title: "Meeting Survivor",
      description: "Survive another meeting that could have been an email"
    )
  end

  def email_achievement_factory do
    build(:achievement,
      category: "emails",
      key: "email_achievement",
      title: "Email Warrior", 
      description: "Process emails efficiently"
    )
  end

  def connection_achievement_factory do
    build(:achievement,
      category: "connections",
      key: "connection_achievement",
      title: "Digital Integrator",
      description: "Connect all the digital services"
    )
  end

  def productivity_theater_achievement_factory do
    build(:achievement,
      category: "productivity_theater",
      key: "theater_achievement",
      title: "Productivity Theater Star",
      description: "Master the art of looking productive"
    )
  end

  # UserAchievement variants
  def completed_user_achievement_factory do
    achievement = build(:achievement, threshold_value: 10)
    
    %UserAchievement{
      progress_value: 15,
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      notified_at: nil,
      user: build(:user),
      achievement: achievement
    }
  end

  def notified_user_achievement_factory do
    completed_at = DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
    notified_at = DateTime.utc_now() |> DateTime.truncate(:second)
    
    build(:completed_user_achievement,
      completed_at: completed_at,
      notified_at: notified_at
    )
  end

  def in_progress_user_achievement_factory do
    achievement = build(:achievement, threshold_value: 20)
    
    build(:user_achievement,
      progress_value: 10,
      achievement: achievement
    )
  end

  # Calendar factories
  alias Neptuner.Calendar.Meeting
  alias Neptuner.Connections.ServiceConnection

  def service_connection_factory do
    %ServiceConnection{
      provider: :google,
      service_type: :calendar,
      external_account_id: sequence(:external_account_id, &"ext_acc_#{&1}"),
      external_account_email: sequence(:external_email, &"external#{&1}@google.com"),
      display_name: sequence(:display_name, &"Google Calendar #{&1}"),
      connection_status: :active,
      sync_enabled: true,
      scopes_granted: ["calendar.readonly", "calendar.events"],
      last_sync_at: DateTime.utc_now() |> DateTime.truncate(:second),
      user: build(:user)
    }
  end

  def meeting_factory do
    scheduled_time = DateTime.utc_now() 
                    |> DateTime.add(Faker.random_between(-30, 30), :day)
                    |> DateTime.truncate(:second)

    %Meeting{
      external_calendar_id: sequence(:external_calendar_id, &"ext_cal_#{&1}"),
      title: sequence(:meeting_title, &"Meeting #{&1}"),
      duration_minutes: Faker.random_between(15, 120),
      attendee_count: Faker.random_between(2, 10),
      could_have_been_email: Enum.random([true, false]),
      actual_productivity_score: nil,
      meeting_type: Enum.random([:standup, :all_hands, :one_on_one, :brainstorm, :status_update, :other]),
      scheduled_at: scheduled_time,
      synced_at: DateTime.utc_now() |> DateTime.truncate(:second),
      user: build(:user),
      service_connection: build(:service_connection)
    }
  end

  # Meeting type variants
  def standup_meeting_factory do
    build(:meeting,
      meeting_type: :standup,
      title: "Daily Standup - Engineering Team",
      duration_minutes: 30,
      attendee_count: 5
    )
  end

  def all_hands_meeting_factory do
    build(:meeting,
      meeting_type: :all_hands,
      title: "All Hands - Company Update",
      duration_minutes: 60,
      attendee_count: 25,
      could_have_been_email: true
    )
  end

  def one_on_one_meeting_factory do
    build(:meeting,
      meeting_type: :one_on_one,
      title: "1:1 with Manager",
      duration_minutes: 30,
      attendee_count: 2
    )
  end

  def brainstorm_meeting_factory do
    build(:meeting,
      meeting_type: :brainstorm,
      title: "Product Brainstorming Session",
      duration_minutes: 90,
      attendee_count: 6
    )
  end

  def status_update_meeting_factory do
    build(:meeting,
      meeting_type: :status_update,
      title: "Weekly Status Update",
      duration_minutes: 45,
      attendee_count: 8,
      could_have_been_email: true
    )
  end

  # Meeting state variants
  def rated_meeting_factory do
    build(:meeting,
      actual_productivity_score: Faker.random_between(1, 10)
    )
  end

  def unrated_meeting_factory do
    build(:meeting,
      actual_productivity_score: nil,
      scheduled_at: DateTime.utc_now() |> DateTime.add(-2, :day) |> DateTime.truncate(:second)
    )
  end

  def could_have_been_email_meeting_factory do
    build(:meeting,
      could_have_been_email: true,
      meeting_type: :status_update
    )
  end

  def productive_meeting_factory do
    build(:meeting,
      could_have_been_email: false,
      actual_productivity_score: Faker.random_between(7, 10),
      meeting_type: :brainstorm
    )
  end

  # Time-based variants
  def past_meeting_factory do
    past_time = DateTime.utc_now() 
               |> DateTime.add(-Faker.random_between(1, 30), :day)
               |> DateTime.truncate(:second)
    
    build(:meeting, scheduled_at: past_time)
  end

  def future_meeting_factory do
    future_time = DateTime.utc_now() 
                 |> DateTime.add(Faker.random_between(1, 30), :day)
                 |> DateTime.truncate(:second)
    
    build(:meeting, scheduled_at: future_time)
  end

  def this_week_meeting_factory do
    this_week = DateTime.utc_now() 
               |> DateTime.add(-Faker.random_between(0, 6), :day)
               |> DateTime.truncate(:second)
    
    build(:meeting, scheduled_at: this_week)
  end

  # Service connection variants
  def google_service_connection_factory do
    build(:service_connection,
      provider: :google,
      service_type: :calendar,
      scopes_granted: ["calendar.readonly", "calendar.events"]
    )
  end

  def microsoft_service_connection_factory do
    build(:service_connection,
      provider: :microsoft,
      service_type: :calendar,
      external_account_email: sequence(:microsoft_email, &"user#{&1}@outlook.com"),
      scopes_granted: ["calendars.read", "calendars.readwrite"]
    )
  end

  def expired_service_connection_factory do
    build(:service_connection,
      connection_status: :expired,
      token_expires_at: DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
    )
  end

  def disabled_sync_connection_factory do
    build(:service_connection,
      sync_enabled: false
    )
  end

  # External meeting data factories (for sync testing)
  def external_google_meeting_data_factory do
    %{
      external_id: "google_event_#{:rand.uniform(10000)}",
      title: sequence(:google_title, fn i -> "Google Meeting #{i}" end),
      duration_minutes: Faker.random_between(30, 120),
      attendees: Enum.map(1..Faker.random_between(2, 8), fn i -> "attendee#{i}@company.com" end),
      start_time: DateTime.utc_now() |> DateTime.add(Faker.random_between(-7, 7), :day) |> DateTime.truncate(:second)
    }
  end

  def external_microsoft_meeting_data_factory do
    %{
      external_id: "outlook_event_#{:rand.uniform(10000)}",
      title: sequence(:microsoft_title, fn i -> "Outlook Meeting #{i}" end),
      duration_minutes: Faker.random_between(30, 120),
      attendees: Enum.map(1..Faker.random_between(2, 8), fn i -> "participant#{i}@company.com" end),
      start_time: DateTime.utc_now() |> DateTime.add(Faker.random_between(-7, 7), :day) |> DateTime.truncate(:second)
    }
  end
end
