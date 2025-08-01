defmodule Neptuner.Dashboard do
  alias Neptuner.{Tasks, Habits, Calendar, Communications, Connections, Achievements}
  alias Neptuner.Repo

  def get_unified_statistics(user_id) do
    %{
      tasks: Tasks.get_task_statistics(user_id),
      habits: Habits.get_habit_statistics(user_id),
      meetings: Calendar.get_meeting_statistics(user_id),
      communications: Communications.get_communication_statistics(user_id),
      connections: Connections.get_connection_statistics(user_id),
      achievements: Achievements.get_achievement_statistics(user_id),
      cosmic_insights: generate_cosmic_insights(user_id)
    }
  end

  def get_recent_activity(user_id, limit \\ 10) do
    recent_tasks = get_recent_task_activity(user_id, limit)
    recent_habits = get_recent_habit_activity(user_id, limit)
    recent_achievements = get_recent_achievement_activity(user_id, limit)

    (recent_tasks ++ recent_habits ++ recent_achievements)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
    |> Enum.take(limit)
  end

  def get_productivity_theater_metrics(user_id) do
    stats = get_unified_statistics(user_id)

    tasks_stats = stats.tasks
    habits_stats = stats.habits
    communications_stats = stats.communications

    total_meaningless_activity =
      tasks_stats.matters_to_nobody +
        habits_stats.self_improvement_theater +
        communications_stats.digital_noise

    total_meaningful_activity =
      tasks_stats.matters_10_years +
        habits_stats.actually_useful +
        communications_stats.urgent_important +
        communications_stats.not_urgent_important

    total_activity = total_meaningless_activity + total_meaningful_activity

    meaningless_percentage =
      if total_activity > 0 do
        round(total_meaningless_activity / total_activity * 100)
      else
        0
      end

    %{
      total_meaningless_activity: total_meaningless_activity,
      total_meaningful_activity: total_meaningful_activity,
      meaningless_percentage: meaningless_percentage,
      theater_level: categorize_theater_level(meaningless_percentage),
      cosmic_commentary: generate_theater_commentary(meaningless_percentage)
    }
  end

  defp get_recent_task_activity(user_id, limit) do
    Tasks.list_tasks(user_id)
    |> Enum.filter(&(&1.status == :completed and not is_nil(&1.completed_at)))
    |> Enum.sort_by(& &1.completed_at, {:desc, DateTime})
    |> Enum.take(limit)
    |> Enum.map(fn task ->
      %{
        type: :task_completed,
        title: "Completed task: #{task.title}",
        description: "#{cosmic_priority_label(task.cosmic_priority)} priority",
        timestamp: task.completed_at,
        icon: "hero-check-circle",
        color: cosmic_priority_color(task.cosmic_priority)
      }
    end)
  end

  defp get_recent_habit_activity(user_id, limit) do
    import Ecto.Query

    Neptuner.Habits.HabitEntry
    |> join(:inner, [he], h in assoc(he, :habit))
    |> where([he, h], h.user_id == ^user_id)
    |> order_by([he], desc: he.inserted_at)
    |> limit(^limit)
    |> preload(:habit)
    |> Repo.all()
    |> Enum.map(fn entry ->
      %{
        type: :habit_completed,
        title: "Completed habit: #{entry.habit.name}",
        description: entry.existential_commentary || "Another day, another habit",
        timestamp: entry.inserted_at,
        icon: "hero-arrow-path",
        color: habit_type_color(entry.habit.habit_type)
      }
    end)
  end

  defp get_recent_achievement_activity(user_id, limit) do
    import Ecto.Query

    Neptuner.Achievements.UserAchievement
    |> where([ua], ua.user_id == ^user_id and not is_nil(ua.completed_at))
    |> order_by([ua], desc: ua.completed_at)
    |> limit(^limit)
    |> preload(:achievement)
    |> Repo.all()
    |> Enum.map(fn user_achievement ->
      %{
        type: :achievement_unlocked,
        title: "Achievement unlocked: #{user_achievement.achievement.name}",
        description: user_achievement.achievement.ironic_description,
        timestamp: user_achievement.completed_at,
        icon: "hero-trophy",
        color: "bg-yellow-500"
      }
    end)
  end

  defp generate_cosmic_insights(user_id) do
    stats = %{
      tasks: Tasks.get_task_statistics(user_id),
      habits: Habits.get_habit_statistics(user_id),
      achievements: Achievements.get_achievement_statistics(user_id)
    }

    insights = []

    insights =
      if stats.tasks.matters_to_nobody > stats.tasks.matters_10_years do
        ["You're optimizing for digital rectangles rather than cosmic significance" | insights]
      else
        insights
      end

    insights =
      if stats.habits.self_improvement_theater > stats.habits.actually_useful do
        ["Your habits suggest a preference for performance over substance" | insights]
      else
        insights
      end

    insights =
      if stats.achievements.completion_percentage > 75 do
        ["High achievement completion: either very productive or very easily amused" | insights]
      else
        insights
      end

    insights =
      if length(insights) == 0 do
        ["Your productivity patterns defy cosmic categorization - impressive or concerning"]
      else
        insights
      end

    %{
      daily_wisdom:
        Enum.random([
          "Remember: most urgent things aren't important, and most important things aren't urgent.",
          "The universe is 13.8 billion years old. Your email can wait.",
          "Productivity is not about doing more things, it's about doing the right things.",
          "Every task completed brings you one step closer to... the next task.",
          "The real productivity was the existential dread we gained along the way."
        ]),
      insights: Enum.take(insights, 3)
    }
  end

  defp categorize_theater_level(percentage) do
    cond do
      percentage >= 80 -> "Performance Artist"
      percentage >= 60 -> "Method Actor"
      percentage >= 40 -> "Casual Performer"
      percentage >= 20 -> "Occasional Actor"
      true -> "Authenticity Seeker"
    end
  end

  defp generate_theater_commentary(percentage) do
    cond do
      percentage >= 80 ->
        "You've mastered the art of looking busy while accomplishing very little. The universe is mildly impressed."

      percentage >= 60 ->
        "A solid performance in the productivity theater. Your audience of digital systems is moderately convinced."

      percentage >= 40 ->
        "Balanced approach to meaningful work and digital ritual. The cosmos approves of your moderation."

      percentage >= 20 ->
        "Mostly focused on substantial work with occasional bows to the productivity gods. Well done."

      true ->
        "Your work patterns suggest genuine focus on what matters. Either very wise or very naive."
    end
  end

  defp cosmic_priority_label(priority) do
    case priority do
      :matters_10_years -> "Cosmic"
      :matters_10_days -> "Temporal"
      :matters_to_nobody -> "Theatrical"
    end
  end

  defp cosmic_priority_color(priority) do
    case priority do
      :matters_10_years -> "bg-purple-500"
      :matters_10_days -> "bg-blue-500"
      :matters_to_nobody -> "bg-gray-500"
    end
  end

  defp habit_type_color(habit_type) do
    case habit_type do
      :actually_useful -> "bg-green-500"
      :basic_human_function -> "bg-blue-500"
      :self_improvement_theater -> "bg-orange-500"
    end
  end
end
