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

  def create_purchase(attrs \\ %{}) do
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
        Logger.info("Creating new purchase for LemonSqueezy order #{attrs.lemonsqueezy_order_id}")
        create_purchase(attrs)

      purchase ->
        Logger.info(
          "Updating existing purchase for LemonSqueezy order #{attrs.lemonsqueezy_order_id}"
        )

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
        Logger.info("Unhandled subscription event data: #{inspect(data)}")
        :ok
    end
  end

  def cancel_subscription(%LemonEx.Webhooks.Event{data: data}) do
    Logger.info("Subscription cancelled/expired: #{inspect(data)}")
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
    Logger.info("Handling subscription event: #{inspect(data)}")
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

  defp extract_custom_data(%{"first_order_item" => %{"custom_data" => data}}) when is_map(data),
    do: data

  defp extract_custom_data(_), do: %{}

  defp get_receipt_url(%{"urls" => %{"receipt" => url}}), do: url
  defp get_receipt_url(_), do: nil

  defp get_customer_portal_url(%{"urls" => %{"customer_portal" => url}}), do: url
  defp get_customer_portal_url(_), do: nil
end
