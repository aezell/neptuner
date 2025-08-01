defmodule Neptuner.Repo.Migrations.CreateServiceConnections do
  use Ecto.Migration

  def change do
    create table(:service_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :provider, :string, null: false
      add :service_type, :string, null: false
      add :external_account_id, :string
      add :external_account_email, :string
      add :display_name, :string
      add :access_token, :binary
      add :refresh_token, :binary
      add :token_expires_at, :utc_datetime
      add :last_sync_at, :utc_datetime
      add :sync_enabled, :boolean, default: true
      add :connection_status, :string, default: "active"
      add :scopes_granted, {:array, :string}, default: []
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:service_connections, [:user_id])
    create index(:service_connections, [:provider])
    create index(:service_connections, [:service_type])
    create index(:service_connections, [:connection_status])
    create index(:service_connections, [:user_id, :provider, :service_type])

    create constraint(:service_connections, :provider_check,
             check: "provider IN ('google', 'microsoft', 'apple', 'caldav')"
           )

    create constraint(:service_connections, :service_type_check,
             check: "service_type IN ('calendar', 'email', 'tasks')"
           )

    create constraint(:service_connections, :connection_status_check,
             check: "connection_status IN ('active', 'expired', 'error', 'disconnected')"
           )
  end
end
