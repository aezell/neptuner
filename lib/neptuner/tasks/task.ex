defmodule Neptuner.Tasks.Task do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User

  schema "tasks" do
    field :title, :string
    field :description, :string

    field :cosmic_priority, Ecto.Enum,
      values: [:matters_10_years, :matters_10_days, :matters_to_nobody],
      default: :matters_to_nobody

    field :status, Ecto.Enum, values: [:pending, :completed, :abandoned_wisely], default: :pending
    field :estimated_actual_importance, :integer, default: 1
    field :completed_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :cosmic_priority,
      :status,
      :estimated_actual_importance,
      :completed_at
    ])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:estimated_actual_importance, 1..10)
    |> maybe_set_completed_at()
  end

  defp maybe_set_completed_at(changeset) do
    status = get_change(changeset, :status)

    case status do
      :completed ->
        put_change(changeset, :completed_at, DateTime.utc_now(:second))

      :pending ->
        put_change(changeset, :completed_at, nil)

      :abandoned_wisely ->
        put_change(changeset, :completed_at, DateTime.utc_now(:second))

      _ ->
        changeset
    end
  end

  def cosmic_priority_description(:matters_10_years),
    do: "Genuinely important life decisions, relationships, health choices"

  def cosmic_priority_description(:matters_10_days),
    do: "Legitimate short-term concerns with real consequences"

  def cosmic_priority_description(:matters_to_nobody),
    do: "Digital busy work that exists because we forgot how to be idle"
end
