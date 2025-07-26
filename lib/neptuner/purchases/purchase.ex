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
    |> validate_format(:user_email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> unique_constraint(:lemonsqueezy_order_id)
    |> unique_constraint(:order_identifier)
  end
end
