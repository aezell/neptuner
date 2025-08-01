defmodule Neptuner.PurchasesTest do
  use Neptuner.DataCase
  alias Neptuner.Purchases

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
      updated_data = %{
        order_data
        | "status" => "refunded",
          "refunded" => true,
          "refunded_amount" => order_data["total"]
      }

      # Update the purchase
      assert {:ok, updated_purchase} =
               Purchases.create_or_update_purchase_from_order(updated_data)

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
