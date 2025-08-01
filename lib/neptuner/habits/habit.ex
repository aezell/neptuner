defmodule Neptuner.Habits.Habit do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User
  alias Neptuner.Habits.HabitEntry

  schema "habits" do
    field :name, :string
    field :description, :string
    field :current_streak, :integer, default: 0
    field :longest_streak, :integer, default: 0

    field :habit_type, Ecto.Enum,
      values: [:basic_human_function, :self_improvement_theater, :actually_useful],
      default: :self_improvement_theater

    belongs_to :user, User
    has_many :habit_entries, HabitEntry, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def changeset(habit, attrs) do
    habit
    |> cast(attrs, [:name, :description, :habit_type, :current_streak, :longest_streak])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> validate_number(:current_streak, greater_than_or_equal_to: 0)
    |> validate_number(:longest_streak, greater_than_or_equal_to: 0)
    |> ensure_longest_streak_consistency()
  end

  defp ensure_longest_streak_consistency(changeset) do
    current_streak = get_field(changeset, :current_streak, 0)
    longest_streak = get_field(changeset, :longest_streak, 0)

    if current_streak > longest_streak do
      put_change(changeset, :longest_streak, current_streak)
    else
      changeset
    end
  end

  def habit_type_description(:basic_human_function),
    do: "Essential activities that keep you alive and functional"

  def habit_type_description(:self_improvement_theater),
    do: "Activities that feel productive but mostly exist to make you feel better about yourself"

  def habit_type_description(:actually_useful),
    do: "Genuinely beneficial practices with measurable positive impact"
end
