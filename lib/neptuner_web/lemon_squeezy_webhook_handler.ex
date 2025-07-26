defmodule NeptunerWeb.LemonSqueezyWebhookHandler do
  alias Neptuner.Purchases
  require Logger

  @behaviour LemonEx.Webhooks.Handler

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "order_created"} = event) do
    Logger.info("LemonSqueezy order created: #{inspect(event.data["id"])}")

    case Purchases.create_or_update_purchase_from_order(event.data) do
      {:ok, purchase} ->
        Logger.info("Purchase created/updated: #{purchase.id}")
        :ok

      {:error, changeset} ->
        Logger.error("Failed to create/update purchase: #{inspect(changeset.errors)}")
        {:error, "Failed to process order_created event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "order_refunded"} = event) do
    Logger.info("LemonSqueezy order refunded: #{inspect(event.data["id"])}")

    case Purchases.create_or_update_purchase_from_order(event.data) do
      {:ok, purchase} ->
        Logger.info("Purchase refund processed: #{purchase.id}")
        :ok

      {:error, changeset} ->
        Logger.error("Failed to process refund: #{inspect(changeset.errors)}")
        {:error, "Failed to process order_refunded event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_created"} = event) do
    Logger.info("LemonSqueezy subscription created: #{inspect(event.data["id"])}")

    case Purchases.update_subscription(event) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to handle subscription_created: #{inspect(reason)}")
        {:error, "Failed to process subscription_created event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_updated"} = event) do
    Logger.info("LemonSqueezy subscription updated: #{inspect(event.data["id"])}")

    case Purchases.update_subscription(event) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to handle subscription_updated: #{inspect(reason)}")
        {:error, "Failed to process subscription_updated event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_payment_success"} = event) do
    Logger.info("LemonSqueezy subscription payment success: #{inspect(event.data["id"])}")

    case Purchases.update_subscription(event) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to handle subscription_payment_success: #{inspect(reason)}")
        {:error, "Failed to process subscription_payment_success event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_payment_failed"} = event) do
    Logger.info("LemonSqueezy subscription payment failed: #{inspect(event.data["id"])}")

    case Purchases.update_subscription(event) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to handle subscription_payment_failed: #{inspect(reason)}")
        {:error, "Failed to process subscription_payment_failed event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_payment_recovered"} = event) do
    Logger.info("LemonSqueezy subscription payment recovered: #{inspect(event.data["id"])}")

    case Purchases.update_subscription(event) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to handle subscription_payment_recovered: #{inspect(reason)}")
        {:error, "Failed to process subscription_payment_recovered event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_cancelled"} = event) do
    Logger.info("LemonSqueezy subscription cancelled: #{inspect(event.data["id"])}")

    Purchases.cancel_subscription(event)
    :ok
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_resumed"} = event) do
    Logger.info("LemonSqueezy subscription resumed: #{inspect(event.data["id"])}")

    case Purchases.update_subscription(event) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to handle subscription_resumed: #{inspect(reason)}")
        {:error, "Failed to process subscription_resumed event"}
    end
  end

  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: "subscription_expired"} = event) do
    Logger.info("LemonSqueezy subscription expired: #{inspect(event.data["id"])}")

    Purchases.cancel_subscription(event)
    :ok
  end

  # You need to handle all incoming events. So, better have a
  # catch-all handler for events that you don't want to handle,
  # but only want to acknowledge.
  @impl true
  def handle_event(%LemonEx.Webhooks.Event{name: event_name} = event) do
    Logger.info("Unhandled LemonSqueezy event: #{event_name}")
    Logger.debug("Event data: #{inspect(event)}")
    :ok
  end

  def handle_event(unhandled_event) do
    Logger.warning("Received unexpected event format: #{inspect(unhandled_event)}")
    :ok
  end
end
