defmodule Neptuner.Organisations.OrganisationMember do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User
  alias Neptuner.Organisations.Organisation

  schema "organisation_members" do
    field :role, :string, default: "member"
    field :joined_at, :utc_datetime

    belongs_to :user, User
    belongs_to :organisation, Organisation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organisation_member, attrs) do
    organisation_member
    |> cast(attrs, [:role, :joined_at, :user_id, :organisation_id])
    |> validate_required([:role, :user_id, :organisation_id])
    |> validate_inclusion(:role, ["member", "admin", "owner"])
    |> unique_constraint([:user_id, :organisation_id])
    |> put_joined_at()
  end

  defp put_joined_at(changeset) do
    if get_field(changeset, :joined_at) do
      changeset
    else
      put_change(changeset, :joined_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end
end
