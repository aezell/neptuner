defmodule Neptuner.Connections.ServiceConnection do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User
  alias Neptuner.Calendar.Meeting

  schema "service_connections" do
    field :provider, Ecto.Enum, values: [:google, :microsoft, :apple, :caldav]
    field :service_type, Ecto.Enum, values: [:calendar, :email, :tasks]
    field :external_account_id, :string
    field :external_account_email, :string
    field :display_name, :string
    field :access_token, :binary
    field :refresh_token, :binary
    field :token_expires_at, :utc_datetime
    field :last_sync_at, :utc_datetime
    field :sync_enabled, :boolean, default: true

    field :connection_status, Ecto.Enum,
      values: [:active, :expired, :error, :disconnected],
      default: :active

    field :scopes_granted, {:array, :string}, default: []

    belongs_to :user, User
    has_many :meetings, Meeting, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def changeset(service_connection, attrs) do
    service_connection
    |> cast(attrs, [
      :provider,
      :service_type,
      :external_account_id,
      :external_account_email,
      :display_name,
      :access_token,
      :refresh_token,
      :token_expires_at,
      :last_sync_at,
      :sync_enabled,
      :connection_status,
      :scopes_granted
    ])
    |> validate_required([:provider, :service_type])
    |> validate_length(:display_name, max: 255)
    |> validate_length(:external_account_email, max: 255)
    |> validate_format(:external_account_email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must be a valid email"
    )
  end

  def token_expired?(%__MODULE__{token_expires_at: nil}), do: false

  def token_expired?(%__MODULE__{token_expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  def needs_refresh?(%__MODULE__{} = connection) do
    token_expired?(connection) or connection.connection_status == :expired
  end

  def provider_display_name(:google), do: "Google"
  def provider_display_name(:microsoft), do: "Microsoft"
  def provider_display_name(:apple), do: "Apple"
  def provider_display_name(:caldav), do: "CalDAV"

  def service_type_display_name(:calendar), do: "Calendar"
  def service_type_display_name(:email), do: "Email"
  def service_type_display_name(:tasks), do: "Tasks"
end
