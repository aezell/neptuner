defmodule Neptuner.Repo.Migrations.AddSubscriptionTierToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :subscription_tier, :string, default: "free", null: false
      add :subscription_status, :string, default: "active", null: false
      add :subscription_expires_at, :utc_datetime
      add :lemonsqueezy_customer_id, :string
      add :subscription_features, :map, default: %{}
    end

    create index(:users, [:subscription_tier])
    create index(:users, [:subscription_status])
    create index(:users, [:lemonsqueezy_customer_id])
  end
end
