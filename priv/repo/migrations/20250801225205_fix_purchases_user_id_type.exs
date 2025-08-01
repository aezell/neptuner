defmodule Neptuner.Repo.Migrations.FixPurchasesUserIdType do
  use Ecto.Migration

  def change do
    # Drop existing foreign key constraint and index
    drop constraint(:purchases, "purchases_user_id_fkey")
    drop index(:purchases, [:user_id])

    # Change column type from integer to binary_id (UUID)
    alter table(:purchases) do
      modify :user_id, :binary_id
    end

    # Recreate foreign key constraint and index
    alter table(:purchases) do
      modify :user_id, references(:users, on_delete: :nothing, type: :binary_id)
    end

    create index(:purchases, [:user_id])
  end
end
