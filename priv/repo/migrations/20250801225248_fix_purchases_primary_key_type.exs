defmodule Neptuner.Repo.Migrations.FixPurchasesPrimaryKeyType do
  use Ecto.Migration

  def up do
    # Drop existing table and recreate with correct primary key type
    drop table(:purchases)

    create table(:purchases, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # LemonSqueezy Order identifiers
      add :lemonsqueezy_order_id, :string, null: false
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

    # Recreate indexes
    create unique_index(:purchases, [:lemonsqueezy_order_id])
    create unique_index(:purchases, [:order_identifier])
    create index(:purchases, [:lemonsqueezy_customer_id])
    create index(:purchases, [:user_id])
    create index(:purchases, [:status])
    create index(:purchases, [:user_email])
    create index(:purchases, [:test_mode])
    create index(:purchases, [:refunded])
  end

  def down do
    # This is a destructive migration - can't easily reverse
    raise "This migration cannot be reversed"
  end
end
