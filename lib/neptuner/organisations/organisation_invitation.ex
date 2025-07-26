defmodule Neptuner.Organisations.OrganisationInvitation do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User
  alias Neptuner.Organisations.Organisation

  schema "organisation_invitations" do
    field :email, :string
    field :role, :string, default: "member"
    field :token, :string
    field :expires_at, :utc_datetime
    field :accepted_at, :utc_datetime

    belongs_to :organisation, Organisation
    belongs_to :invited_by, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organisation_invitation, attrs) do
    organisation_invitation
    |> cast(attrs, [:email, :role, :organisation_id, :invited_by_id])
    |> validate_required([:email, :role, :organisation_id, :invited_by_id])
    |> validate_inclusion(:role, ["member", "admin"])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> unique_constraint([:email, :organisation_id],
      message: "User has already been invited to this organisation"
    )
    |> put_token()
    |> put_expires_at()
  end

  defp put_token(changeset) do
    if get_field(changeset, :token) do
      changeset
    else
      put_change(changeset, :token, generate_token())
    end
  end

  defp put_expires_at(changeset) do
    if get_field(changeset, :expires_at) do
      changeset
    else
      # Invitations expire in 7 days
      expires_at = DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      put_change(changeset, :expires_at, expires_at)
    end
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  @doc """
  Checks if an invitation is still valid (not expired and not accepted).
  """
  def valid?(%__MODULE__{expires_at: expires_at, accepted_at: accepted_at}) do
    is_nil(accepted_at) and DateTime.after?(expires_at, DateTime.utc_now())
  end

  @doc """
  Marks an invitation as accepted.
  """
  def accept_changeset(invitation) do
    change(invitation, accepted_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
