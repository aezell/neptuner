defmodule NeptunerWeb.LemonSqueezyWebhookHandlerTest do
  use Neptuner.DataCase
  alias NeptunerWeb.LemonSqueezyWebhookHandler
  alias Neptuner.Purchases
  import Neptuner.Factory

  describe "webhook handler" do
    @tag :skip
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

    @tag :skip
    test "handles order_refunded event" do
      # First create an order
      create_event = build(:lemonsqueezy_webhook_event)
      assert :ok = LemonSqueezyWebhookHandler.handle_event(create_event)

      # Now refund it
      refund_event =
        build(:refunded_webhook_event,
          data: %{
            create_event.data
            | "status" => "refunded",
              "refunded" => true,
              "refunded_amount" => create_event.data["total"]
          }
        )

      assert :ok = LemonSqueezyWebhookHandler.handle_event(refund_event)

      # Verify purchase was updated
      purchase = Purchases.get_purchase_by_lemonsqueezy_order_id(create_event.data["id"])
      assert purchase.status == "refunded"
      assert purchase.refunded == true
      assert purchase.refunded_amount == create_event.data["total"]
    end

    @tag :skip
    test "handles subscription events" do
      event = build(:subscription_webhook_event)

      assert :ok = LemonSqueezyWebhookHandler.handle_event(event)
    end

    @tag :skip
    test "handles unrecognized events gracefully" do
      event = %LemonEx.Webhooks.Event{
        name: "unknown_event",
        data: %{},
        meta: %{}
      }

      assert :ok = LemonSqueezyWebhookHandler.handle_event(event)
    end

    @tag :skip
    test "handles malformed events gracefully" do
      assert :ok = LemonSqueezyWebhookHandler.handle_event(%{unexpected: "format"})
    end
  end
end
