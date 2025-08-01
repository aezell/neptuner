defmodule Neptuner.Repo.Migrations.CreateWebhookSubscriptions do
  use Ecto.Migration

  def change do
    create table(:webhook_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_id,
          references(:service_connections, type: :binary_id, on_delete: :delete_all),
          null: false

      add :provider_webhook_id, :string, null: false
      add :webhook_type, :string, null: false
      add :webhook_url, :text
      add :is_active, :boolean, default: true, null: false
      add :expires_at, :utc_datetime
      add :last_notification_at, :utc_datetime
      add :notification_count, :integer, default: 0, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:webhook_subscriptions, [:provider_webhook_id])
    create index(:webhook_subscriptions, [:connection_id])
    create index(:webhook_subscriptions, [:webhook_type])
    create index(:webhook_subscriptions, [:is_active])
    create index(:webhook_subscriptions, [:expires_at])
  end
end
