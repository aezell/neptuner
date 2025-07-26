defmodule Neptuner.Repo.Migrations.CreateOrganisationsAndMembers do
  use Ecto.Migration

  def change do
    create table(:organisations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisations, [:name])

    create table(:organisation_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string, null: false, default: "member"
      add :joined_at, :utc_datetime, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      add :organisation_id, references(:organisations, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisation_members, [:user_id, :organisation_id])
    create index(:organisation_members, [:user_id])
    create index(:organisation_members, [:organisation_id])
  end
end
