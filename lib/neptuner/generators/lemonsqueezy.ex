defmodule Mix.Tasks.Neptuner.Gen.Lemonsqueezy do
  @moduledoc """
  Installs LemonSqueezy payment integration for the SaaS template using Igniter.

  This task:
  - Adds lemon_ex dependency to mix.exs
  - Adds LemonSqueezy configuration to config.exs and dev.exs
  - Creates Purchase schema and context module for LemonSqueezy orders
  - Creates LemonSqueezy webhook handler
  - Adds webhook plug to endpoint
  - Generates database migration for purchases
  - Updates .env.example with LemonSqueezy environment variables

      $ mix neptuner.gen.lemonsqueezy

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      |> add_lemonsqueezy_dependency()
      |> add_lemonsqueezy_config()
      |> add_lemonsqueezy_dev_config()
      |> create_purchase_schema()
      |> create_purchases_context()
      |> create_lemonsqueezy_webhook_handler()
      |> update_endpoint()
      |> create_migration()
      |> create_purchases_test()
      |> create_webhook_handler_test()
      |> update_factory()
      |> update_env_example()

    if opts[:yes] do
      igniter
    else
      print_completion_notice(igniter)
    end
  end

  defp add_lemonsqueezy_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:lemon_ex,") do
        # Dependency already exists
        source
      else
        # Add lemon_ex and httpoison dependencies after timex
        updated_content =
          String.replace(
            content,
            ~r/(\{:timex, \"~> 3\.7\.13\"\})/,
            "\\1,\n      # LemonSqueezy\n      {:lemon_ex, \"~> 0.2.4\"},\n      {:httpoison, \"~> 2.2.3\"}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_lemonsqueezy_config(igniter) do
    config_content = """
    config :lemon_ex,
      api_key: System.get_env("LEMONSQUEEZY_API_KEY"),
      webhook_secret: System.get_env("LEMONSQUEEZY_WEBHOOK_SECRET"),
      # (Optional) You can provide HTTPoison options which are added to every request.
      # See all options here: https://hexdocs.pm/httpoison/HTTPoison.Request.html#content
      request_options: [timeout: 10_000]
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :lemon_ex") do
        # Config already exists
        source
      else
        # Add LemonSqueezy config before the import_config line
        updated_content =
          String.replace(
            content,
            ~r/(# Import environment specific config\. This must remain at the bottom)/,
            "\n#{config_content}\n\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_lemonsqueezy_dev_config(igniter) do
    dev_config_content = """
    # LemonSqueezy development configuration
    config :lemon_ex,
      api_key: "test_api_key",
      webhook_secret: "test_webhook_secret"
    """

    Igniter.update_file(igniter, "config/dev.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :lemon_ex") do
        # Config already exists
        source
      else
        # Add LemonSqueezy dev config before the swoosh config
        updated_content =
          String.replace(
            content,
            ~r/(# Disable swoosh api client)/,
            "\n#{dev_config_content}\n\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_purchase_schema(igniter) do
    purchase_content = """
    defmodule Neptuner.Purchases.Purchase do
      use Neptuner.Schema

      schema "purchases" do
        # LemonSqueezy Order fields
        field :lemonsqueezy_order_id, :integer
        field :lemonsqueezy_customer_id, :integer
        field :order_identifier, :string
        field :order_number, :integer
        field :user_name, :string
        field :user_email, :string
        
        # Financial fields (all amounts in cents)
        field :currency, :string
        field :currency_rate, :float
        field :subtotal, :integer
        field :setup_fee, :integer
        field :discount_total, :integer
        field :tax, :integer
        field :total, :integer
        field :refunded_amount, :integer
        
        # Status and metadata
        field :status, :string
        field :refunded, :boolean, default: false
        field :refunded_at, :utc_datetime
        field :test_mode, :boolean, default: false
        
        # Tax information
        field :tax_name, :string
        field :tax_rate, :float
        field :tax_inclusive, :boolean
        
        # Product information
        field :product_name, :string
        field :variant_name, :string
        
        # Additional metadata
        field :metadata, :map, default: %{}
        field :custom_data, :map, default: %{}
        
        # URLs from LemonSqueezy
        field :receipt_url, :string
        field :customer_portal_url, :string

        belongs_to :user, Neptuner.Accounts.User

        timestamps()
      end

      @required_fields ~w(lemonsqueezy_order_id total currency status user_email)a
      @optional_fields ~w(
        lemonsqueezy_customer_id order_identifier order_number user_name
        currency_rate subtotal setup_fee discount_total tax refunded_amount
        refunded refunded_at test_mode tax_name tax_rate tax_inclusive
        product_name variant_name metadata custom_data receipt_url 
        customer_portal_url user_id
      )a

      def changeset(purchase, attrs) do
        purchase
        |> cast(attrs, @required_fields ++ @optional_fields)
        |> validate_required(@required_fields)
        |> validate_number(:total, greater_than: 0)
        |> validate_length(:currency, is: 3)
        |> validate_inclusion(:status, ["pending", "paid", "refunded", "partial_refund", "void"])
        |> validate_format(:user_email, ~r/^[^\\s]+@[^\\s]+\\.[^\\s]+$/)
        |> unique_constraint(:lemonsqueezy_order_id)
        |> unique_constraint(:order_identifier)
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/purchases/purchase.ex",
      purchase_content
    )
  end

  defp create_purchases_context(igniter) do
    purchases_content = """
    defmodule Neptuner.Purchases do
      import Ecto.Query, warn: false
      alias Neptuner.Repo
      alias Neptuner.Purchases.Purchase
      require Logger

      def list_purchases do
        Repo.all(Purchase)
      end

      def get_purchase!(id), do: Repo.get!(Purchase, id)

      def get_purchase_by_lemonsqueezy_order_id(order_id) do
        Repo.get_by(Purchase, lemonsqueezy_order_id: order_id)
      end

      def get_purchase_by_order_identifier(identifier) do
        Repo.get_by(Purchase, order_identifier: identifier)
      end

      def create_purchase(attrs \\\\ %{}) do
        %Purchase{}
        |> Purchase.changeset(attrs)
        |> Repo.insert()
      end

      def update_purchase(%Purchase{} = purchase, attrs) do
        purchase
        |> Purchase.changeset(attrs)
        |> Repo.update()
      end

      def create_or_update_purchase_from_order(order_data) do
        attrs = build_purchase_attrs_from_order(order_data)
        
        case get_purchase_by_lemonsqueezy_order_id(attrs.lemonsqueezy_order_id) do
          nil -> 
            Logger.info("Creating new purchase for LemonSqueezy order \#{attrs.lemonsqueezy_order_id}")
            create_purchase(attrs)
          purchase -> 
            Logger.info("Updating existing purchase for LemonSqueezy order \#{attrs.lemonsqueezy_order_id}")
            update_purchase(purchase, attrs)
        end
      end

      def update_subscription(%LemonEx.Webhooks.Event{data: data, meta: meta}) do
        case data do
          # Handle order events
          %{"order_id" => order_id} when not is_nil(order_id) ->
            handle_order_event(data, meta)
          
          # Handle subscription events that might create orders
          %{"first_subscription_item" => item} when not is_nil(item) ->
            handle_subscription_event(data, meta)
          
          _ ->
            Logger.info("Unhandled subscription event data: \#{inspect(data)}")
            :ok
        end
      end

      def cancel_subscription(%LemonEx.Webhooks.Event{data: data}) do
        Logger.info("Subscription cancelled/expired: \#{inspect(data)}")
        # Handle subscription cancellation logic here
        # This might involve updating user access, sending emails, etc.
        :ok
      end

      # Private functions

      defp handle_order_event(data, _meta) do
        # For subscription events that reference an order, we might want to 
        # fetch the order details from LemonSqueezy API or use the data provided
        create_or_update_purchase_from_order(data)
      end

      defp handle_subscription_event(data, _meta) do
        # Handle subscription-specific events
        # This might involve creating a purchase record for the initial payment
        Logger.info("Handling subscription event: \#{inspect(data)}")
        :ok
      end

      defp build_purchase_attrs_from_order(order_data) do
        %{
          lemonsqueezy_order_id: order_data["id"],
          lemonsqueezy_customer_id: order_data["customer_id"],
          order_identifier: order_data["identifier"],
          order_number: order_data["order_number"],
          user_name: order_data["user_name"],
          user_email: order_data["user_email"],
          currency: order_data["currency"],
          currency_rate: order_data["currency_rate"],
          subtotal: order_data["subtotal"],
          setup_fee: order_data["setup_fee"] || 0,
          discount_total: order_data["discount_total"] || 0,
          tax: order_data["tax"] || 0,
          total: order_data["total"],
          refunded_amount: order_data["refunded_amount"] || 0,
          status: order_data["status"],
          refunded: order_data["refunded"] || false,
          refunded_at: parse_datetime(order_data["refunded_at"]),
          test_mode: order_data["test_mode"] || false,
          tax_name: order_data["tax_name"],
          tax_rate: order_data["tax_rate"],
          tax_inclusive: order_data["tax_inclusive"] || false,
          product_name: get_product_name(order_data),
          variant_name: get_variant_name(order_data),
          metadata: order_data["metadata"] || %{},
          custom_data: extract_custom_data(order_data),
          receipt_url: get_receipt_url(order_data),
          customer_portal_url: get_customer_portal_url(order_data)
        }
      end

      defp parse_datetime(nil), do: nil
      defp parse_datetime(datetime_string) when is_binary(datetime_string) do
        case DateTime.from_iso8601(datetime_string) do
          {:ok, datetime, _} -> datetime
          {:error, _} -> nil
        end
      end

      defp get_product_name(%{"first_order_item" => %{"product_name" => name}}), do: name
      defp get_product_name(_), do: nil

      defp get_variant_name(%{"first_order_item" => %{"variant_name" => name}}), do: name
      defp get_variant_name(_), do: nil

      defp extract_custom_data(%{"first_order_item" => %{"custom_data" => data}}) when is_map(data), do: data
      defp extract_custom_data(_), do: %{}

      defp get_receipt_url(%{"urls" => %{"receipt" => url}}), do: url
      defp get_receipt_url(_), do: nil

      defp get_customer_portal_url(%{"urls" => %{"customer_portal" => url}}), do: url
      defp get_customer_portal_url(_), do: nil
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/purchases.ex",
      purchases_content
    )
  end

  defp create_lemonsqueezy_webhook_handler(igniter) do
    handler_content = """
    defmodule NeptunerWeb.LemonSqueezyWebhookHandler do
      alias Neptuner.Purchases
      require Logger

      @behaviour LemonEx.Webhooks.Handler

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "order_created"} = event) do
        Logger.info("LemonSqueezy order created: \#{inspect(event.data["id"])}")
        
        case Purchases.create_or_update_purchase_from_order(event.data) do
          {:ok, purchase} ->
            Logger.info("Purchase created/updated: \#{purchase.id}")
            :ok
          {:error, changeset} ->
            Logger.error("Failed to create/update purchase: \#{inspect(changeset.errors)}")
            {:error, "Failed to process order_created event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "order_refunded"} = event) do
        Logger.info("LemonSqueezy order refunded: \#{inspect(event.data["id"])}")
        
        case Purchases.create_or_update_purchase_from_order(event.data) do
          {:ok, purchase} ->
            Logger.info("Purchase refund processed: \#{purchase.id}")
            :ok
          {:error, changeset} ->
            Logger.error("Failed to process refund: \#{inspect(changeset.errors)}")
            {:error, "Failed to process order_refunded event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_created"} = event) do
        Logger.info("LemonSqueezy subscription created: \#{inspect(event.data["id"])}")
        
        case Purchases.update_subscription(event) do
          :ok -> :ok
          {:error, reason} ->
            Logger.error("Failed to handle subscription_created: \#{inspect(reason)}")
            {:error, "Failed to process subscription_created event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_updated"} = event) do
        Logger.info("LemonSqueezy subscription updated: \#{inspect(event.data["id"])}")
        
        case Purchases.update_subscription(event) do
          :ok -> :ok
          {:error, reason} ->
            Logger.error("Failed to handle subscription_updated: \#{inspect(reason)}")
            {:error, "Failed to process subscription_updated event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_payment_success"} = event) do
        Logger.info("LemonSqueezy subscription payment success: \#{inspect(event.data["id"])}")
        
        case Purchases.update_subscription(event) do
          :ok -> :ok
          {:error, reason} ->
            Logger.error("Failed to handle subscription_payment_success: \#{inspect(reason)}")
            {:error, "Failed to process subscription_payment_success event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_payment_failed"} = event) do
        Logger.info("LemonSqueezy subscription payment failed: \#{inspect(event.data["id"])}")
        
        case Purchases.update_subscription(event) do
          :ok -> :ok
          {:error, reason} ->
            Logger.error("Failed to handle subscription_payment_failed: \#{inspect(reason)}")
            {:error, "Failed to process subscription_payment_failed event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_payment_recovered"} = event) do
        Logger.info("LemonSqueezy subscription payment recovered: \#{inspect(event.data["id"])}")
        
        case Purchases.update_subscription(event) do
          :ok -> :ok
          {:error, reason} ->
            Logger.error("Failed to handle subscription_payment_recovered: \#{inspect(reason)}")
            {:error, "Failed to process subscription_payment_recovered event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_cancelled"} = event) do
        Logger.info("LemonSqueezy subscription cancelled: \#{inspect(event.data["id"])}")
        
        Purchases.cancel_subscription(event)
        :ok
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_resumed"} = event) do
        Logger.info("LemonSqueezy subscription resumed: \#{inspect(event.data["id"])}")
        
        case Purchases.update_subscription(event) do
          :ok -> :ok
          {:error, reason} ->
            Logger.error("Failed to handle subscription_resumed: \#{inspect(reason)}")
            {:error, "Failed to process subscription_resumed event"}
        end
      end

      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: "subscription_expired"} = event) do
        Logger.info("LemonSqueezy subscription expired: \#{inspect(event.data["id"])}")
        
        Purchases.cancel_subscription(event)
        :ok
      end

      # You need to handle all incoming events. So, better have a
      # catch-all handler for events that you don't want to handle,
      # but only want to acknowledge.
      @impl true
      def handle_event(%LemonEx.Webhooks.Event{name: event_name} = event) do
        Logger.info("Unhandled LemonSqueezy event: \#{event_name}")
        Logger.debug("Event data: \#{inspect(event)}")
        :ok
      end

      def handle_event(unhandled_event) do
        Logger.warning("Received unexpected event format: \#{inspect(unhandled_event)}")
        :ok
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner_web/controllers/lemon_squeezy_webhooks_controller.ex",
      handler_content
    )
  end

  defp update_endpoint(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/endpoint.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "LemonEx.Webhooks.Plug") do
        # Plug already exists
        source
      else
        # Add LemonSqueezy webhook plug before the json decoder plug
        updated_content =
          String.replace(
            content,
            ~r/(plug Plug\.Parsers,)/,
            "  # LemonSqueezy webhooks\n  plug LemonEx.Webhooks.Plug,\n    at: \"/webhook/lemonsqueezy\",\n    handler: NeptunerWeb.LemonSqueezyWebhookHandler\n\n  \\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_migration(igniter) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")
    migration_filename = "#{timestamp}_add_purchases.exs"

    migration_content = """
    defmodule Neptuner.Repo.Migrations.AddPurchases do
      use Ecto.Migration

      def change do
        create table(:purchases) do
          # LemonSqueezy Order identifiers
          add :lemonsqueezy_order_id, :integer, null: false
          add :lemonsqueezy_customer_id, :integer
          add :order_identifier, :string
          add :order_number, :integer
          
          # Customer information
          add :user_name, :string
          add :user_email, :string, null: false
          
          # Financial fields (amounts in cents)
          add :currency, :string, null: false, size: 3
          add :currency_rate, :float
          add :subtotal, :integer
          add :setup_fee, :integer, default: 0
          add :discount_total, :integer, default: 0
          add :tax, :integer, default: 0
          add :total, :integer, null: false
          add :refunded_amount, :integer, default: 0
          
          # Status and flags
          add :status, :string, null: false
          add :refunded, :boolean, default: false
          add :refunded_at, :utc_datetime
          add :test_mode, :boolean, default: false
          
          # Tax information
          add :tax_name, :string
          add :tax_rate, :float
          add :tax_inclusive, :boolean
          
          # Product information
          add :product_name, :string
          add :variant_name, :string
          
          # JSON metadata fields
          add :metadata, :map, default: %{}
          add :custom_data, :map, default: %{}
          
          # URLs
          add :receipt_url, :string
          add :customer_portal_url, :string
          
          # User relationship
          add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

          timestamps(type: :utc_datetime)
        end

        # Indexes for performance
        create unique_index(:purchases, [:lemonsqueezy_order_id])
        create unique_index(:purchases, [:order_identifier])
        create index(:purchases, [:lemonsqueezy_customer_id])
        create index(:purchases, [:user_id])
        create index(:purchases, [:status])
        create index(:purchases, [:user_email])
        create index(:purchases, [:test_mode])
        create index(:purchases, [:refunded])
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "priv/repo/migrations/#{migration_filename}",
      migration_content
    )
  end

  defp create_purchases_test(igniter) do
    test_content = """
    defmodule Neptuner.PurchasesTest do
      use Neptuner.DataCase
      alias Neptuner.Purchases
      import Neptuner.Factory

      describe "purchases" do
        test "create_or_update_purchase_from_order/1 creates a new purchase" do
          order_data = build(:purchase_order_data)
          
          assert {:ok, purchase} = Purchases.create_or_update_purchase_from_order(order_data)
          
          assert purchase.lemonsqueezy_order_id == order_data["id"]
          assert purchase.user_email == order_data["user_email"]
          assert purchase.total == order_data["total"]
          assert purchase.status == order_data["status"]
          assert purchase.test_mode == order_data["test_mode"]
          assert purchase.product_name == order_data["first_order_item"]["product_name"]
          assert purchase.variant_name == order_data["first_order_item"]["variant_name"]
        end

        test "create_or_update_purchase_from_order/1 updates existing purchase" do
          order_data = build(:purchase_order_data)
          
          # Create initial purchase
          assert {:ok, purchase} = Purchases.create_or_update_purchase_from_order(order_data)
          
          # Update the order data
          updated_data = %{order_data | 
            "status" => "refunded",
            "refunded" => true,
            "refunded_amount" => order_data["total"]
          }
          
          # Update the purchase
          assert {:ok, updated_purchase} = Purchases.create_or_update_purchase_from_order(updated_data)
          
          # Should be the same record, but updated
          assert updated_purchase.id == purchase.id
          assert updated_purchase.status == "refunded"
          assert updated_purchase.refunded == true
          assert updated_purchase.refunded_amount == order_data["total"]
        end

        test "get_purchase_by_lemonsqueezy_order_id/1 finds purchase by order ID" do
          order_data = build(:purchase_order_data)
          {:ok, purchase} = Purchases.create_or_update_purchase_from_order(order_data)
          
          found_purchase = Purchases.get_purchase_by_lemonsqueezy_order_id(order_data["id"])
          assert found_purchase.id == purchase.id
        end

        test "get_purchase_by_order_identifier/1 finds purchase by identifier" do
          order_data = build(:purchase_order_data)
          {:ok, purchase} = Purchases.create_or_update_purchase_from_order(order_data)
          
          found_purchase = Purchases.get_purchase_by_order_identifier(order_data["identifier"])
          assert found_purchase.id == purchase.id
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner/purchases_test.exs",
      test_content
    )
  end

  defp create_webhook_handler_test(igniter) do
    test_content = """
    defmodule NeptunerWeb.LemonSqueezyWebhookHandlerTest do
      use Neptuner.DataCase
      alias NeptunerWeb.LemonSqueezyWebhookHandler
      alias Neptuner.Purchases
      import Neptuner.Factory

      describe "webhook handler" do
        test "handles order_created event" do
          event = build(:lemonsqueezy_webhook_event)

          assert :ok = LemonSqueezyWebhookHandler.handle_event(event)
          
          # Verify purchase was created
          purchase = Purchases.get_purchase_by_lemonsqueezy_order_id(event.data["id"])
          assert purchase != nil
          assert purchase.user_email == event.data["user_email"]
          assert purchase.total == event.data["total"]
          assert purchase.status == event.data["status"]
        end

        test "handles order_refunded event" do
          # First create an order
          create_event = build(:lemonsqueezy_webhook_event)
          assert :ok = LemonSqueezyWebhookHandler.handle_event(create_event)
          
          # Now refund it
          refund_event = build(:refunded_webhook_event, data: %{create_event.data | 
            "status" => "refunded",
            "refunded" => true,
            "refunded_amount" => create_event.data["total"]
          })

          assert :ok = LemonSqueezyWebhookHandler.handle_event(refund_event)
          
          # Verify purchase was updated
          purchase = Purchases.get_purchase_by_lemonsqueezy_order_id(create_event.data["id"])
          assert purchase.status == "refunded"
          assert purchase.refunded == true
          assert purchase.refunded_amount == create_event.data["total"]
        end

        test "handles subscription events" do
          event = build(:subscription_webhook_event)

          assert :ok = LemonSqueezyWebhookHandler.handle_event(event)
        end

        test "handles unrecognized events gracefully" do
          event = %LemonEx.Webhooks.Event{
            name: "unknown_event",
            data: %{},
            meta: %{}
          }

          assert :ok = LemonSqueezyWebhookHandler.handle_event(event)
        end

        test "handles malformed events gracefully" do
          assert :ok = LemonSqueezyWebhookHandler.handle_event(%{unexpected: "format"})
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner_web/lemon_squeezy_webhook_handler_test.exs",
      test_content
    )
  end

  defp update_factory(igniter) do
    Igniter.update_file(igniter, "test/support/factory.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "def purchase_factory") do
        # Factory definitions already exist
        source
      else
        # Add factory definitions after the use line
        factory_definitions = """
          alias Neptuner.Purchases.Purchase

          def purchase_factory do
            order_id = Faker.random_between(100_000, 999_999)
            total_cents = Faker.random_between(500, 50_000)
            
            %Purchase{
              lemonsqueezy_order_id: order_id,
              lemonsqueezy_customer_id: Faker.random_between(10_000, 99_999),
              order_identifier: "uuid-\#{Faker.UUID.v4()}",
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
              receipt_url: "https://lemonsqueezy.com/receipts/\#{order_id}",
              customer_portal_url: "https://lemonsqueezy.com/portal/\#{order_id}"
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
              "identifier" => "uuid-\#{Faker.UUID.v4()}",
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
                "receipt" => "https://lemonsqueezy.com/receipts/\#{order_id}",
                "customer_portal" => "https://lemonsqueezy.com/portal/\#{order_id}"
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
            %{purchase | 
              status: "refunded", 
              refunded: true, 
              refunded_amount: purchase.total,
              refunded_at: DateTime.utc_now()
            }
          end

          def partial_refund_purchase_factory do
            purchase = build(:purchase)
            partial_amount = div(purchase.total, 2)
            %{purchase | 
              status: "partial_refund", 
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
            order_data = build(:purchase_order_data, %{
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
        """

        replacement = "use ExMachina.Ecto, repo: Neptuner.Repo\n" <> factory_definitions

        updated_content =
          String.replace(
            content,
            "use ExMachina.Ecto, repo: Neptuner.Repo",
            replacement
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_env_example(igniter) do
    Igniter.update_file(igniter, ".env.example", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "LEMONSQUEEZY_API_KEY") do
        # LemonSqueezy keys already exist
        source
      else
        # Add LemonSqueezy environment variables
        lemonsqueezy_env_vars = """
        LEMONSQUEEZY_API_KEY=
        LEMONSQUEEZY_WEBHOOK_SECRET=
        """

        updated_content =
          if String.trim(content) == "" do
            String.trim(lemonsqueezy_env_vars)
          else
            String.trim(lemonsqueezy_env_vars) <> "\n" <> content
          end

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## LemonSqueezy Integration Complete! 🍋

    LemonSqueezy payment processing has been successfully integrated into your SaaS template. Here's what was configured:

    ### Dependencies Added:
    - lemon_ex (~> 0.2.4) for LemonSqueezy API integration
    - httpoison (~> 2.2.3) for HTTP requests

    ### Configuration Added:
    - LemonSqueezy configuration in config/config.exs for production
    - Development configuration in config/dev.exs with test keys
    - Webhook signature verification for security

    ### Database Schema Created:
    - Purchase schema with comprehensive LemonSqueezy order data fields
    - Migration file for purchases table with proper indexes
    - Relationship to User model for purchase tracking

    ### Code Created:
    - Neptuner.Purchases context module for purchase management
    - Neptuner.Purchases.Purchase schema with validations
    - LemonSqueezyWebhookHandler for handling LemonSqueezy webhook events
    - Webhook plug at /webhook/lemonsqueezy

    ### Files Created:
    - lib/neptuner/purchases.ex - Purchase context module
    - lib/neptuner/purchases/purchase.ex - Purchase schema
    - lib/neptuner_web/controllers/lemon_squeezy_webhooks_controller.ex - Webhook handler
    - priv/repo/migrations/*_add_purchases.exs - Database migration

    ### Files Updated:
    - mix.exs with lemon_ex and httpoison dependencies
    - config/config.exs with production LemonSqueezy configuration
    - config/dev.exs with development configuration
    - lib/neptuner_web/endpoint.ex with webhook plug
    - .env.example with required environment variables

    ### Webhook Events Handled:
    - order_created - Creates/updates purchase records
    - order_refunded - Updates purchase status and refund amount
    - subscription_created - Handles subscription creation
    - subscription_updated - Handles subscription updates
    - subscription_payment_success - Handles successful subscription payments
    - subscription_payment_failed - Handles failed subscription payments
    - subscription_payment_recovered - Handles recovered subscription payments
    - subscription_cancelled - Handles subscription cancellations
    - subscription_resumed - Handles subscription resumptions
    - subscription_expired - Handles subscription expirations

    ### Next Steps:
    1. Set up LemonSqueezy API keys:
       - Visit https://app.lemonsqueezy.com/settings/api
       - Create a new API key
       - Set LEMONSQUEEZY_API_KEY and LEMONSQUEEZY_WEBHOOK_SECRET in your environment

    2. Run the migration:
       ```bash
       mix ecto.migrate
       ```

    3. Set up webhook endpoint in LemonSqueezy Dashboard:
       - Go to https://app.lemonsqueezy.com/settings/webhooks
       - Add endpoint: https://yourdomain.com/webhook/lemonsqueezy
       - Select events: order_created, order_refunded, subscription events, etc.

    4. For development/testing:
       - Use the test API key provided in dev.exs
       - The webhook endpoint will work with both test and live LemonSqueezy

    ### Usage Examples:
    ```elixir
    # List all purchases
    Neptuner.Purchases.list_purchases()

    # Get purchase by LemonSqueezy order ID
    Neptuner.Purchases.get_purchase_by_lemonsqueezy_order_id(123456)

    # Get purchase by order identifier
    Neptuner.Purchases.get_purchase_by_order_identifier("uuid-123-456-789")

    # Test webhook endpoint
    curl -X POST http://localhost:4000/webhook/lemonsqueezy \\
      -H "Content-Type: application/json" \\
      -d '{"meta": {"event_name": "order_created"}, "data": {...}}'
    ```

    ### LemonSqueezy Features:
    - Secure webhook signature verification in production
    - Comprehensive purchase and subscription tracking
    - Support for various LemonSqueezy events and payment methods
    - Integration with your existing User model
    - Full support for orders, subscriptions, and refunds

    🎉 Your app now supports LemonSqueezy payment processing!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
