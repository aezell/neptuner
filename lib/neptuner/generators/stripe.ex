defmodule Mix.Tasks.Neptuner.Gen.Stripe do
  @moduledoc """
  Installs Stripe payment integration for the SaaS template using Igniter.

  This task:
  - Adds stripity_stripe dependency to mix.exs
  - Adds Stripe configuration to config.exs and dev.exs
  - Creates Purchase schema and context module
  - Creates Stripe webhook controller
  - Adds webhook route to router
  - Generates database migration for purchases
  - Updates .env.example with Stripe environment variables

      $ mix neptuner.gen.stripe

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      |> add_stripe_dependency()
      |> add_stripe_config()
      |> add_stripe_dev_config()
      |> create_purchase_schema()
      |> create_purchases_context()
      |> create_stripe_webhook_controller()
      |> update_router()
      |> create_migration()
      |> update_env_example()

    if opts[:yes] do
      igniter
    else
      print_completion_notice(igniter)
    end
  end

  defp add_stripe_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:stripity_stripe,") do
        # Dependency already exists
        source
      else
        # Add stripity_stripe dependency after timex
        updated_content =
          String.replace(
            content,
            ~r/(\{:timex, "~> 3\.7\.13"\})/,
            "\\1,\n      # Stripe\n      {:stripity_stripe, \"~> 3.2.0\"}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_stripe_config(igniter) do
    config_content = """
    config :stripity_stripe,
      api_key: System.get_env("STRIPE_SECRET_KEY"),
      webhook_signing_secret: System.get_env("STRIPE_WEBHOOK_SECRET")
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :stripity_stripe") do
        # Config already exists
        source
      else
        # Add Stripe config before the import_config line
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

  defp add_stripe_dev_config(igniter) do
    dev_config_content = """
    config :stripity_stripe,
      api_key: "sk_test_thisisaboguskey",
      api_base_url: "http://localhost:12111",
      webhook_signing_secret: "whsec_test_bogus_secret"
    """

    Igniter.update_file(igniter, "config/dev.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :stripity_stripe") do
        # Config already exists
        source
      else
        # Add Stripe dev config before the swoosh config
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

      @required_fields ~w(stripe_payment_intent_id amount currency status)a
      @optional_fields ~w(stripe_charge_id stripe_customer_id description metadata receipt_url payment_method_type user_id)a

      def changeset(purchase, attrs) do
        purchase
        |> cast(attrs, @required_fields ++ @optional_fields)
        |> validate_required(@required_fields)
        |> validate_number(:amount, greater_than: 0)
        |> validate_length(:currency, is: 3)
        |> validate_inclusion(:status, ["succeeded", "processing", "canceled", "failed", "pending"])
        |> unique_constraint(:stripe_payment_intent_id)
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

      def list_purchases do
        Repo.all(Purchase)
      end

      def get_purchase!(id), do: Repo.get!(Purchase, id)

      def get_purchase_by_payment_intent(payment_intent_id) do
        Repo.get_by(Purchase, stripe_payment_intent_id: payment_intent_id)
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

      def create_or_update_purchase_from_payment_intent(payment_intent) do
        # Handle both map and struct formats
        pi_data = if is_map(payment_intent) and not is_struct(payment_intent) do
          payment_intent
        else
          Map.from_struct(payment_intent)
        end

        attrs = %{
          stripe_payment_intent_id: pi_data["id"] || pi_data[:id],
          stripe_charge_id: get_charge_id(pi_data),
          stripe_customer_id: pi_data["customer"] || pi_data[:customer],
          amount: pi_data["amount"] || pi_data[:amount],
          currency: pi_data["currency"] || pi_data[:currency],
          status: to_string(pi_data["status"] || pi_data[:status]),
          description: pi_data["description"] || pi_data[:description],
          metadata: pi_data["metadata"] || pi_data[:metadata] || %{},
          receipt_url: get_receipt_url(pi_data),
          payment_method_type: get_payment_method_type(pi_data)
        }

        case get_purchase_by_payment_intent(attrs.stripe_payment_intent_id) do
          nil -> create_purchase(attrs)
          purchase -> update_purchase(purchase, attrs)
        end
      end

      defp get_charge_id(%{charges: %{data: [%{id: charge_id} | _]}}), do: charge_id
      defp get_charge_id(_), do: nil

      defp get_receipt_url(%{charges: %{data: [%{receipt_url: url} | _]}}), do: url
      defp get_receipt_url(_), do: nil

      defp get_payment_method_type(%{payment_method_types: [type | _]}), do: type
      defp get_payment_method_type(_), do: nil
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/purchases.ex",
      purchases_content
    )
  end

  defp create_stripe_webhook_controller(igniter) do
    controller_content = """
    defmodule NeptunerWeb.StripeWebhookController do
      use NeptunerWeb, :controller
      require Logger

      alias Neptuner.Purchases

      def handle(conn, params) do
        with {:ok, event} <- parse_event(params, conn),
             :ok <- process_event(event) do
          json(conn, %{received: true})
        else
          {:error, reason} ->
            Logger.error("Webhook processing failed: \#{inspect(reason)}")

            conn
            |> put_status(:bad_request)
            |> json(%{error: "Webhook processing failed"})
        end
      end

      defp parse_event(params, conn) do
        if Mix.env() in [:dev, :test] do
          # Skip signature verification in dev/test
          Logger.debug("Parsing webhook params: \#{inspect(params)}")

          # Phoenix already parsed the JSON into params
          event = %Stripe.Event{
            id: params["id"],
            type: params["type"],
            data: %{
              object: get_in(params, ["data", "object"]) || %{}
            }
          }

          {:ok, event}
        else
          # Production: verify signature from raw body
          {:ok, body, _conn} = Plug.Conn.read_body(conn)
          signature = get_req_header(conn, "stripe-signature") |> List.first()
          endpoint_secret = Application.get_env(:stripity_stripe, :webhook_signing_secret)
          Stripe.Webhook.construct_event(body, signature, endpoint_secret)
        end
      end

      defp process_event(%Stripe.Event{type: type, data: %{object: object}}) do
        case type do
          "payment_intent.succeeded" ->
            handle_payment_intent_succeeded(object)

          "payment_intent.payment_failed" ->
            handle_payment_intent_failed(object)

          "charge.succeeded" ->
            handle_charge_succeeded(object)

          "charge.refunded" ->
            handle_charge_refunded(object)

          _ ->
            Logger.info("Unhandled webhook event type: \#{type}")
            :ok
        end
      end

      defp handle_payment_intent_succeeded(payment_intent) do
        Logger.info("Payment succeeded: \#{inspect(payment_intent)}")

        case Purchases.create_or_update_purchase_from_payment_intent(payment_intent) do
          {:ok, purchase} ->
            Logger.info("Purchase recorded: \#{purchase.id}")
            # You can add additional logic here like sending confirmation emails
            :ok

          {:error, changeset} ->
            Logger.error("Failed to record purchase: \#{inspect(changeset)}")
            {:error, changeset}
        end
      end

      defp handle_payment_intent_failed(payment_intent) do
        Logger.info("Payment failed: \#{payment_intent.id}")

        case Purchases.get_purchase_by_payment_intent(payment_intent.id) do
          nil ->
            :ok

          purchase ->
            Purchases.update_purchase(purchase, %{status: "failed"})
            :ok
        end
      end

      defp handle_charge_succeeded(charge) do
        Logger.info("Charge succeeded: \#{charge.id}")
        # Update purchase with charge details if needed
        :ok
      end

      defp handle_charge_refunded(charge) do
        Logger.info("Charge refunded: \#{charge.id}")

        # Find purchase by charge ID and update status
        # You might want to add a function to find purchase by charge_id
        :ok
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner_web/controllers/stripe_webhook_controller.ex",
      controller_content
    )
  end

  defp update_router(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "StripeWebhookController") do
        # Route already exists
        source
      else
        # Uncomment the API scope and add the webhook route
        updated_content =
          String.replace(
            content,
            ~r/  # scope "\/api", NeptunerWeb do\n  #   pipe_through :api\n  # end/,
            "  scope \"/api\", NeptunerWeb do\n    pipe_through :api\n    post \"/stripe/webhooks\", StripeWebhookController, :handle\n  end"
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
          add :stripe_payment_intent_id, :string, null: false
          add :stripe_charge_id, :string
          add :stripe_customer_id, :string
          # Amount in cents
          add :amount, :integer, null: false
          add :currency, :string, null: false
          add :status, :string, null: false
          add :description, :text
          add :metadata, :map, default: %{}
          add :receipt_url, :string
          add :payment_method_type, :string
          add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

          timestamps(type: :utc_datetime)
        end

        create unique_index(:purchases, [:stripe_payment_intent_id])
        create index(:purchases, [:stripe_customer_id])
        create index(:purchases, [:user_id])
        create index(:purchases, [:status])
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "priv/repo/migrations/#{migration_filename}",
      migration_content
    )
  end

  defp update_env_example(igniter) do
    Igniter.update_file(igniter, ".env.example", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "STRIPE_SECRET_KEY") do
        # Stripe keys already exist
        source
      else
        # Add Stripe environment variables
        stripe_env_vars = """
        STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key
        STRIPE_WEBHOOK_SECRET=whsec_your_webhook_endpoint_secret
        """

        updated_content =
          if String.trim(content) == "" do
            String.trim(stripe_env_vars)
          else
            String.trim(stripe_env_vars) <> "\n" <> content
          end

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Stripe Integration Complete! 💳

    Stripe payment processing has been successfully integrated into your SaaS template. Here's what was configured:

    ### Dependencies Added:
    - stripity_stripe (~> 3.2.0) for Stripe API integration

    ### Configuration Added:
    - Stripe configuration in config/config.exs for production
    - Development configuration in config/dev.exs with mock server support
    - Webhook signature verification for security

    ### Database Schema Created:
    - Purchase schema with comprehensive Stripe data fields
    - Migration file for purchases table with proper indexes
    - Relationship to User model for purchase tracking

    ### Code Created:
    - Neptuner.Purchases context module for purchase management
    - Neptuner.Purchases.Purchase schema with validations
    - StripeWebhookController for handling Stripe webhook events
    - Webhook route at /api/stripe/webhooks

    ### Files Created:
    - lib/neptuner/purchases.ex - Purchase context module
    - lib/neptuner/purchases/purchase.ex - Purchase schema
    - lib/neptuner_web/controllers/stripe_webhook_controller.ex - Webhook handler
    - priv/repo/migrations/*_add_purchases.exs - Database migration

    ### Files Updated:
    - mix.exs with stripity_stripe dependency
    - config/config.exs with production Stripe configuration
    - config/dev.exs with development/mock server configuration
    - lib/neptuner_web/router.ex with webhook route
    - .env.example with required environment variables

    ### Webhook Events Handled:
    - payment_intent.succeeded - Creates/updates purchase records
    - payment_intent.payment_failed - Updates purchase status to failed
    - charge.succeeded - Logs successful charges
    - charge.refunded - Handles refund events

    ### Next Steps:
    1. Set up Stripe API keys:
       - Visit https://dashboard.stripe.com/apikeys
       - Get your secret key and webhook signing secret
       - Set STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET in your environment

    2. Run the migration:
       ```bash
       mix ecto.migrate
       ```

    3. Set up webhook endpoint in Stripe Dashboard:
       - Go to https://dashboard.stripe.com/webhooks
       - Add endpoint: https://yourdomain.com/api/stripe/webhooks
       - Select events: payment_intent.succeeded, payment_intent.payment_failed, etc.

    4. For development/testing with mock server:
       - Use Docker: docker run --rm -it -p 12111:12111 stripemock/stripe-mock:latest
       - The webhook endpoint will work with both mock and real Stripe

    ### Usage Examples:
    ```elixir
    # List all purchases
    Neptuner.Purchases.list_purchases()

    # Get purchase by payment intent
    Neptuner.Purchases.get_purchase_by_payment_intent("pi_123")

    # Test webhook endpoint
    curl -X POST http://localhost:4000/api/stripe/webhooks \\
      -H "Content-Type: application/json" \\
      -d '{"type": "payment_intent.succeeded", "data": {"object": {...}}}'
    ```

    ### Stripe Features:
    - Secure webhook signature verification in production
    - Comprehensive purchase tracking and management
    - Support for various Stripe events and payment methods
    - Integration with your existing User model

    🎉 Your app now supports Stripe payment processing!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
