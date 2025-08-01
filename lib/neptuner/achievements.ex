defmodule Neptuner.Achievements do
  @moduledoc """
  The Achievements context - Achievement Deflation Engine for cosmic perspective on productivity.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo

  alias Neptuner.Achievements.Achievement
  alias Neptuner.Achievements.UserAchievement

  def list_achievements(opts \\ []) do
    category = Keyword.get(opts, :category)
    active_only = Keyword.get(opts, :active_only, true)

    base_query = Achievement

    query =
      base_query
      |> maybe_filter_by_category(category)
      |> maybe_filter_active(active_only)
      |> order_by([a], asc: a.category, asc: a.title)

    Repo.all(query)
  end

  defp maybe_filter_by_category(query, nil), do: query
  defp maybe_filter_by_category(query, category), do: where(query, [a], a.category == ^category)

  defp maybe_filter_active(query, false), do: query
  defp maybe_filter_active(query, true), do: where(query, [a], a.is_active == true)

  def get_achievement!(id), do: Repo.get!(Achievement, id)
  def get_achievement_by_key!(key), do: Repo.get_by!(Achievement, key: key)

  def create_achievement(attrs \\ %{}) do
    %Achievement{}
    |> Achievement.changeset(attrs)
    |> Repo.insert()
  end

  def update_achievement(%Achievement{} = achievement, attrs) do
    achievement
    |> Achievement.changeset(attrs)
    |> Repo.update()
  end

  def delete_achievement(%Achievement{} = achievement) do
    Repo.delete(achievement)
  end

  def list_user_achievements(user_id, opts \\ []) do
    category = Keyword.get(opts, :category)
    completed_only = Keyword.get(opts, :completed_only, false)
    include_achievement = Keyword.get(opts, :include_achievement, true)

    base_query =
      UserAchievement
      |> where([ua], ua.user_id == ^user_id)

    query =
      if include_achievement do
        base_query |> join(:inner, [ua], a in Achievement, on: ua.achievement_id == a.id)
      else
        base_query
      end

    query =
      if category do
        query |> where([ua, a], a.category == ^category)
      else
        query
      end

    query =
      if completed_only do
        query |> where([ua], not is_nil(ua.completed_at))
      else
        query
      end

    query =
      if include_achievement do
        query
        |> preload([ua, a], achievement: a)
        |> order_by([ua, a], desc: ua.completed_at, asc: a.category, asc: a.title)
      else
        query
        |> order_by([ua], desc: ua.completed_at)
      end

    Repo.all(query)
  end

  def get_user_achievement(user_id, achievement_id) do
    UserAchievement
    |> where([ua], ua.user_id == ^user_id and ua.achievement_id == ^achievement_id)
    |> preload(:achievement)
    |> Repo.one()
  end

  def get_user_achievement_by_key(user_id, achievement_key) do
    UserAchievement
    |> join(:inner, [ua], a in Achievement, on: ua.achievement_id == a.id)
    |> where([ua, a], ua.user_id == ^user_id and a.key == ^achievement_key)
    |> preload([ua, a], achievement: a)
    |> Repo.one()
  end

  def create_or_update_user_achievement(user_id, achievement_key, progress_value) do
    achievement = get_achievement_by_key!(achievement_key)

    case get_user_achievement_by_key(user_id, achievement_key) do
      nil ->
        completed_at =
          if progress_value >= (achievement.threshold_value || 1),
            do: DateTime.utc_now(),
            else: nil

        %UserAchievement{user_id: user_id, achievement_id: achievement.id}
        |> UserAchievement.changeset(%{
          progress_value: progress_value,
          completed_at: completed_at
        })
        |> Repo.insert()

      existing ->
        new_completed_at =
          if !existing.completed_at && progress_value >= (achievement.threshold_value || 1) do
            DateTime.utc_now()
          else
            existing.completed_at
          end

        existing
        |> UserAchievement.changeset(%{
          progress_value: progress_value,
          completed_at: new_completed_at
        })
        |> Repo.update()
    end
  end

  def mark_achievement_notified(user_id, achievement_key) do
    case get_user_achievement_by_key(user_id, achievement_key) do
      nil ->
        {:error, :not_found}

      user_achievement ->
        user_achievement
        |> UserAchievement.changeset(%{notified_at: DateTime.utc_now()})
        |> Repo.update()
    end
  end

  def check_achievements_for_user(user_id) do
    achievements_to_check = [
      {"task_beginner", fn -> count_completed_tasks(user_id) end},
      {"task_digital_rectangle_mover", fn -> count_completed_tasks(user_id) end},
      {"task_existential_warrior", fn -> count_completed_tasks(user_id) end},
      {"habit_basic_human", fn -> count_active_habits(user_id) end},
      {"habit_streak_survivor", fn -> get_longest_habit_streak(user_id) end},
      {"meeting_survivor", fn -> count_attended_meetings(user_id) end},
      {"meeting_archaeologist", fn -> count_useless_meetings(user_id) end},
      {"email_warrior", fn -> count_processed_emails(user_id) end},
      {"connection_integrator", fn -> count_active_connections(user_id) end}
    ]

    results =
      Enum.map(achievements_to_check, fn {key, value_fn} ->
        value = value_fn.()

        case create_or_update_user_achievement(user_id, key, value) do
          {:ok, user_achievement} ->
            if user_achievement.completed_at && !user_achievement.notified_at do
              {:completed, user_achievement}
            else
              {:updated, user_achievement}
            end

          {:error, _} ->
            {:error, key}
        end
      end)

    newly_completed =
      results
      |> Enum.filter(fn
        {:completed, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {:completed, ua} -> ua end)

    {:ok, newly_completed}
  end

  defp count_completed_tasks(user_id) do
    Neptuner.Tasks.Task
    |> where([t], t.user_id == ^user_id and t.status == :completed)
    |> Repo.aggregate(:count)
  end

  defp count_active_habits(user_id) do
    Neptuner.Habits.Habit
    |> where([h], h.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp get_longest_habit_streak(user_id) do
    habits =
      Neptuner.Habits.Habit
      |> where([h], h.user_id == ^user_id)
      |> Repo.all()

    habits
    |> Enum.map(& &1.longest_streak)
    |> Enum.max(fn -> 0 end)
  end

  defp count_attended_meetings(user_id) do
    Neptuner.Calendar.Meeting
    |> where([m], m.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp count_useless_meetings(user_id) do
    Neptuner.Calendar.Meeting
    |> where([m], m.user_id == ^user_id and m.could_have_been_email == true)
    |> Repo.aggregate(:count)
  end

  defp count_processed_emails(user_id) do
    Neptuner.Communications.EmailSummary
    |> where([e], e.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp count_active_connections(user_id) do
    Neptuner.Connections.ServiceConnection
    |> where([sc], sc.user_id == ^user_id and sc.connection_status == :active)
    |> Repo.aggregate(:count)
  end

  def get_achievement_statistics(user_id) do
    total_achievements = Repo.aggregate(Achievement, :count)

    user_completed =
      UserAchievement
      |> where([ua], ua.user_id == ^user_id and not is_nil(ua.completed_at))
      |> Repo.aggregate(:count)

    user_in_progress =
      UserAchievement
      |> where([ua], ua.user_id == ^user_id and is_nil(ua.completed_at))
      |> Repo.aggregate(:count)

    %{
      total_achievements: total_achievements,
      completed: user_completed,
      in_progress: user_in_progress,
      completion_percentage:
        if(total_achievements > 0, do: round(user_completed / total_achievements * 100), else: 0)
    }
  end
end
