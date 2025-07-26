defmodule Neptuner.Waitlist.Entry do
  @moduledoc """
  Waitlist entry schema for collecting potential user information.
  """
  use Neptuner.Schema

  schema "waitlist_entries" do
    field :email, :string
    field :name, :string
    field :company, :string
    field :role, :string
    field :use_case, :string
    field :subscribed_at, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:email, :name, :company, :role, :use_case])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:name, max: 80)
    |> validate_length(:company, max: 100)
    |> validate_length(:role, max: 50)
    |> validate_length(:use_case, max: 500)
    |> unique_constraint(:email)
    |> put_subscribed_at()
  end

  defp put_subscribed_at(changeset) do
    if changeset.valid? and get_field(changeset, :subscribed_at) == nil do
      put_change(
        changeset,
        :subscribed_at,
        NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      )
    else
      changeset
    end
  end
end
