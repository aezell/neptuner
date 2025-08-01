defmodule Neptuner.Calendar.SyncService do
  @moduledoc """
  Service for syncing calendar events from external providers.

  This is a basic implementation that demonstrates the sync architecture.
  In a production environment, this would include actual API calls to 
  Google Calendar, Microsoft Graph, etc.
  """

  alias Neptuner.Calendar
  alias Neptuner.Connections

  def sync_user_calendars(user_id) do
    calendar_connections = Connections.list_service_connections_by_type(user_id, :calendar)

    results =
      Enum.map(calendar_connections, fn connection ->
        sync_calendar_connection(user_id, connection)
      end)

    # Return summary of sync results
    %{
      connections_synced: length(calendar_connections),
      sync_results: results,
      synced_at: DateTime.utc_now()
    }
  end

  def sync_calendar_connection(user_id, connection) do
    case connection.provider do
      :google -> sync_google_calendar(user_id, connection)
      :microsoft -> sync_microsoft_calendar(user_id, connection)
      _ -> {:error, :unsupported_provider}
    end
  end

  defp sync_google_calendar(user_id, connection) do
    # In a real implementation, this would:
    # 1. Use the stored access token to call Google Calendar API
    # 2. Fetch recent calendar events
    # 3. Transform the data and sync with our Meeting model

    # For now, we'll create some mock meetings to demonstrate the system
    mock_meetings = generate_mock_google_meetings()

    sync_results =
      Enum.map(mock_meetings, fn meeting_data ->
        Calendar.sync_meeting_from_external(user_id, connection.id, meeting_data)
      end)

    {:ok, %{provider: :google, meetings_synced: length(sync_results)}}
  end

  defp sync_microsoft_calendar(user_id, connection) do
    # Similar to Google implementation
    mock_meetings = generate_mock_microsoft_meetings()

    sync_results =
      Enum.map(mock_meetings, fn meeting_data ->
        Calendar.sync_meeting_from_external(user_id, connection.id, meeting_data)
      end)

    {:ok, %{provider: :microsoft, meetings_synced: length(sync_results)}}
  end

  # Mock data generators for demonstration
  defp generate_mock_google_meetings do
    base_time = DateTime.utc_now() |> DateTime.add(-7, :day)

    [
      %{
        external_id: "google_standup_#{:rand.uniform(1000)}",
        title: "Daily Standup - Engineering",
        duration_minutes: 30,
        attendees: ["user@company.com", "dev1@company.com", "dev2@company.com"],
        start_time: DateTime.add(base_time, 1, :day)
      },
      %{
        external_id: "google_allhands_#{:rand.uniform(1000)}",
        title: "All Hands - Q4 Planning",
        duration_minutes: 60,
        attendees: Enum.map(1..25, fn i -> "employee#{i}@company.com" end),
        start_time: DateTime.add(base_time, 2, :day)
      },
      %{
        external_id: "google_1on1_#{:rand.uniform(1000)}",
        title: "1:1 with Manager",
        duration_minutes: 30,
        attendees: ["user@company.com", "manager@company.com"],
        start_time: DateTime.add(base_time, 3, :day)
      },
      %{
        external_id: "google_brainstorm_#{:rand.uniform(1000)}",
        title: "Product Brainstorming Session",
        duration_minutes: 90,
        attendees: ["user@company.com", "product@company.com", "design@company.com"],
        start_time: DateTime.add(base_time, 4, :day)
      },
      %{
        external_id: "google_status_#{:rand.uniform(1000)}",
        title: "Weekly Status Update Meeting",
        duration_minutes: 45,
        attendees: Enum.map(1..8, fn i -> "team#{i}@company.com" end),
        start_time: DateTime.add(base_time, 5, :day)
      }
    ]
  end

  defp generate_mock_microsoft_meetings do
    base_time = DateTime.utc_now() |> DateTime.add(-5, :day)

    [
      %{
        external_id: "outlook_sync_#{:rand.uniform(1000)}",
        title: "Cross-team Sync Meeting",
        duration_minutes: 60,
        attendees: Enum.map(1..6, fn i -> "member#{i}@company.com" end),
        start_time: DateTime.add(base_time, 1, :day)
      },
      %{
        external_id: "outlook_review_#{:rand.uniform(1000)}",
        title: "Quarterly Review Meeting",
        duration_minutes: 120,
        attendees: ["user@company.com", "director@company.com", "hr@company.com"],
        start_time: DateTime.add(base_time, 2, :day)
      },
      %{
        external_id: "outlook_planning_#{:rand.uniform(1000)}",
        title: "Sprint Planning Session",
        duration_minutes: 90,
        attendees: Enum.map(1..5, fn i -> "dev#{i}@company.com" end),
        start_time: DateTime.add(base_time, 3, :day)
      }
    ]
  end

  def get_sync_recommendations(user_id) do
    stats = Calendar.get_meeting_statistics(user_id)
    weekly = Calendar.get_weekly_meeting_report(user_id)

    recommendations = []

    recommendations =
      if stats.could_have_been_email_percentage > 60 do
        ["Consider challenging meetings that could be handled asynchronously" | recommendations]
      else
        recommendations
      end

    recommendations =
      if weekly.week_hours > 20 do
        [
          "You're spending #{weekly.week_hours}h/week in meetings - consider time blocking for deep work"
          | recommendations
        ]
      else
        recommendations
      end

    recommendations =
      if stats.unrated_meetings > 10 do
        ["Rate your recent meetings to improve the cosmic accuracy of insights" | recommendations]
      else
        recommendations
      end

    %{
      meeting_load_status: classify_meeting_load(weekly.week_hours),
      email_worthiness_status: classify_email_worthiness(stats.could_have_been_email_percentage),
      recommendations: recommendations,
      existential_insight: generate_meeting_philosophy(stats, weekly)
    }
  end

  defp classify_meeting_load(hours) when hours < 5, do: :light_load
  defp classify_meeting_load(hours) when hours < 15, do: :moderate_load
  defp classify_meeting_load(hours) when hours < 25, do: :heavy_load
  defp classify_meeting_load(_), do: :meeting_overload

  defp classify_email_worthiness(percentage) when percentage < 30, do: :meeting_efficient
  defp classify_email_worthiness(percentage) when percentage < 60, do: :moderately_efficient
  defp classify_email_worthiness(_), do: :email_heavy

  defp generate_meeting_philosophy(stats, weekly) do
    cond do
      stats.average_productivity_score && stats.average_productivity_score > 7 ->
        "You've discovered the rare art of productive gatherings. The universe notices."

      weekly.collective_human_hours_lost > 50 ->
        "#{weekly.collective_human_hours_lost} collective hours were lost to meetings this week. That's enough time to contemplate the meaning of existence."

      stats.could_have_been_email_percentage > 80 ->
        "Most of your meetings are elaborate email ceremonies. This is either peak corporate theater or a cry for asynchronous help."

      true ->
        "Your meeting patterns suggest the eternal human struggle between connection and efficiency. Both have their cosmic place."
    end
  end
end
