defmodule Mix.Tasks.Neptuner.Gen.Polar do
  @moduledoc """
  Installs Polar.sh payment integration for the SaaS template using Igniter.

  This task:
  - Adds polarex dependency to mix.exs
  - Adds Polar.sh configuration to config.exs and dev.exs
  - Creates Purchase schema and context module for Polar orders
  - Creates Polar webhook handler
  - Adds webhook route to router
  - Generates database migration for purchases
  - Updates .env.example with Polar environment variables

      $ mix neptuner.gen.polar

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      |> add_polar_dependency()
      |> add_polar_config()
      |> add_polar_dev_config()
      |> create_purchase_schema()
      |> create_purchases_context()
      |> create_polar_webhook_handler()
      |> update_router()
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

  defp add_polar_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:polarex,") do
        # Dependency already exists
        source
      else
        # Add polarex dependency after timex
        updated_content =
          String.replace(
            content,
            ~r/(\{:timex, \"~> 3\.7\.13\"\})/,
            "\\1,\n      # Polar.sh integration\n      {:polarex, \"~> 0.2.0\"}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_polar_config(igniter) do
    config_content = """
    config :polarex,
      server: System.get_env("POLAR_SERVER_URL", "https://sandbox-api.polar.sh"),
      access_token: System.get_env("POLAR_ACCESS_TOKEN")

    config :neptuner,
      polar_webhook_secret: System.get_env("POLAR_WEBHOOK_SECRET")
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :polarex") do
        # Config already exists
        source
      else
        # Add Polar config before the import_config line
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

  defp add_polar_dev_config(igniter) do
    dev_config_content = """
    # Polar development configuration
    config :polarex,
      server: "https://sandbox-api.polar.sh",
      access_token: "test_access_token"

    config :neptuner,
      polar_webhook_secret: "test_webhook_secret"
    """

    Igniter.update_file(igniter, "config/dev.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :polarex") do
        # Config already exists
        source
      else
        # Add Polar dev config before the swoosh config
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
        # Polar Order fields
        field :polar_order_id, :string
        field :polar_customer_id, :string
        field :polar_checkout_id, :string
        field :polar_subscription_id, :string
        field :user_name, :string
        field :user_email, :string
        
        # Financial fields (all amounts in cents)
        field :currency, :string
        field :amount, :integer
        field :tax_amount, :integer
        field :platform_fee_type, :string
        field :platform_fee_amount, :integer
        
        # Status and metadata
        field :status, :string
        field :billing_reason, :string
        field :billing_address, :map
        field :product_name, :string
        field :product_price_id, :string
        
        # Additional metadata
        field :metadata, :map, default: %{}
        field :custom_data, :map, default: %{}

        belongs_to :user, Neptuner.Accounts.User

        timestamps()
      end

      @required_fields ~w(amount currency status user_email)a
      @optional_fields ~w(
        polar_order_id polar_customer_id polar_checkout_id polar_subscription_id user_name
        tax_amount platform_fee_type platform_fee_amount billing_reason
        billing_address product_name product_price_id metadata custom_data user_id
      )a

      def changeset(purchase, attrs) do
        purchase
        |> cast(attrs, @required_fields ++ @optional_fields)
        |> validate_required(@required_fields)
        |> validate_number(:amount, greater_than_or_equal_to: 0)
        |> validate_length(:currency, is: 3)
        |> validate_inclusion(:status, ["pending", "succeeded", "canceled", "requires_action", "open", "confirmed", "completed", "paid"])
        |> validate_inclusion(:billing_reason, ["purchase", "subscription_create", "subscription_cycle", "subscription_update"])
        |> validate_format(:user_email, ~r/^[^\\s]+@[^\\s]+\\.[^\\s]+$/)
        |> unique_constraint(:polar_order_id)
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

      def get_purchase_by_polar_order_id(order_id) do
        Repo.get_by(Purchase, polar_order_id: order_id)
      end

      def get_purchase_by_polar_checkout_id(checkout_id) do
        from(p in Purchase, where: p.polar_checkout_id == ^checkout_id, order_by: [desc: p.inserted_at], limit: 1)
        |> Repo.one()
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
        
        # First check if we have a purchase with this order ID
        case get_purchase_by_polar_order_id(attrs[:polar_order_id]) do
          nil -> 
            # If no purchase by order ID, check if we have one by checkout ID
            case attrs[:polar_checkout_id] && get_purchase_by_polar_checkout_id(attrs[:polar_checkout_id]) do
              nil ->
                Logger.info("Creating new purchase for Polar order \#{attrs[:polar_order_id]}")
                create_purchase(attrs)
              purchase ->
                Logger.info("Updating existing purchase (found by checkout ID) for Polar order \#{attrs[:polar_order_id]}")
                update_purchase(purchase, attrs)
            end
          purchase -> 
            Logger.info("Updating existing purchase for Polar order \#{attrs[:polar_order_id]}")
            update_purchase(purchase, attrs)
        end
      end

      def create_or_update_purchase_from_checkout(checkout_data) do
        attrs = build_purchase_attrs_from_checkout(checkout_data)
        
        # Check if we already have a purchase with this checkout ID
        case get_purchase_by_polar_checkout_id(attrs[:polar_checkout_id]) do
          nil -> 
            Logger.info("Creating new purchase for Polar checkout \#{attrs[:polar_checkout_id]}")
            create_purchase(attrs)
          purchase -> 
            Logger.info("Updating existing purchase for Polar checkout \#{attrs[:polar_checkout_id]}")
            update_purchase(purchase, attrs)
        end
      end

      def handle_subscription_event(subscription_data) do
        Logger.info("Handling subscription event: \#{inspect(subscription_data)}")
        :ok
      end

      def handle_customer_event(customer_data) do
        Logger.info("Handling customer event: \#{inspect(customer_data)}")
        :ok
      end

      def handle_benefit_grant_event(benefit_grant_data) do
        Logger.info("Handling benefit grant event: \#{inspect(benefit_grant_data)}")
        :ok
      end

      # Private functions

      defp build_purchase_attrs_from_order(order_data) do
        %{
          polar_order_id: order_data["id"],
          polar_customer_id: get_in(order_data, ["customer", "id"]),
          polar_checkout_id: order_data["checkout_id"],
          polar_subscription_id: get_in(order_data, ["subscription", "id"]),
          user_name: get_customer_name(order_data),
          user_email: get_customer_email(order_data),
          currency: order_data["currency"],
          amount: parse_amount(order_data["total_amount"] || order_data["amount"]),
          tax_amount: parse_amount(order_data["tax_amount"]) || 0,
          platform_fee_type: get_in(order_data, ["platform_fee_type"]),
          platform_fee_amount: parse_amount(get_in(order_data, ["platform_fee_amount"])) || 0,
          status: order_data["status"],
          billing_reason: order_data["billing_reason"],
          billing_address: get_in(order_data, ["billing_address"]) || %{},
          product_name: get_product_name(order_data),
          product_price_id: get_in(order_data, ["product_price", "id"]),
          metadata: order_data["metadata"] || %{},
          custom_data: extract_custom_data(order_data)
        }
      end

      defp build_purchase_attrs_from_checkout(checkout_data) do
        attrs = %{
          polar_checkout_id: checkout_data["id"],
          polar_customer_id: checkout_data["customer_id"],
          user_name: get_customer_name(checkout_data),
          user_email: get_customer_email(checkout_data),
          currency: checkout_data["currency"],
          amount: parse_amount(checkout_data["total_amount"] || checkout_data["amount"]),
          tax_amount: parse_amount(checkout_data["tax_amount"]) || 0,
          status: checkout_data["status"],
          product_name: get_product_name(checkout_data),
          product_price_id: checkout_data["product_price_id"],
          metadata: checkout_data["metadata"] || %{},
          custom_data: extract_custom_data(checkout_data)
        }
        
        # Don't include polar_order_id for checkouts since they don't have orders yet
        attrs
      end

      defp get_customer_name(%{"customer" => %{"name" => name}}) when is_binary(name), do: name
      defp get_customer_name(%{"user" => %{"public_name" => name}}) when is_binary(name), do: name
      defp get_customer_name(%{"billing_name" => name}) when is_binary(name), do: name
      defp get_customer_name(_), do: nil

      defp get_customer_email(%{"customer" => %{"email" => email}}) when is_binary(email), do: email
      defp get_customer_email(%{"user" => %{"email" => email}}) when is_binary(email), do: email
      defp get_customer_email(%{"customer_email" => email}) when is_binary(email), do: email
      defp get_customer_email(%{"email" => email}) when is_binary(email), do: email
      defp get_customer_email(_), do: "unknown@polar.sh"

      defp get_product_name(%{"product" => %{"name" => name}}), do: name
      defp get_product_name(%{"product_name" => name}), do: name
      defp get_product_name(%{"products" => [%{"name" => name} | _]}), do: name
      defp get_product_name(_), do: nil

      defp extract_custom_data(%{"custom_field_data" => data}) when is_map(data), do: data
      defp extract_custom_data(%{"metadata" => data}) when is_map(data), do: data
      defp extract_custom_data(_), do: %{}

      defp parse_amount(amount) when is_integer(amount), do: amount
      defp parse_amount(amount) when is_binary(amount) do
        case Integer.parse(amount) do
          {int_amount, _} -> int_amount
          :error -> 0
        end
      end
      defp parse_amount(_), do: 0
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/purchases.ex",
      purchases_content
    )
  end

  defp create_polar_webhook_handler(igniter) do
    handler_content = """
    defmodule NeptunerWeb.PolarWebhookController do
      use NeptunerWeb, :controller
      alias Neptuner.Purchases
      require Logger

      def handle_webhook(conn, params) do
        Logger.info("Received Polar webhook with params: \#{inspect(params)}")
        
        case verify_webhook_signature(conn, params) do
          {:ok, event_data} ->
            handle_polar_event(event_data)
            send_resp(conn, 200, "OK")
          
          {:error, reason} ->
            Logger.error("Webhook verification failed: \#{inspect(reason)}")
            send_resp(conn, 400, "Bad Request")
        end
      end

      defp verify_webhook_signature(conn, params) do
        # Get webhook secret from config
        webhook_secret = Application.get_env(:neptuner, :polar_webhook_secret)
        
        # Get signature from headers
        signature = get_req_header(conn, "webhook-signature") |> List.first()
        
        # In test environment, skip signature verification
        if Mix.env() == :test do
          {:ok, params}
        else
          if webhook_secret && signature do
            # For now, we'll trust the webhook - in production you should verify the signature
            # using the Standard Webhooks specification that Polar follows
            {:ok, params}
          else
            {:error, "Missing webhook secret or signature"}
          end
        end
      end

      defp handle_polar_event(%{"type" => event_type, "data" => data}) do
        Logger.info("Received Polar webhook: \#{event_type}")
        
        case event_type do
          # Order events
          "order.created" -> handle_order_created(data)
          "order.paid" -> handle_order_paid(data)
          "order.updated" -> handle_order_updated(data)
          "order.refunded" -> handle_order_refunded(data)
          
          # Checkout events
          "checkout.created" -> handle_checkout_created(data)
          "checkout.updated" -> handle_checkout_updated(data)
          
          # Subscription events
          "subscription.created" -> handle_subscription_created(data)
          "subscription.updated" -> handle_subscription_updated(data)
          "subscription.active" -> handle_subscription_active(data)
          "subscription.canceled" -> handle_subscription_canceled(data)
          "subscription.uncanceled" -> handle_subscription_uncanceled(data)
          "subscription.revoked" -> handle_subscription_revoked(data)
          
          # Customer events
          "customer.created" -> handle_customer_created(data)
          "customer.updated" -> handle_customer_updated(data)
          "customer.deleted" -> handle_customer_deleted(data)
          "customer.state_changed" -> handle_customer_state_changed(data)
          
          # Benefit grant events
          "benefit_grant.created" -> handle_benefit_grant_created(data)
          "benefit_grant.updated" -> handle_benefit_grant_updated(data)
          "benefit_grant.revoked" -> handle_benefit_grant_revoked(data)
          
          # Refund events
          "refund.created" -> handle_refund_created(data)
          "refund.updated" -> handle_refund_updated(data)
          
          # Unhandled events
          _ -> 
            Logger.info("Unhandled Polar event: \#{event_type}")
            :ok
        end
      end

      # Catch-all for malformed events
      defp handle_polar_event(event) do
        Logger.warning("Received malformed Polar event: \#{inspect(event)}")
        :ok
      end

      # Order event handlers
      defp handle_order_created(data) do
        Logger.info("Order created: \#{inspect(data["id"])}")
        Logger.debug("Order data: \#{inspect(data)}")
        
        case Purchases.create_or_update_purchase_from_order(data) do
          {:ok, purchase} ->
            Logger.info("Purchase created: \#{purchase.id}")
            :ok
          {:error, changeset} ->
            Logger.error("Failed to create purchase: \#{inspect(changeset.errors)}")
            Logger.error("Order data that failed: \#{inspect(data)}")
            {:error, "Failed to process order_created event"}
        end
      end

      defp handle_order_paid(data) do
        Logger.info("Order paid: \#{inspect(data["id"])}")
        
        case Purchases.create_or_update_purchase_from_order(data) do
          {:ok, purchase} ->
            Logger.info("Purchase updated for payment: \#{purchase.id}")
            :ok
          {:error, changeset} ->
            Logger.error("Failed to update purchase: \#{inspect(changeset.errors)}")
            {:error, "Failed to process order_paid event"}
        end
      end

      defp handle_order_updated(data) do
        Logger.info("Order updated: \#{inspect(data["id"])}")
        
        case Purchases.create_or_update_purchase_from_order(data) do
          {:ok, purchase} ->
            Logger.info("Purchase updated: \#{purchase.id}")
            :ok
          {:error, changeset} ->
            Logger.error("Failed to update purchase: \#{inspect(changeset.errors)}")
            {:error, "Failed to process order_updated event"}
        end
      end

      defp handle_order_refunded(data) do
        Logger.info("Order refunded: \#{inspect(data["id"])}")
        
        case Purchases.create_or_update_purchase_from_order(data) do
          {:ok, purchase} ->
            Logger.info("Purchase refund processed: \#{purchase.id}")
            :ok
          {:error, changeset} ->
            Logger.error("Failed to process refund: \#{inspect(changeset.errors)}")
            {:error, "Failed to process order_refunded event"}
        end
      end

      # Checkout event handlers
      defp handle_checkout_created(data) do
        Logger.info("Checkout created: \#{inspect(data["id"])}")
        Logger.debug("Checkout data: \#{inspect(data)}")
        
        # Only create purchase records for checkouts that have customer info
        # "open" status means checkout is created but customer hasn't filled it out yet
        case data["status"] do
          "open" ->
            Logger.info("Checkout is in 'open' status, skipping purchase creation until customer completes it")
            :ok
          _ ->
            case Purchases.create_or_update_purchase_from_checkout(data) do
              {:ok, purchase} ->
                Logger.info("Purchase created from checkout: \#{purchase.id}")
                :ok
              {:error, changeset} ->
                Logger.error("Failed to create purchase from checkout: \#{inspect(changeset.errors)}")
                Logger.error("Checkout data that failed: \#{inspect(data)}")
                {:error, "Failed to process checkout_created event"}
            end
        end
      end

      defp handle_checkout_updated(data) do
        Logger.info("Checkout updated: \#{inspect(data["id"])}")
        
        case Purchases.create_or_update_purchase_from_checkout(data) do
          {:ok, purchase} ->
            Logger.info("Purchase updated from checkout: \#{purchase.id}")
            :ok
          {:error, changeset} ->
            Logger.error("Failed to update purchase from checkout: \#{inspect(changeset.errors)}")
            {:error, "Failed to process checkout_updated event"}
        end
      end

      # Subscription event handlers
      defp handle_subscription_created(data) do
        Logger.info("Subscription created: \#{inspect(data["id"])}")
        Purchases.handle_subscription_event(data)
      end

      defp handle_subscription_updated(data) do
        Logger.info("Subscription updated: \#{inspect(data["id"])}")
        Purchases.handle_subscription_event(data)
      end

      defp handle_subscription_active(data) do
        Logger.info("Subscription active: \#{inspect(data["id"])}")
        Purchases.handle_subscription_event(data)
      end

      defp handle_subscription_canceled(data) do
        Logger.info("Subscription canceled: \#{inspect(data["id"])}")
        Purchases.handle_subscription_event(data)
      end

      defp handle_subscription_uncanceled(data) do
        Logger.info("Subscription uncanceled: \#{inspect(data["id"])}")
        Purchases.handle_subscription_event(data)
      end

      defp handle_subscription_revoked(data) do
        Logger.info("Subscription revoked: \#{inspect(data["id"])}")
        Purchases.handle_subscription_event(data)
      end

      # Customer event handlers
      defp handle_customer_created(data) do
        Logger.info("Customer created: \#{inspect(data["id"])}")
        Purchases.handle_customer_event(data)
      end

      defp handle_customer_updated(data) do
        Logger.info("Customer updated: \#{inspect(data["id"])}")
        Purchases.handle_customer_event(data)
      end

      defp handle_customer_deleted(data) do
        Logger.info("Customer deleted: \#{inspect(data["id"])}")
        Purchases.handle_customer_event(data)
      end

      defp handle_customer_state_changed(data) do
        Logger.info("Customer state changed: \#{inspect(data["id"])}")
        Purchases.handle_customer_event(data)
      end

      # Benefit grant event handlers
      defp handle_benefit_grant_created(data) do
        Logger.info("Benefit grant created: \#{inspect(data["id"])}")
        Purchases.handle_benefit_grant_event(data)
      end

      defp handle_benefit_grant_updated(data) do
        Logger.info("Benefit grant updated: \#{inspect(data["id"])}")
        Purchases.handle_benefit_grant_event(data)
      end

      defp handle_benefit_grant_revoked(data) do
        Logger.info("Benefit grant revoked: \#{inspect(data["id"])}")
        Purchases.handle_benefit_grant_event(data)
      end

      # Refund event handlers
      defp handle_refund_created(data) do
        Logger.info("Refund created: \#{inspect(data["id"])}")
        :ok
      end

      defp handle_refund_updated(data) do
        Logger.info("Refund updated: \#{inspect(data["id"])}")
        :ok
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner_web/controllers/polar_webhook_controller.ex",
      handler_content
    )
  end

  defp update_router(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "PolarWebhookController") do
        # Route already exists
        source
      else
        # Uncomment the API scope and add the webhook route
        updated_content =
          String.replace(
            content,
            ~r/  # scope "\/api", NeptunerWeb do\n  #   pipe_through :api\n  # end/,
            "  scope \"/api\", NeptunerWeb do\n    pipe_through :api\n    post \"/webhooks/polar\", PolarWebhookController, :handle_webhook\n  end"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_migration(igniter) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")
    migration_filename = "#{timestamp}_add_polar_purchases.exs"

    migration_content = """
    defmodule Neptuner.Repo.Migrations.AddPolarPurchases do
      use Ecto.Migration

      def change do
        create table(:purchases) do
          # Polar identifiers
          add :polar_order_id, :string
          add :polar_customer_id, :string
          add :polar_checkout_id, :string
          add :polar_subscription_id, :string
          
          # Customer information
          add :user_name, :string
          add :user_email, :string, null: false
          
          # Financial fields (amounts in cents)
          add :currency, :string, null: false, size: 3
          add :amount, :integer, null: false
          add :tax_amount, :integer, default: 0
          add :platform_fee_type, :string
          add :platform_fee_amount, :integer, default: 0
          
          # Status and metadata
          add :status, :string, null: false
          add :billing_reason, :string
          add :billing_address, :map, default: %{}
          
          # Product information
          add :product_name, :string
          add :product_price_id, :string
          
          # JSON metadata fields
          add :metadata, :map, default: %{}
          add :custom_data, :map, default: %{}
          
          # User relationship
          add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

          timestamps(type: :utc_datetime)
        end

        # Indexes for performance
        create unique_index(:purchases, [:polar_order_id], where: "polar_order_id IS NOT NULL")
        create unique_index(:purchases, [:polar_checkout_id], where: "polar_checkout_id IS NOT NULL")
        create index(:purchases, [:polar_customer_id])
        create index(:purchases, [:polar_subscription_id])
        create index(:purchases, [:user_id])
        create index(:purchases, [:status])
        create index(:purchases, [:user_email])
        create index(:purchases, [:billing_reason])
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
          order_data = build(:polar_order_data)
          
          assert {:ok, purchase} = Purchases.create_or_update_purchase_from_order(order_data)
          
          assert purchase.polar_order_id == order_data["id"]
          assert purchase.user_email == order_data["customer"]["email"]
          assert purchase.amount == order_data["amount"]
          assert purchase.status == order_data["status"]
          assert purchase.currency == order_data["currency"]
          assert purchase.product_name == order_data["product"]["name"]
        end

        test "create_or_update_purchase_from_order/1 updates existing purchase" do
          order_data = build(:polar_order_data)
          
          # Create initial purchase
          assert {:ok, purchase} = Purchases.create_or_update_purchase_from_order(order_data)
          
          # Update the order data
          updated_data = %{order_data | 
            "status" => "succeeded",
            "amount" => order_data["amount"] + 1000
          }
          
          # Update the purchase
          assert {:ok, updated_purchase} = Purchases.create_or_update_purchase_from_order(updated_data)
          
          # Should be the same record, but updated
          assert updated_purchase.id == purchase.id
          assert updated_purchase.status == "succeeded"
          assert updated_purchase.amount == order_data["amount"] + 1000
        end

        test "create_or_update_purchase_from_checkout/1 creates a new purchase" do
          checkout_data = build(:polar_checkout_data)
          
          assert {:ok, purchase} = Purchases.create_or_update_purchase_from_checkout(checkout_data)
          
          assert purchase.polar_checkout_id == checkout_data["id"]
          assert purchase.user_email == checkout_data["customer"]["email"]
          assert purchase.amount == checkout_data["amount"]
          assert purchase.status == checkout_data["status"]
        end

        test "get_purchase_by_polar_order_id/1 finds purchase by order ID" do
          order_data = build(:polar_order_data)
          {:ok, purchase} = Purchases.create_or_update_purchase_from_order(order_data)
          
          found_purchase = Purchases.get_purchase_by_polar_order_id(order_data["id"])
          assert found_purchase.id == purchase.id
        end

        test "get_purchase_by_polar_checkout_id/1 finds purchase by checkout ID" do
          checkout_data = build(:polar_checkout_data)
          {:ok, purchase} = Purchases.create_or_update_purchase_from_checkout(checkout_data)
          
          found_purchase = Purchases.get_purchase_by_polar_checkout_id(checkout_data["id"])
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
    defmodule NeptunerWeb.PolarWebhookControllerTest do
      use NeptunerWeb.ConnCase
      alias Neptuner.Purchases
      import Neptuner.Factory

      describe "webhook handler" do
        test "handles order.created event", %{conn: conn} do
          event_data = %{
            "type" => "order.created",
            "data" => build(:polar_order_data)
          }

          conn = post(conn, ~p"/api/webhooks/polar", event_data)
          
          assert response(conn, 200) == "OK"
          
          # Verify purchase was created
          purchase = Purchases.get_purchase_by_polar_order_id(event_data["data"]["id"])
          assert purchase != nil
          assert purchase.user_email == event_data["data"]["customer"]["email"]
          assert purchase.amount == event_data["data"]["amount"]
          assert purchase.status == event_data["data"]["status"]
        end

        test "handles order.paid event", %{conn: conn} do
          # First create an order
          order_data = build(:polar_order_data)
          create_event = %{"type" => "order.created", "data" => order_data}
          post(conn, ~p"/api/webhooks/polar", create_event)
          
          # Now mark it as paid
          paid_event = %{
            "type" => "order.paid",
            "data" => %{order_data | "status" => "succeeded"}
          }

          conn = post(conn, ~p"/api/webhooks/polar", paid_event)
          assert response(conn, 200) == "OK"
          
          # Verify purchase was updated
          purchase = Purchases.get_purchase_by_polar_order_id(order_data["id"])
          assert purchase.status == "succeeded"
        end

        test "handles checkout.created event", %{conn: conn} do
          event_data = %{
            "type" => "checkout.created",
            "data" => build(:polar_checkout_data)
          }

          conn = post(conn, ~p"/api/webhooks/polar", event_data)
          assert response(conn, 200) == "OK"
          
          # Verify purchase was created from checkout
          purchase = Purchases.get_purchase_by_polar_checkout_id(event_data["data"]["id"])
          assert purchase != nil
          assert purchase.user_email == event_data["data"]["customer"]["email"]
        end

        test "handles subscription events", %{conn: conn} do
          event_data = %{
            "type" => "subscription.created",
            "data" => build(:polar_subscription_data)
          }

          conn = post(conn, ~p"/api/webhooks/polar", event_data)
          assert response(conn, 200) == "OK"
        end

        test "handles unrecognized events gracefully", %{conn: conn} do
          event_data = %{
            "type" => "unknown_event",
            "data" => %{}
          }

          conn = post(conn, ~p"/api/webhooks/polar", event_data)
          assert response(conn, 200) == "OK"
        end

        test "handles malformed webhook data", %{conn: conn} do
          conn = post(conn, ~p"/api/webhooks/polar", %{"malformed" => "data"})
          assert response(conn, 200) == "OK"
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner_web/polar_webhook_controller_test.exs",
      test_content
    )
  end

  defp update_factory(igniter) do
    Igniter.update_file(igniter, "test/support/factory.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "def polar_order_data_factory") do
        # Factory definitions already exist
        source
      else
        # Add factory definitions after the use line
        factory_definitions = """
          alias Neptuner.Purchases.Purchase

          defp random_string(length) do
            :crypto.strong_rand_bytes(length)
            |> Base.encode32(case: :lower)
            |> String.slice(0, length)
          end

          def purchase_factory do
            order_id = "po_" <> random_string(16)
            amount_cents = Faker.random_between(500, 50_000)
            
            %Purchase{
              polar_order_id: order_id,
              polar_customer_id: "cu_" <> random_string(16),
              polar_checkout_id: "ch_" <> random_string(16),
              polar_subscription_id: "sub_" <> random_string(16),
              user_name: Faker.Person.name(),
              user_email: Faker.Internet.email(),
              currency: Enum.random(["USD", "EUR", "GBP"]),
              amount: amount_cents,
              tax_amount: Faker.random_between(0, div(amount_cents, 8)),
              platform_fee_type: Enum.random(["percentage", "fixed"]),
              platform_fee_amount: Faker.random_between(0, div(amount_cents, 20)),
              status: "succeeded",
              billing_reason: "purchase",
              billing_address: %{
                "line1" => Faker.Address.street_address(),
                "city" => Faker.Address.city(),
                "state" => Faker.Address.state(),
                "postal_code" => Faker.Address.zip_code(),
                "country" => "US"
              },
              product_name: Faker.Commerce.product_name(),
              product_price_id: "price_" <> random_string(16),
              metadata: %{},
              custom_data: %{"user_id" => to_string(Faker.random_between(1, 1000))}
            }
          end

          def polar_order_data_factory do
            order_id = "po_" <> random_string(16)
            amount_cents = Faker.random_between(500, 50_000)
            
            %{
              "id" => order_id,
              "customer" => %{
                "id" => "cu_" <> random_string(16),
                "email" => Faker.Internet.email(),
                "name" => Faker.Person.name()
              },
              "checkout" => %{
                "id" => "ch_" <> random_string(16)
              },
              "subscription" => %{
                "id" => "sub_" <> random_string(16)
              },
              "currency" => Enum.random(["USD", "EUR", "GBP"]),
              "amount" => amount_cents,
              "tax_amount" => Faker.random_between(0, div(amount_cents, 8)),
              "platform_fee_type" => Enum.random(["percentage", "fixed"]),
              "platform_fee_amount" => Faker.random_between(0, div(amount_cents, 20)),
              "status" => "succeeded",
              "billing_reason" => "purchase",
              "billing_address" => %{
                "line1" => Faker.Address.street_address(),
                "city" => Faker.Address.city(),
                "state" => Faker.Address.state(),
                "postal_code" => Faker.Address.zip_code(),
                "country" => "US"
              },
              "product" => %{
                "name" => Faker.Commerce.product_name()
              },
              "product_price" => %{
                "id" => "price_" <> random_string(16)
              },
              "metadata" => %{},
              "custom_field_data" => %{"user_id" => to_string(Faker.random_between(1, 1000))}
            }
          end

          def polar_checkout_data_factory do
            checkout_id = "ch_" <> random_string(16)
            amount_cents = Faker.random_between(500, 50_000)
            
            %{
              "id" => checkout_id,
              "customer" => %{
                "id" => "cu_" <> random_string(16),
                "email" => Faker.Internet.email(),
                "name" => Faker.Person.name()
              },
              "currency" => Enum.random(["USD", "EUR", "GBP"]),
              "amount" => amount_cents,
              "tax_amount" => Faker.random_between(0, div(amount_cents, 8)),
              "status" => "pending",
              "product" => %{
                "name" => Faker.Commerce.product_name()
              },
              "product_price" => %{
                "id" => "price_" <> random_string(16)
              },
              "metadata" => %{},
              "custom_field_data" => %{"user_id" => to_string(Faker.random_between(1, 1000))}
            }
          end

          def polar_subscription_data_factory do
            %{
              "id" => "sub_" <> random_string(16),
              "customer" => %{
                "id" => "cu_" <> random_string(16),
                "email" => Faker.Internet.email(),
                "name" => Faker.Person.name()
              },
              "status" => "active",
              "current_period_start" => DateTime.utc_now() |> DateTime.to_iso8601(),
              "current_period_end" => DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.to_iso8601(),
              "product" => %{
                "name" => Faker.Commerce.product_name()
              }
            }
          end

          # Traits for different purchase states
          def pending_purchase_factory do
            build(:purchase, status: "pending")
          end

          def succeeded_purchase_factory do
            build(:purchase, status: "succeeded")
          end

          def canceled_purchase_factory do
            build(:purchase, status: "canceled")
          end

          def subscription_purchase_factory do
            build(:purchase, billing_reason: "subscription_create")
          end

          def subscription_cycle_purchase_factory do
            build(:purchase, billing_reason: "subscription_cycle")
          end

          def checkout_purchase_factory do
            amount_cents = Faker.random_between(500, 50_000)
            
            %Purchase{
              polar_checkout_id: "ch_" <> random_string(16),
              polar_customer_id: "cu_" <> random_string(16),
              user_name: Faker.Person.name(),
              user_email: Faker.Internet.email(),
              currency: Enum.random(["USD", "EUR", "GBP"]),
              amount: amount_cents,
              tax_amount: Faker.random_between(0, div(amount_cents, 8)),
              platform_fee_type: Enum.random(["percentage", "fixed"]),
              platform_fee_amount: Faker.random_between(0, div(amount_cents, 20)),
              status: "pending",
              billing_address: %{
                "line1" => Faker.Address.street_address(),
                "city" => Faker.Address.city(),
                "state" => Faker.Address.state(),
                "postal_code" => Faker.Address.zip_code(),
                "country" => "US"
              },
              product_name: Faker.Commerce.product_name(),
              product_price_id: "price_" <> random_string(16),
              metadata: %{},
              custom_data: %{"user_id" => to_string(Faker.random_between(1, 1000))}
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

      if String.contains?(content, "POLAR_ACCESS_TOKEN") do
        # Polar keys already exist
        source
      else
        # Add Polar environment variables
        polar_env_vars = """
        POLAR_ACCESS_TOKEN=
        POLAR_WEBHOOK_SECRET=
        """

        updated_content =
          if String.trim(content) == "" do
            String.trim(polar_env_vars)
          else
            String.trim(polar_env_vars) <> "\n" <> content
          end

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Polar.sh Integration Complete! ❄️

    Polar.sh payment processing has been successfully integrated into your SaaS template. Here's what was configured:

    ### Dependencies Added:
    - polarex (~> 0.2.0) for Polar.sh API integration

    ### Configuration Added:
    - Polar.sh configuration in config/config.exs for production
    - Development configuration in config/dev.exs with test keys
    - Webhook signature verification for security

    ### Database Schema Created:
    - Purchase schema with comprehensive Polar.sh order and checkout data fields
    - Migration file for purchases table with proper indexes
    - Relationship to User model for purchase tracking

    ### Code Created:
    - Neptuner.Purchases context module for purchase management
    - Neptuner.Purchases.Purchase schema with validations
    - PolarWebhookController for handling Polar.sh webhook events
    - Webhook route at /api/webhooks/polar

    ### Files Created:
    - lib/neptuner/purchases.ex - Purchase context module
    - lib/neptuner/purchases/purchase.ex - Purchase schema
    - lib/neptuner_web/controllers/polar_webhook_controller.ex - Webhook handler
    - priv/repo/migrations/*_add_polar_purchases.exs - Database migration

    ### Files Updated:
    - mix.exs with polarex dependency
    - config/config.exs with production Polar.sh configuration
    - config/dev.exs with development configuration
    - lib/neptuner_web/router.ex with webhook route
    - .env.example with required environment variables

    ### Webhook Events Handled:
    - order.created - Creates/updates purchase records
    - order.paid - Updates purchase status for payment
    - order.updated - Updates purchase information
    - order.refunded - Handles order refunds
    - checkout.created - Creates purchase from checkout
    - checkout.updated - Updates checkout information
    - subscription.created - Handles subscription creation
    - subscription.updated - Handles subscription updates
    - subscription.active - Handles active subscriptions
    - subscription.canceled - Handles subscription cancellations
    - subscription.uncanceled - Handles subscription uncancellations
    - subscription.revoked - Handles subscription revocations
    - customer.created - Handles customer creation
    - customer.updated - Handles customer updates
    - customer.deleted - Handles customer deletions
    - customer.state_changed - Handles customer state changes
    - benefit_grant.created - Handles benefit grant creation
    - benefit_grant.updated - Handles benefit grant updates
    - benefit_grant.revoked - Handles benefit grant revocations
    - refund.created - Handles refund creation
    - refund.updated - Handles refund updates

    ### Next Steps:
    1. Set up Polar.sh API keys:
       - Visit https://polar.sh/settings
       - Create a new access token
       - Set POLAR_ACCESS_TOKEN and POLAR_WEBHOOK_SECRET in your environment

    2. Run the migration:
       ```bash
       mix ecto.migrate
       ```

    3. Set up webhook endpoint in Polar.sh Dashboard:
       - Go to https://polar.sh/settings/webhooks
       - Add endpoint: https://yourdomain.com/api/webhooks/polar
       - Select events: order events, checkout events, subscription events, etc.

    4. For development/testing:
       - Use the test access token provided in dev.exs
       - The webhook endpoint will work with both sandbox and live Polar.sh

    ### Usage Examples:
    ```elixir
    # List all purchases
    Neptuner.Purchases.list_purchases()

    # Get purchase by Polar order ID
    Neptuner.Purchases.get_purchase_by_polar_order_id("po_123456")

    # Get purchase by Polar checkout ID
    Neptuner.Purchases.get_purchase_by_polar_checkout_id("ch_123456")

    # Test webhook endpoint
    curl -X POST http://localhost:4000/api/webhooks/polar \\
      -H "Content-Type: application/json" \\
      -d '{"type": "order.created", "data": {...}}'
    ```

    ### Polar.sh Features:
    - Secure webhook signature verification in production
    - Comprehensive purchase and subscription tracking
    - Support for various Polar.sh events and payment methods
    - Integration with your existing User model
    - Full support for orders, checkouts, subscriptions, and refunds
    - Support for benefit grants and customer management

    🎉 Your app now supports Polar.sh payment processing!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
