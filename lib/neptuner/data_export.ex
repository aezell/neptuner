defmodule Neptuner.DataExport do
  @moduledoc """
  Data export functionality for premium users.
  Provides cosmic insights in various formats for external analysis.
  """

  alias Neptuner.{Tasks, Habits, Calendar, Communications, Achievements, Subscriptions}

  @doc """
  Generates a comprehensive data export for a user in the specified format.
  Available formats: :json, :csv, :excel
  Premium feature - requires cosmic_enlightenment or enterprise tier.
  """
  def export_user_data(user_id, format \\ :json, options \\ %{}) do
    # Verify user has premium access
    case Subscriptions.get_user_subscription_tier(user_id) do
      {:ok, tier} when tier in [:cosmic_enlightenment, :enterprise] ->
        generate_export(user_id, format, options)

      _ ->
        {:error, :insufficient_cosmic_privileges}
    end
  end

  @doc """
  Generates a specific dataset export (tasks, habits, meetings, etc.)
  """
  def export_dataset(user_id, dataset, format \\ :json, options \\ %{}) do
    case Subscriptions.get_user_subscription_tier(user_id) do
      {:ok, tier} when tier in [:cosmic_enlightenment, :enterprise] ->
        case dataset do
          :tasks -> export_tasks(user_id, format, options)
          :habits -> export_habits(user_id, format, options)
          :meetings -> export_meetings(user_id, format, options)
          :communications -> export_communications(user_id, format, options)
          :achievements -> export_achievements(user_id, format, options)
          :analytics -> export_analytics(user_id, format, options)
          _ -> {:error, :unknown_dataset}
        end

      _ ->
        {:error, :insufficient_cosmic_privileges}
    end
  end

  # Private functions

  defp generate_export(user_id, format, options) do
    date_range = get_date_range(options)

    export_data = %{
      export_metadata: %{
        user_id: user_id,
        generated_at: DateTime.utc_now(),
        format: format,
        date_range: date_range,
        cosmic_version: "1.0",
        philosophical_note:
          "Remember: all productivity is an illusion in the cosmic scale of time and space."
      },
      tasks: get_tasks_data(user_id, date_range),
      habits: get_habits_data(user_id, date_range),
      meetings: get_meetings_data(user_id, date_range),
      communications: get_communications_data(user_id, date_range),
      achievements: get_achievements_data(user_id),
      cosmic_insights: get_cosmic_insights(user_id, date_range)
    }

    case format_export_data(export_data, format) do
      {:ok, formatted_data} ->
        {:ok,
         %{
           data: formatted_data,
           filename: generate_filename(user_id, format),
           content_type: get_content_type(format)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp export_tasks(user_id, format, options) do
    date_range = get_date_range(options)
    tasks_data = get_tasks_data(user_id, date_range)

    export_data = %{
      export_metadata: %{
        dataset: "tasks",
        user_id: user_id,
        generated_at: DateTime.utc_now(),
        date_range: date_range
      },
      tasks: tasks_data
    }

    format_and_package_export(export_data, format, user_id, "tasks")
  end

  defp export_habits(user_id, format, options) do
    date_range = get_date_range(options)
    habits_data = get_habits_data(user_id, date_range)

    export_data = %{
      export_metadata: %{
        dataset: "habits",
        user_id: user_id,
        generated_at: DateTime.utc_now(),
        date_range: date_range
      },
      habits: habits_data
    }

    format_and_package_export(export_data, format, user_id, "habits")
  end

  defp export_meetings(user_id, format, options) do
    date_range = get_date_range(options)
    meetings_data = get_meetings_data(user_id, date_range)

    export_data = %{
      export_metadata: %{
        dataset: "meetings",
        user_id: user_id,
        generated_at: DateTime.utc_now(),
        date_range: date_range
      },
      meetings: meetings_data
    }

    format_and_package_export(export_data, format, user_id, "meetings")
  end

  defp export_communications(user_id, format, options) do
    date_range = get_date_range(options)
    communications_data = get_communications_data(user_id, date_range)

    export_data = %{
      export_metadata: %{
        dataset: "communications",
        user_id: user_id,
        generated_at: DateTime.utc_now(),
        date_range: date_range
      },
      communications: communications_data
    }

    format_and_package_export(export_data, format, user_id, "communications")
  end

  defp export_achievements(user_id, format, _options) do
    achievements_data = get_achievements_data(user_id)

    export_data = %{
      export_metadata: %{
        dataset: "achievements",
        user_id: user_id,
        generated_at: DateTime.utc_now()
      },
      achievements: achievements_data
    }

    format_and_package_export(export_data, format, user_id, "achievements")
  end

  defp export_analytics(user_id, format, options) do
    date_range = get_date_range(options)
    analytics_data = get_cosmic_insights(user_id, date_range)

    export_data = %{
      export_metadata: %{
        dataset: "analytics",
        user_id: user_id,
        generated_at: DateTime.utc_now(),
        date_range: date_range
      },
      cosmic_insights: analytics_data
    }

    format_and_package_export(export_data, format, user_id, "analytics")
  end

  # Data collection functions

  defp get_tasks_data(user_id, {start_date, end_date}) do
    Tasks.list_tasks_for_date_range(user_id, start_date, end_date)
    |> Enum.map(fn task ->
      %{
        id: task.id,
        title: task.title,
        description: task.description,
        priority: task.priority,
        status: task.status,
        estimated_effort: task.estimated_effort,
        actual_effort: task.actual_effort,
        created_at: task.inserted_at,
        completed_at: task.completed_at,
        cosmic_category: task.cosmic_category,
        reality_check_score: task.reality_check_score,
        existential_weight: task.existential_weight
      }
    end)
  end

  defp get_habits_data(user_id, {start_date, end_date}) do
    habits = Habits.list_habits(user_id)

    Enum.map(habits, fn habit ->
      # Get habit tracking data for the date range
      tracking_data = Habits.get_habit_tracking_for_range(habit.id, start_date, end_date)

      %{
        id: habit.id,
        name: habit.name,
        description: habit.description,
        category: habit.category,
        frequency_goal: habit.frequency_goal,
        current_streak: habit.current_streak,
        longest_streak: habit.longest_streak,
        created_at: habit.inserted_at,
        tracking_data: tracking_data,
        existential_purpose: habit.existential_purpose
      }
    end)
  end

  defp get_meetings_data(user_id, {start_date, end_date}) do
    Calendar.list_meetings_for_date_range(user_id, start_date, end_date)
    |> Enum.map(fn meeting ->
      %{
        id: meeting.id,
        title: meeting.title,
        description: meeting.description,
        scheduled_at: meeting.scheduled_at,
        duration_minutes: meeting.duration_minutes,
        meeting_type: meeting.meeting_type,
        attendee_count: meeting.attendee_count,
        productivity_score: meeting.productivity_score,
        could_have_been_email: meeting.could_have_been_email,
        actual_productivity_score: meeting.actual_productivity_score,
        location: meeting.location,
        meeting_link: meeting.meeting_link,
        external_id: meeting.external_id,
        calendar_name: meeting.calendar_name,
        recurring: meeting.recurring
      }
    end)
  end

  defp get_communications_data(user_id, {start_date, end_date}) do
    Communications.list_email_summaries_for_date_range(user_id, start_date, end_date)
    |> Enum.map(fn email ->
      %{
        id: email.id,
        subject: email.subject,
        from_email: email.from_email,
        received_at: email.received_at,
        classification: email.classification,
        importance_score: email.importance_score,
        thread_position: email.thread_position,
        is_sent: email.is_sent,
        word_count: email.word_count,
        has_attachments: email.has_attachments,
        labels: email.labels
      }
    end)
  end

  defp get_achievements_data(user_id) do
    Achievements.list_user_achievements(user_id)
    |> Enum.map(fn achievement ->
      %{
        id: achievement.id,
        achievement_type: achievement.achievement_type,
        unlocked_at: achievement.unlocked_at,
        progress_value: achievement.progress_value,
        milestone_reached: achievement.milestone_reached,
        cosmic_significance: achievement.cosmic_significance
      }
    end)
  end

  defp get_cosmic_insights(user_id, {start_date, end_date}) do
    # Generate comprehensive analytics for the user
    %{
      productivity_summary: calculate_productivity_summary(user_id, start_date, end_date),
      cosmic_balance: calculate_cosmic_balance(user_id, start_date, end_date),
      time_allocation: calculate_time_allocation(user_id, start_date, end_date),
      digital_wellness: calculate_digital_wellness(user_id, start_date, end_date),
      existential_insights: generate_existential_insights(user_id, start_date, end_date)
    }
  end

  # Helper functions for analytics

  defp calculate_productivity_summary(user_id, start_date, end_date) do
    tasks = Tasks.list_tasks_for_date_range(user_id, start_date, end_date)
    meetings = Calendar.list_meetings_for_date_range(user_id, start_date, end_date)
    habits = Habits.get_user_habit_stats_for_range(user_id, start_date, end_date)

    %{
      tasks_completed: Enum.count(tasks, &(&1.status == :completed)),
      total_tasks: length(tasks),
      meetings_attended: length(meetings),
      average_meeting_score: calculate_average_meeting_score(meetings),
      habit_completion_rate: habits[:completion_rate] || 0,
      cosmic_productivity_rating: calculate_cosmic_rating(tasks, meetings, habits)
    }
  end

  defp calculate_cosmic_balance(user_id, start_date, end_date) do
    tasks_by_priority = Tasks.get_tasks_by_priority_distribution(user_id, start_date, end_date)

    %{
      cosmic_focus: tasks_by_priority[:cosmic] || 0,
      galactic_focus: tasks_by_priority[:galactic] || 0,
      stellar_focus: tasks_by_priority[:stellar] || 0,
      terrestrial_focus: tasks_by_priority[:terrestrial] || 0,
      balance_rating: calculate_balance_rating(tasks_by_priority)
    }
  end

  defp calculate_time_allocation(user_id, start_date, end_date) do
    meetings = Calendar.list_meetings_for_date_range(user_id, start_date, end_date)
    tasks = Tasks.list_tasks_for_date_range(user_id, start_date, end_date)

    total_meeting_time = Enum.sum(Enum.map(meetings, & &1.duration_minutes))
    total_task_time = Enum.sum(Enum.map(tasks, &(&1.actual_effort || 0)))

    %{
      meeting_minutes: total_meeting_time,
      task_minutes: total_task_time,
      meeting_percentage:
        if(total_meeting_time + total_task_time > 0,
          do: total_meeting_time / (total_meeting_time + total_task_time) * 100,
          else: 0
        ),
      task_percentage:
        if(total_meeting_time + total_task_time > 0,
          do: total_task_time / (total_meeting_time + total_task_time) * 100,
          else: 0
        )
    }
  end

  defp calculate_digital_wellness(user_id, start_date, end_date) do
    emails = Communications.list_email_summaries_for_date_range(user_id, start_date, end_date)

    %{
      emails_processed: length(emails),
      average_importance_score: calculate_average_importance_score(emails),
      communication_balance: calculate_communication_balance(emails),
      digital_noise_ratio: calculate_digital_noise_ratio(emails)
    }
  end

  defp generate_existential_insights(user_id, start_date, end_date) do
    # Generate philosophical observations about the user's productivity patterns
    tasks = Tasks.list_tasks_for_date_range(user_id, start_date, end_date)
    meetings = Calendar.list_meetings_for_date_range(user_id, start_date, end_date)

    insights = []

    # Add insights based on patterns
    insights =
      if Enum.count(tasks, &(&1.priority == :cosmic)) > Enum.count(tasks) / 2 do
        [
          "You demonstrate cosmic awareness by focusing on what truly matters in the long term."
          | insights
        ]
      else
        insights
      end

    insights =
      if Enum.count(meetings, & &1.could_have_been_email) > length(meetings) / 3 do
        [
          "Your calendar suggests the universe is testing your meeting endurance with unnecessary gatherings."
          | insights
        ]
      else
        insights
      end

    # Add more insights based on other patterns...

    %{
      observations: insights,
      cosmic_wisdom:
        "In the vast expanse of time and space, your productivity patterns reveal the eternal human struggle to find meaning in digital chaos.",
      next_evolution:
        "Consider transcending traditional productivity by embracing the cosmic perspective on what truly matters."
    }
  end

  # Format and packaging functions

  defp format_and_package_export(export_data, format, user_id, dataset_name) do
    case format_export_data(export_data, format) do
      {:ok, formatted_data} ->
        {:ok,
         %{
           data: formatted_data,
           filename: generate_filename(user_id, format, dataset_name),
           content_type: get_content_type(format)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_export_data(data, :json) do
    {:ok, Jason.encode!(data, pretty: true)}
  end

  defp format_export_data(data, :csv) do
    # For CSV, we need to flatten the data structure
    # This is a simplified implementation - a full version would handle nested data better
    {:ok, csv_data} = flatten_for_csv(data)
    {:ok, csv_data}
  end

  defp format_export_data(_data, :excel) do
    # Excel export would require a library like xlsxir or similar
    # For now, return an error indicating it's not implemented
    {:error, :excel_format_not_implemented}
  end

  defp format_export_data(_data, format) do
    {:error, {:unsupported_format, format}}
  end

  defp flatten_for_csv(_data) do
    # Simple CSV flattening - in a real implementation, this would be more sophisticated
    csv_rows = []

    # Add headers
    headers = ["field", "value", "timestamp"]
    csv_content = [headers | csv_rows] |> Enum.map(&Enum.join(&1, ",")) |> Enum.join("\n")

    {:ok, csv_content}
  end

  defp get_date_range(options) do
    start_date = Map.get(options, :start_date, Date.utc_today() |> Date.add(-30))
    end_date = Map.get(options, :end_date, Date.utc_today())
    {start_date, end_date}
  end

  defp generate_filename(user_id, format, dataset_name \\ "complete") do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "neptuner_#{dataset_name}_export_user_#{user_id}_#{timestamp}.#{format}"
  end

  defp get_content_type(:json), do: "application/json"
  defp get_content_type(:csv), do: "text/csv"

  defp get_content_type(:excel),
    do: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  # Analytics helper functions (simplified implementations)

  defp calculate_average_meeting_score(meetings) do
    if length(meetings) > 0 do
      Enum.sum(Enum.map(meetings, &(&1.productivity_score || 50))) / length(meetings)
    else
      0
    end
  end

  defp calculate_cosmic_rating(tasks, meetings, habits) do
    # Simplified cosmic rating calculation
    task_score =
      if length(tasks) > 0,
        do: Enum.count(tasks, &(&1.status == :completed)) / length(tasks) * 100,
        else: 50

    meeting_score = calculate_average_meeting_score(meetings)
    habit_score = habits[:completion_rate] || 50

    (task_score + meeting_score + habit_score) / 3
  end

  defp calculate_balance_rating(tasks_by_priority) do
    # Calculate how balanced the priority distribution is
    total_tasks = Enum.sum(Map.values(tasks_by_priority))
    # Simplified implementation
    if total_tasks == 0, do: 0, else: 50
  end

  defp calculate_average_importance_score(emails) do
    if length(emails) > 0 do
      Enum.sum(Enum.map(emails, &(&1.importance_score || 50))) / length(emails)
    else
      0
    end
  end

  defp calculate_communication_balance(emails) do
    sent_count = Enum.count(emails, & &1.is_sent)
    received_count = length(emails) - sent_count

    if received_count > 0 do
      sent_count / received_count
    else
      0
    end
  end

  defp calculate_digital_noise_ratio(emails) do
    noise_emails =
      Enum.count(emails, &(&1.classification in [:digital_noise, :mass_communication]))

    if length(emails) > 0 do
      noise_emails / length(emails) * 100
    else
      0
    end
  end
end
