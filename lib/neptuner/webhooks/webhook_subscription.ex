defmodule Neptuner.Webhooks.WebhookSubscription do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Connections.ServiceConnection

  schema "webhook_subscriptions" do
    field :provider_webhook_id, :string

    field :webhook_type, Ecto.Enum,
      values: [:google_calendar, :gmail_push, :microsoft_calendar, :microsoft_email]

    field :webhook_url, :string
    field :is_active, :boolean, default: true
    field :expires_at, :utc_datetime
    field :last_notification_at, :utc_datetime
    field :notification_count, :integer, default: 0
    field :metadata, :map, default: %{}

    belongs_to :connection, ServiceConnection

    timestamps(type: :utc_datetime)
  end

  def changeset(webhook_subscription, attrs) do
    webhook_subscription
    |> cast(attrs, [
      :connection_id,
      :provider_webhook_id,
      :webhook_type,
      :webhook_url,
      :is_active,
      :expires_at,
      :last_notification_at,
      :notification_count,
      :metadata
    ])
    |> validate_required([:connection_id, :provider_webhook_id, :webhook_type])
    |> validate_length(:provider_webhook_id, max: 255)
    |> validate_length(:webhook_url, max: 2048)
    |> unique_constraint(:provider_webhook_id)
    |> foreign_key_constraint(:connection_id)
  end

  def increment_notification_count(webhook_subscription) do
    webhook_subscription
    |> change(%{
      notification_count: webhook_subscription.notification_count + 1,
      last_notification_at: DateTime.utc_now()
    })
  end

  def is_expired?(%__MODULE__{expires_at: nil}), do: false

  def is_expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  def needs_renewal?(%__MODULE__{expires_at: nil}), do: false

  def needs_renewal?(%__MODULE__{expires_at: expires_at}) do
    # Renew webhooks when they have less than 1 day remaining
    renewal_threshold = DateTime.add(DateTime.utc_now(), 1, :day)
    DateTime.compare(expires_at, renewal_threshold) == :lt
  end
end
