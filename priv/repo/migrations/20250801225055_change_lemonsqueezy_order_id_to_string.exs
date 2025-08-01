defmodule Neptuner.Repo.Migrations.ChangeLemonsqueezyOrderIdToString do
  use Ecto.Migration

  def change do
    # Drop existing unique index
    drop unique_index(:purchases, [:lemonsqueezy_order_id])

    # Change column type from integer to string
    alter table(:purchases) do
      modify :lemonsqueezy_order_id, :string, null: false
    end

    # Recreate unique index
    create unique_index(:purchases, [:lemonsqueezy_order_id])
  end
end
