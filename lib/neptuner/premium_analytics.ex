defmodule Neptuner.PremiumAnalytics do
  alias Neptuner.{Tasks, Habits, Calendar, Communications, Subscriptions}
  alias Neptuner.Repo
  import Ecto.Query

  @doc """
  Get advanced productivity analytics for premium users only.
  """
  def get_advanced_analytics(user) do
    unless Subscriptions.has_feature?(user, :advanced_analytics) do
      {:error, :premium_required}
    else
      {:ok,
       %{
         productivity_trends: get_productivity_trends(user.id),
         time_allocation: get_time_allocation_analysis(user.id),
         productivity_patterns: get_productivity_patterns(user.id),
         cross_system_insights: get_cross_system_insights(user.id),
         predictive_insights: get_predictive_insights(user.id),
         cosmic_coaching: get_cosmic_coaching(user.id)
       }}
    end
  end

  @doc """
  Get trend analysis showing productivity patterns over time.
  """
  def get_productivity_trends(user_id) do
    # Task completion trends over last 30 days
    task_trends = get_task_completion_trends(user_id)

    # Habit consistency trends
    habit_trends = get_habit_consistency_trends(user_id)

    # Meeting productivity trends
    meeting_trends = get_meeting_productivity_trends(user_id)

    %{
      task_completion_velocity: task_trends,
      habit_consistency_score: habit_trends,
      meeting_productivity_evolution: meeting_trends,
      overall_productivity_trend:
        calculate_overall_trend(task_trends, habit_trends, meeting_trends),
      cosmic_insight: generate_trend_insight(task_trends, habit_trends, meeting_trends)
    }
  end

  @doc """
  Analyze how time is allocated across different activities.
  """
  def get_time_allocation_analysis(user_id) do
    task_time = estimate_task_time_allocation(user_id)
    meeting_time = get_actual_meeting_time(user_id)
    habit_time = estimate_habit_time(user_id)

    total_time = task_time + meeting_time + habit_time

    %{
      task_allocation: %{
        time_minutes: task_time,
        percentage: if(total_time > 0, do: round(task_time / total_time * 100), else: 0)
      },
      meeting_allocation: %{
        time_minutes: meeting_time,
        percentage: if(total_time > 0, do: round(meeting_time / total_time * 100), else: 0)
      },
      habit_allocation: %{
        time_minutes: habit_time,
        percentage: if(total_time > 0, do: round(habit_time / total_time * 100), else: 0)
      },
      optimization_suggestions:
        get_time_optimization_suggestions(task_time, meeting_time, habit_time),
      cosmic_wisdom: generate_time_allocation_wisdom(task_time, meeting_time, habit_time)
    }
  end

  @doc """
  Identify productivity patterns and peak performance times.
  """
  def get_productivity_patterns(user_id) do
    %{
      peak_productivity_days: identify_peak_days(user_id),
      task_completion_patterns: analyze_task_completion_patterns(user_id),
      habit_streak_patterns: analyze_habit_streak_patterns(user_id),
      procrastination_indicators: identify_procrastination_patterns(user_id),
      energy_level_correlation: correlate_energy_with_productivity(user_id),
      cosmic_pattern_recognition: generate_pattern_insights(user_id)
    }
  end

  @doc """
  Cross-system insights connecting different productivity areas.
  """
  def get_cross_system_insights(user_id) do
    %{
      task_habit_correlation: analyze_task_habit_correlation(user_id),
      meeting_productivity_impact: analyze_meeting_impact_on_tasks(user_id),
      email_distraction_analysis: analyze_email_impact_on_focus(user_id),
      achievement_motivation_patterns: analyze_achievement_motivation(user_id),
      system_synergy_score: calculate_system_synergy(user_id),
      cosmic_interconnectedness: generate_interconnection_insights(user_id)
    }
  end

  @doc """
  Predictive insights based on historical patterns.
  """
  def get_predictive_insights(user_id) do
    %{
      likely_completion_times: predict_task_completion_times(user_id),
      habit_streak_predictions: predict_habit_streak_sustainability(user_id),
      productivity_forecast: forecast_productivity_trends(user_id),
      burnout_risk_assessment: assess_burnout_risk(user_id),
      achievement_timeline: predict_achievement_completion(user_id),
      cosmic_prophecy: generate_predictive_wisdom(user_id)
    }
  end

  @doc """
  AI-powered cosmic coaching based on user patterns.
  """
  def get_cosmic_coaching(user_id) do
    analytics = %{
      task_stats: Tasks.get_task_statistics(user_id),
      habit_stats: Habits.get_habit_statistics(user_id),
      meeting_stats: Calendar.get_meeting_statistics(user_id),
      communication_stats: Communications.get_communication_statistics(user_id)
    }

    %{
      productivity_score: calculate_holistic_productivity_score(analytics),
      key_strengths: identify_productivity_strengths(analytics),
      improvement_areas: identify_improvement_opportunities(analytics),
      actionable_recommendations: generate_actionable_recommendations(analytics),
      weekly_focus_suggestion: suggest_weekly_focus(analytics),
      cosmic_guidance: generate_cosmic_coaching_wisdom(analytics)
    }
  end

  # Private helper functions

  defp get_task_completion_trends(user_id) do
    # Simplified trend calculation - in real implementation would use more sophisticated analysis
    last_30_days = Date.add(Date.utc_today(), -30)

    Tasks.Task
    |> where([t], t.user_id == ^user_id and t.status == :completed)
    |> where([t], t.completed_at >= ^last_30_days)
    |> group_by([t], fragment("DATE(?)", t.completed_at))
    |> select([t], {fragment("DATE(?)", t.completed_at), count(t.id)})
    |> Repo.all()
    |> Enum.map(fn {date, count} -> %{date: date, completed_tasks: count} end)
  end

  defp get_habit_consistency_trends(user_id) do
    # Calculate habit consistency over time
    user_habits = Habits.list_habits(user_id)

    Enum.map(user_habits, fn habit ->
      %{
        habit_name: habit.name,
        current_streak: habit.current_streak,
        longest_streak: habit.longest_streak,
        consistency_score: calculate_habit_consistency_score(habit)
      }
    end)
  end

  defp get_meeting_productivity_trends(user_id) do
    # Analyze meeting productivity over time
    meetings = Calendar.list_meetings(user_id)

    productive_meetings =
      Enum.filter(meetings, &(&1.actual_productivity_score && &1.actual_productivity_score >= 7))

    %{
      total_meetings: length(meetings),
      productive_meetings: length(productive_meetings),
      average_productivity: calculate_average_meeting_productivity(meetings),
      trend_direction: determine_meeting_productivity_trend(meetings)
    }
  end

  defp calculate_overall_trend(task_trends, habit_trends, meeting_trends) do
    # Simplified overall trend calculation
    task_velocity =
      if length(task_trends) > 0 do
        Enum.sum(Enum.map(task_trends, & &1.completed_tasks)) / length(task_trends)
      else
        0
      end

    habit_consistency =
      if length(habit_trends) > 0 do
        Enum.sum(Enum.map(habit_trends, & &1.consistency_score)) / length(habit_trends)
      else
        0
      end

    meeting_productivity = Map.get(meeting_trends, :average_productivity, 5)

    overall_score = task_velocity * 0.4 + habit_consistency * 0.3 + meeting_productivity * 0.3

    cond do
      overall_score >= 8 -> :ascending
      overall_score >= 6 -> :stable
      true -> :declining
    end
  end

  defp generate_trend_insight(task_trends, habit_trends, meeting_trends) do
    task_count = length(task_trends)
    habit_count = length(habit_trends)
    meeting_productivity = Map.get(meeting_trends, :average_productivity, 5)

    cond do
      task_count > 10 and habit_count > 3 and meeting_productivity > 7 ->
        "Your productivity constellation is in perfect alignment. The cosmic forces approve of your systematic approach to existence."

      task_count > 5 and meeting_productivity < 5 ->
        "High task velocity but meeting productivity suggests time might be better spent in contemplative solitude."

      habit_count > 2 and task_count < 3 ->
        "Strong habit foundation detected. Consider channeling this consistency into more ambitious task completion."

      true ->
        "Your productivity patterns reveal a unique cosmic signature. The universe is still deciphering your approach."
    end
  end

  defp estimate_task_time_allocation(user_id) do
    # Simplified estimation - would use more sophisticated time tracking in real implementation
    task_count = Tasks.get_task_statistics(user_id).total
    # Assume average 30 minutes per task
    task_count * 30
  end

  defp get_actual_meeting_time(user_id) do
    meetings = Calendar.list_meetings(user_id)
    Enum.sum(Enum.map(meetings, &(&1.duration_minutes || 0)))
  end

  defp estimate_habit_time(user_id) do
    habit_count = Habits.get_habit_statistics(user_id).total_habits
    # Assume average 15 minutes per habit per day
    # Monthly estimate
    habit_count * 15 * 30
  end

  defp get_time_optimization_suggestions(task_time, meeting_time, habit_time) do
    suggestions = []

    suggestions =
      if meeting_time > task_time * 1.5 do
        [
          "Consider reducing meeting time to focus more on individual task completion"
          | suggestions
        ]
      else
        suggestions
      end

    suggestions =
      if habit_time < task_time * 0.1 do
        ["Invest more time in habits to build sustainable productivity foundations" | suggestions]
      else
        suggestions
      end

    if length(suggestions) == 0 do
      ["Your time allocation appears cosmically balanced. The universe approves."]
    else
      suggestions
    end
  end

  defp generate_time_allocation_wisdom(task_time, meeting_time, habit_time) do
    total_time = task_time + meeting_time + habit_time

    if total_time == 0 do
      "Time is an illusion. Productivity is a double illusion. Yet here we are, measuring both."
    else
      meeting_percentage = round(meeting_time / total_time * 100)

      if meeting_percentage > 60 do
        "#{meeting_percentage}% of your time in meetings suggests you're either very important or very trapped. Possibly both."
      else
        "Your time allocation suggests a balanced approach to cosmic productivity. The universe takes note."
      end
    end
  end

  defp calculate_habit_consistency_score(habit) do
    if habit.longest_streak > 0 do
      (habit.current_streak / habit.longest_streak * 10) |> min(10) |> Float.round(1)
    else
      0
    end
  end

  defp calculate_average_meeting_productivity(meetings) do
    rated_meetings = Enum.filter(meetings, & &1.actual_productivity_score)

    if length(rated_meetings) > 0 do
      Enum.sum(Enum.map(rated_meetings, & &1.actual_productivity_score)) / length(rated_meetings)
    else
      5.0
    end
  end

  defp determine_meeting_productivity_trend(meetings) do
    # Simplified trend analysis
    if length(meetings) >= 3 do
      recent_productivity =
        meetings
        |> Enum.take(3)
        |> Enum.map(&(&1.actual_productivity_score || 5))
        |> Enum.sum()
        |> Kernel./(3)

      if recent_productivity > 6 do
        :improving
      else
        :declining
      end
    else
      :stable
    end
  end

  # Placeholder implementations for complex analytics functions
  defp identify_peak_days(_user_id), do: ["Monday", "Wednesday", "Friday"]

  defp analyze_task_completion_patterns(_user_id),
    do: %{peak_hour: 10, productivity_variance: "low"}

  defp analyze_habit_streak_patterns(_user_id),
    do: %{best_streak_day: "Tuesday", consistency_rating: 8.5}

  defp identify_procrastination_patterns(_user_id),
    do: %{risk_level: "low", peak_procrastination_time: "14:00"}

  defp correlate_energy_with_productivity(_user_id),
    do: %{correlation_strength: 0.73, peak_energy_time: "09:00"}

  defp generate_pattern_insights(_user_id),
    do: "Your patterns suggest a methodical approach to cosmic productivity."

  defp analyze_task_habit_correlation(_user_id),
    do: %{correlation: 0.65, insight: "Strong task completion correlates with habit consistency"}

  defp analyze_meeting_impact_on_tasks(_user_id),
    do: %{impact_score: -0.3, insight: "Meetings slightly reduce daily task velocity"}

  defp analyze_email_impact_on_focus(_user_id),
    do: %{distraction_score: 0.4, insight: "Email checking moderately impacts focus"}

  defp analyze_achievement_motivation(_user_id),
    do: %{
      motivation_boost: 1.2,
      insight: "Achievements provide significant productivity motivation"
    }

  defp calculate_system_synergy(_user_id), do: 7.8

  defp generate_interconnection_insights(_user_id),
    do: "Your productivity systems show promising interconnection patterns."

  defp predict_task_completion_times(_user_id),
    do: %{average_completion: "2.3 days", confidence: 0.72}

  defp predict_habit_streak_sustainability(_user_id),
    do: %{risk_of_breaking: "low", optimal_streak_length: 21}

  defp forecast_productivity_trends(_user_id),
    do: %{next_month_outlook: "stable growth", confidence: 0.68}

  defp assess_burnout_risk(_user_id),
    do: %{risk_level: "low", key_indicators: ["sustainable pace", "variety in tasks"]}

  defp predict_achievement_completion(_user_id),
    do: %{next_achievement_eta: "5 days", completion_probability: 0.85}

  defp generate_predictive_wisdom(_user_id),
    do: "The cosmic algorithms suggest continued steady progress on your current trajectory."

  defp calculate_holistic_productivity_score(analytics) do
    # Simplified scoring algorithm
    task_score = min(analytics.task_stats.completed / max(analytics.task_stats.total, 1) * 10, 10)
    habit_score = analytics.habit_stats.active_streaks * 2
    meeting_score = Map.get(analytics.meeting_stats, :average_productivity_score, 5)

    ((task_score + habit_score + meeting_score) / 3) |> Float.round(1)
  end

  defp identify_productivity_strengths(analytics) do
    strengths = []

    strengths =
      if analytics.task_stats.completed > analytics.task_stats.total * 0.7 do
        ["High task completion rate" | strengths]
      else
        strengths
      end

    strengths =
      if analytics.habit_stats.active_streaks > 2 do
        ["Strong habit consistency" | strengths]
      else
        strengths
      end

    if length(strengths) == 0, do: ["Cosmic potential awaiting activation"], else: strengths
  end

  defp identify_improvement_opportunities(analytics) do
    opportunities = []

    opportunities =
      if analytics.task_stats.matters_to_nobody > analytics.task_stats.matters_10_years do
        ["Focus more on high-impact tasks" | opportunities]
      else
        opportunities
      end

    opportunities =
      if analytics.habit_stats.self_improvement_theater > analytics.habit_stats.actually_useful do
        ["Prioritize genuinely useful habits" | opportunities]
      else
        opportunities
      end

    if length(opportunities) == 0, do: ["Continue current cosmic trajectory"], else: opportunities
  end

  defp generate_actionable_recommendations(analytics) do
    [
      "Complete #{max(1, 5 - analytics.task_stats.completed)} more high-priority tasks this week",
      "Extend your longest habit streak by 3 days",
      "Rate the productivity of your next 3 meetings to improve meeting quality",
      "Identify and eliminate one 'matters to nobody' task from your list"
    ]
  end

  defp suggest_weekly_focus(analytics) do
    cond do
      analytics.task_stats.completed < 3 ->
        "Focus on task completion momentum"

      analytics.habit_stats.active_streaks == 0 ->
        "Build one consistent daily habit"

      Map.get(analytics.meeting_stats, :could_have_been_email_percentage, 0) > 50 ->
        "Optimize meeting efficiency"

      true ->
        "Maintain current productivity rhythm"
    end
  end

  defp generate_cosmic_coaching_wisdom(analytics) do
    score = calculate_holistic_productivity_score(analytics)

    cond do
      score >= 8 ->
        "Your productivity patterns align with cosmic harmony. The universe recognizes your systematic approach to meaningful work."

      score >= 6 ->
        "Solid productivity foundation detected. Minor orbital adjustments could elevate your cosmic efficiency."

      score >= 4 ->
        "Your productivity system shows promise but requires realignment with universal principles."

      true ->
        "The cosmic productivity forces await your focused attention. Small consistent actions will shift your trajectory."
    end
  end
end
