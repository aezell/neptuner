defmodule Neptuner.Repo.Migrations.CreateWaitlistEntries do
  use Ecto.Migration

  def change do
    create table(:waitlist_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :name, :string
      add :company, :string
      add :role, :string
      add :use_case, :text
      add :subscribed_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:waitlist_entries, [:email])
    create index(:waitlist_entries, [:subscribed_at])
  end
end
