defmodule Neptuner.Analytics do
  @moduledoc """
  The Analytics context manages success metrics tracking for activation and engagement.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo
  alias Neptuner.Accounts.User
  alias Neptuner.Onboarding

  @doc """
  Records user activation events for tracking onboarding success.
  """
  def track_activation_event(user, event_type, metadata \\ %{}) do
    event_data = %{
      user_id: user.id,
      event_type: to_string(event_type),
      event_data: metadata,
      occurred_at: DateTime.utc_now()
    }

    # Log to Phoenix Analytics if available, or implement custom tracking
    log_activation_event(event_data)

    # Update user activation score if it's an onboarding milestone
    case event_type do
      :onboarding_started ->
        update_activation_milestone(user, :onboarding_started_at)

      :cosmic_perspective_set ->
        update_activation_milestone(user, :cosmic_perspective_level, metadata[:level])

      :demo_data_generated ->
        update_activation_milestone(user, :demo_data_generated, true)

      :first_task_created ->
        update_activation_milestone(user, :first_task_created, true)

      :first_connection_made ->
        update_activation_milestone(user, :first_connection_made, true)

      :dashboard_tour_completed ->
        update_activation_milestone(user, :dashboard_tour_completed, true)

      :onboarding_completed ->
        update_activation_milestone(user, :onboarding_completed, true)

      _ ->
        :ok
    end
  end

  @doc """
  Tracks engagement events for user retention analysis.
  """
  def track_engagement_event(user, event_type, metadata \\ %{}) do
    event_data = %{
      user_id: user.id,
      event_type: to_string(event_type),
      event_data: metadata,
      occurred_at: DateTime.utc_now()
    }

    log_engagement_event(event_data)
  end

  @doc """
  Gets activation metrics for a user.
  """
  def get_activation_metrics(user) do
    progress = Onboarding.get_onboarding_progress(user)

    activation_events = [
      {:onboarding_started, progress.started_at != nil},
      {:cosmic_perspective_set, progress.cosmic_perspective_level != :skeptical},
      {:demo_data_generated, progress.demo_data_generated},
      {:first_task_created, progress.first_task_created},
      {:first_connection_made, progress.first_connection_made},
      {:dashboard_tour_completed, progress.dashboard_tour_completed},
      {:onboarding_completed, progress.completed}
    ]

    completed_events = Enum.count(activation_events, fn {_, completed} -> completed end)
    total_events = length(activation_events)

    %{
      activation_score: progress.activation_score,
      activation_percentage: round(completed_events / total_events * 100),
      completed_milestones: Enum.filter(activation_events, fn {_, completed} -> completed end),
      remaining_milestones:
        Enum.filter(activation_events, fn {_, completed} -> not completed end),
      time_to_activation: calculate_time_to_activation(user),
      is_activated: progress.completed
    }
  end

  @doc """
  Gets engagement metrics for a user.
  """
  def get_engagement_metrics(user) do
    thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)
    seven_days_ago = DateTime.add(DateTime.utc_now(), -7, :day)

    # Calculate various engagement metrics
    %{
      # Task engagement
      tasks_created_30d: count_user_tasks_since(user.id, thirty_days_ago),
      tasks_completed_30d: count_user_completed_tasks_since(user.id, thirty_days_ago),
      tasks_created_7d: count_user_tasks_since(user.id, seven_days_ago),

      # Habit engagement
      active_habits: count_user_active_habits(user.id),
      habit_completions_30d: count_habit_completions_since(user.id, thirty_days_ago),
      longest_streak: get_user_longest_streak(user.id),

      # Connection engagement
      active_connections: count_user_active_connections(user.id),
      last_sync: get_last_sync_time(user.id),

      # Achievement engagement
      achievements_earned_30d: count_achievements_earned_since(user.id, thirty_days_ago),

      # Overall engagement score
      engagement_score: calculate_engagement_score(user),
      engagement_level: classify_engagement_level(user)
    }
  end

  @doc """
  Gets cohort analysis data for users who signed up in a given time period.
  """
  def get_cohort_analysis(start_date, end_date) do
    users =
      User
      |> where([u], u.inserted_at >= ^start_date and u.inserted_at <= ^end_date)
      |> Repo.all()

    total_users = length(users)

    if total_users == 0 do
      %{
        total_users: 0,
        activation_rate: 0,
        metrics: %{}
      }
    else
      activated_users = Enum.count(users, & &1.onboarding_completed)

      metrics = %{
        total_users: total_users,
        activated_users: activated_users,
        activation_rate: round(activated_users / total_users * 100),
        average_time_to_activation: calculate_average_time_to_activation(users),
        completion_funnel: calculate_completion_funnel(users)
      }

      %{
        total_users: total_users,
        activation_rate: metrics.activation_rate,
        metrics: metrics
      }
    end
  end

  # Private helper functions

  defp log_activation_event(event_data) do
    # Log to system logger for now - can be extended to external analytics
    require Logger
    Logger.info("Activation Event: #{inspect(event_data)}")
  end

  defp log_engagement_event(event_data) do
    # Log to system logger for now - can be extended to external analytics  
    require Logger
    Logger.info("Engagement Event: #{inspect(event_data)}")
  end

  defp update_activation_milestone(user, field, value \\ true) do
    attrs = %{field => value}

    user
    |> User.onboarding_changeset(attrs)
    |> Repo.update()
  end

  defp calculate_time_to_activation(user) do
    if user.onboarding_completed_at && user.onboarding_started_at do
      DateTime.diff(user.onboarding_completed_at, user.onboarding_started_at, :second)
    else
      nil
    end
  end

  defp count_user_tasks_since(user_id, since_date) do
    Neptuner.Tasks.Task
    |> where([t], t.user_id == ^user_id and t.inserted_at >= ^since_date)
    |> Repo.aggregate(:count)
  end

  defp count_user_completed_tasks_since(user_id, since_date) do
    Neptuner.Tasks.Task
    |> where(
      [t],
      t.user_id == ^user_id and t.status == :completed and t.updated_at >= ^since_date
    )
    |> Repo.aggregate(:count)
  end

  defp count_user_active_habits(user_id) do
    Neptuner.Habits.Habit
    |> where([h], h.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp count_habit_completions_since(_user_id, _since_date) do
    # This would need to be implemented based on habit entries
    # For now, return 0
    0
  end

  defp get_user_longest_streak(user_id) do
    habits =
      Neptuner.Habits.Habit
      |> where([h], h.user_id == ^user_id)
      |> Repo.all()

    habits
    |> Enum.map(& &1.longest_streak)
    |> Enum.max(fn -> 0 end)
  end

  defp count_user_active_connections(user_id) do
    Neptuner.Connections.ServiceConnection
    |> where([sc], sc.user_id == ^user_id and sc.connection_status == :active)
    |> Repo.aggregate(:count)
  end

  defp get_last_sync_time(user_id) do
    Neptuner.Connections.ServiceConnection
    |> where([sc], sc.user_id == ^user_id)
    |> select([sc], max(sc.last_sync_at))
    |> Repo.one()
  end

  defp count_achievements_earned_since(user_id, since_date) do
    Neptuner.Achievements.UserAchievement
    |> where(
      [ua],
      ua.user_id == ^user_id and not is_nil(ua.completed_at) and ua.completed_at >= ^since_date
    )
    |> Repo.aggregate(:count)
  end

  defp calculate_engagement_score(user) do
    metrics = get_engagement_metrics(user)

    # Simple engagement scoring algorithm
    score = 0
    score = score + metrics.tasks_created_7d * 5
    score = score + metrics.active_habits * 10
    score = score + metrics.active_connections * 15
    score = score + metrics.achievements_earned_30d * 20

    min(score, 100)
  end

  defp classify_engagement_level(user) do
    score = calculate_engagement_score(user)

    cond do
      score >= 80 -> :highly_engaged
      score >= 50 -> :moderately_engaged
      score >= 20 -> :lightly_engaged
      true -> :at_risk
    end
  end

  defp calculate_average_time_to_activation(users) do
    activation_times =
      users
      |> Enum.filter(fn user ->
        user.onboarding_completed_at && user.onboarding_started_at
      end)
      |> Enum.map(fn user ->
        DateTime.diff(user.onboarding_completed_at, user.onboarding_started_at, :second)
      end)

    if length(activation_times) > 0 do
      Enum.sum(activation_times) / length(activation_times)
    else
      nil
    end
  end

  defp calculate_completion_funnel(users) do
    total = length(users)

    if total == 0 do
      %{}
    else
      %{
        started_onboarding: Enum.count(users, &(&1.onboarding_started_at != nil)) / total * 100,
        set_cosmic_perspective:
          Enum.count(users, &(&1.cosmic_perspective_level != :skeptical)) / total * 100,
        generated_demo_data: Enum.count(users, & &1.demo_data_generated) / total * 100,
        created_first_task: Enum.count(users, & &1.first_task_created) / total * 100,
        made_first_connection: Enum.count(users, & &1.first_connection_made) / total * 100,
        completed_dashboard_tour: Enum.count(users, & &1.dashboard_tour_completed) / total * 100,
        completed_onboarding: Enum.count(users, & &1.onboarding_completed) / total * 100
      }
      |> Enum.map(fn {k, v} -> {k, round(v)} end)
      |> Enum.into(%{})
    end
  end
end
