defmodule Neptuner.Habits do
  @moduledoc """
  The Habits context.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo

  alias Neptuner.Habits.{Habit, HabitEntry}

  # Habits

  def list_habits(user_id) do
    Habit
    |> where([h], h.user_id == ^user_id)
    |> order_by([h], desc: h.inserted_at)
    |> Repo.all()
  end

  def get_habit!(id), do: Repo.get!(Habit, id)

  def get_user_habit!(user_id, id) do
    Habit
    |> where([h], h.user_id == ^user_id and h.id == ^id)
    |> Repo.one!()
  end

  def create_habit(user_id, attrs \\ %{}) do
    %Habit{}
    |> Habit.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Repo.insert()
  end

  # Alias for import compatibility
  def create_user_habit(user_id, attrs), do: create_habit(user_id, attrs)

  def update_habit(%Habit{} = habit, attrs) do
    habit
    |> Habit.changeset(attrs)
    |> Repo.update()
  end

  def delete_habit(%Habit{} = habit) do
    Repo.delete(habit)
  end

  def change_habit(%Habit{} = habit, attrs \\ %{}) do
    Habit.changeset(habit, attrs)
  end

  # Habit Entries

  def list_habit_entries(habit_id) do
    HabitEntry
    |> where([he], he.habit_id == ^habit_id)
    |> order_by([he], desc: he.completed_on)
    |> Repo.all()
  end

  def get_habit_entry!(id), do: Repo.get!(HabitEntry, id)

  def create_habit_entry(habit_id, attrs \\ %{}) do
    %HabitEntry{}
    |> HabitEntry.changeset(attrs)
    |> Ecto.Changeset.put_change(:habit_id, habit_id)
    |> Repo.insert()
    |> case do
      {:ok, entry} ->
        update_habit_streaks(habit_id)
        {:ok, entry}

      error ->
        error
    end
  end

  def update_habit_entry(%HabitEntry{} = habit_entry, attrs) do
    habit_entry
    |> HabitEntry.changeset(attrs)
    |> Repo.update()
  end

  def delete_habit_entry(%HabitEntry{} = habit_entry) do
    result = Repo.delete(habit_entry)
    update_habit_streaks(habit_entry.habit_id)
    result
  end

  def change_habit_entry(%HabitEntry{} = habit_entry, attrs \\ %{}) do
    HabitEntry.changeset(habit_entry, attrs)
  end

  def check_in_habit(habit_id, date \\ Date.utc_today()) do
    create_habit_entry(habit_id, %{completed_on: date})
  end

  defp update_habit_streaks(habit_id) do
    habit = get_habit!(habit_id)

    entries =
      HabitEntry
      |> where([he], he.habit_id == ^habit_id)
      |> order_by([he], desc: he.completed_on)
      |> Repo.all()

    current_streak = calculate_current_streak(entries)
    longest_streak = calculate_longest_streak(entries)

    update_habit(habit, %{
      current_streak: current_streak,
      longest_streak: max(longest_streak, habit.longest_streak)
    })
  end

  defp calculate_current_streak(entries) do
    today = Date.utc_today()

    entries
    |> Enum.reduce_while(0, fn entry, streak ->
      expected_date = Date.add(today, -streak)

      if Date.compare(entry.completed_on, expected_date) == :eq do
        {:cont, streak + 1}
      else
        {:halt, streak}
      end
    end)
  end

  defp calculate_longest_streak(entries) do
    entries
    |> Enum.map(& &1.completed_on)
    |> Enum.sort(Date)
    |> Enum.chunk_while([], &chunk_consecutive_dates/2, &after_chunk/1)
    |> Enum.map(&length/1)
    |> Enum.max(fn -> 0 end)
  end

  defp chunk_consecutive_dates(date, []) do
    {:cont, [date]}
  end

  defp chunk_consecutive_dates(date, [last_date | _] = acc) do
    if Date.diff(date, last_date) == 1 do
      {:cont, [date | acc]}
    else
      {:cont, Enum.reverse(acc), [date]}
    end
  end

  defp after_chunk([]), do: {:cont, []}
  defp after_chunk(acc), do: {:cont, Enum.reverse(acc), []}

  def get_habit_statistics(user_id) do
    habits = list_habits(user_id)

    %{
      total_habits: length(habits),
      active_streaks: Enum.count(habits, &(&1.current_streak > 0)),
      total_current_streak: Enum.sum(Enum.map(habits, & &1.current_streak)),
      longest_overall_streak: Enum.max(Enum.map(habits, & &1.longest_streak), fn -> 0 end),
      basic_human_functions: Enum.count(habits, &(&1.habit_type == :basic_human_function)),
      self_improvement_theater: Enum.count(habits, &(&1.habit_type == :self_improvement_theater)),
      actually_useful: Enum.count(habits, &(&1.habit_type == :actually_useful))
    }
  end

  def get_habit_tracking_for_range(habit_id, start_date, end_date) do
    HabitEntry
    |> where([he], he.habit_id == ^habit_id)
    |> where([he], he.completed_on >= ^start_date and he.completed_on <= ^end_date)
    |> order_by([he], asc: he.completed_on)
    |> Repo.all()
  end

  def get_user_habit_stats_for_range(user_id, start_date, end_date) do
    habits = list_habits(user_id)

    Enum.map(habits, fn habit ->
      entries = get_habit_tracking_for_range(habit.id, start_date, end_date)

      completion_rate =
        if habit.frequency == :daily do
          total_days = Date.diff(end_date, start_date) + 1
          if total_days > 0, do: length(entries) / total_days * 100, else: 0
        else
          # For weekly/monthly, use a simpler calculation
          # Rough completion score
          length(entries) * 10
        end

      %{
        habit: habit,
        entries_count: length(entries),
        completion_rate: completion_rate,
        entries: entries
      }
    end)
  end
end
