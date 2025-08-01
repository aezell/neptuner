defmodule Neptuner.Habits.HabitEntry do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Habits.Habit

  schema "habit_entries" do
    field :completed_on, :date
    field :existential_commentary, :string

    belongs_to :habit, Habit

    timestamps(type: :utc_datetime)
  end

  def changeset(habit_entry, attrs) do
    habit_entry
    |> cast(attrs, [:completed_on, :existential_commentary])
    |> validate_required([:completed_on])
    |> unique_constraint([:habit_id, :completed_on])
    |> maybe_generate_commentary()
  end

  defp maybe_generate_commentary(changeset) do
    if get_change(changeset, :existential_commentary) == nil do
      put_change(changeset, :existential_commentary, generate_random_commentary())
    else
      changeset
    end
  end

  defp generate_random_commentary do
    commentaries = [
      "Another day of convincing yourself this routine matters in the grand scheme of things.",
      "The algorithm of self-improvement continues its relentless execution.",
      "Today's episode of 'Humans Performing Optimality Theater' is now complete.",
      "Successfully maintained the illusion of progress through repetitive behavior.",
      "The habit has been acknowledged by the universe, which remains indifferent.",
      "Another data point in the infinite spreadsheet of personal optimization.",
      "The machine of habit completion churns on, indifferent to cosmic significance.",
      "Today's ritual of self-imposed discipline has been ceremonially observed.",
      "The daily demonstration that free will and determination can coexist with absurdity.",
      "Another brick in the endless wall of 'becoming the person you want to be.'"
    ]

    Enum.random(commentaries)
  end
end
