defmodule Neptuner.Organisations.Organisation do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User
  alias Neptuner.Organisations.OrganisationMember

  schema "organisations" do
    field :name, :string

    has_many :organisation_members, OrganisationMember
    many_to_many :users, User, join_through: OrganisationMember

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
  end
end
