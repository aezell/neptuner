defmodule Neptuner.Repo.Migrations.CreateOrganisationInvitations do
  use Ecto.Migration

  def change do
    create table(:organisation_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :role, :string, null: false, default: "member"
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :accepted_at, :utc_datetime

      add :organisation_id, references(:organisations, on_delete: :delete_all, type: :binary_id),
        null: false

      add :invited_by_id, references(:users, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisation_invitations, [:token])
    create unique_index(:organisation_invitations, [:email, :organisation_id])
    create index(:organisation_invitations, [:organisation_id])
    create index(:organisation_invitations, [:invited_by_id])
    create index(:organisation_invitations, [:expires_at])
  end
end
