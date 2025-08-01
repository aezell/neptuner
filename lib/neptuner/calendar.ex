defmodule Neptuner.Calendar do
  @moduledoc """
  The Calendar context for managing meetings and calendar integration.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo

  alias Neptuner.Calendar.Meeting

  def list_meetings(user_id) do
    Meeting
    |> where([m], m.user_id == ^user_id)
    |> order_by([m], desc: m.scheduled_at)
    |> Repo.all()
  end

  def list_meetings_for_date_range(user_id, start_date, end_date) do
    Meeting
    |> where([m], m.user_id == ^user_id)
    |> where([m], m.scheduled_at >= ^start_date and m.scheduled_at <= ^end_date)
    |> order_by([m], asc: m.scheduled_at)
    |> Repo.all()
  end

  def list_meetings_by_type(user_id, meeting_type) do
    Meeting
    |> where([m], m.user_id == ^user_id and m.meeting_type == ^meeting_type)
    |> order_by([m], desc: m.scheduled_at)
    |> Repo.all()
  end

  def get_meeting!(id), do: Repo.get!(Meeting, id)

  def get_user_meeting!(user_id, id) do
    Meeting
    |> where([m], m.user_id == ^user_id and m.id == ^id)
    |> Repo.one!()
  end

  def create_meeting(user_id, service_connection_id, attrs \\ %{}) do
    %Meeting{}
    |> Meeting.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Ecto.Changeset.put_change(:service_connection_id, service_connection_id)
    |> Ecto.Changeset.put_change(:synced_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.insert()
  end

  def update_meeting(%Meeting{} = meeting, attrs) do
    meeting
    |> Meeting.changeset(attrs)
    |> Repo.update()
  end

  def delete_meeting(%Meeting{} = meeting) do
    Repo.delete(meeting)
  end

  def change_meeting(%Meeting{} = meeting, attrs \\ %{}) do
    Meeting.changeset(meeting, attrs)
  end

  def rate_meeting_productivity(%Meeting{} = meeting, score) when score in 1..10 do
    update_meeting(meeting, %{actual_productivity_score: score})
  end

  def mark_as_could_have_been_email(%Meeting{} = meeting, could_have_been \\ true) do
    update_meeting(meeting, %{could_have_been_email: could_have_been})
  end

  @doc """
  Creates or updates a meeting based on external_id from synced services.
  Used for Google Calendar, Microsoft Graph, etc. integration.
  """
  def upsert_meeting_by_external_id(user_id, service_connection_id, external_id, attrs) do
    case get_meeting_by_external_id(user_id, external_id) do
      nil ->
        # Create new meeting
        attrs_with_external_id = Map.put(attrs, :external_calendar_id, external_id)
        create_meeting(user_id, service_connection_id, attrs_with_external_id)

      meeting ->
        # Update existing meeting
        update_meeting(meeting, attrs)
    end
  end

  @doc """
  Gets a meeting by its external_id (from synced services).
  """
  def get_meeting_by_external_id(user_id, external_id) do
    Meeting
    |> where([m], m.user_id == ^user_id and m.external_calendar_id == ^external_id)
    |> Repo.one()
  end

  def get_meetings_needing_rating(user_id) do
    yesterday = DateTime.utc_now() |> DateTime.add(-1, :day)

    Meeting
    |> where([m], m.user_id == ^user_id)
    |> where([m], is_nil(m.actual_productivity_score))
    |> where([m], m.scheduled_at < ^yesterday)
    |> order_by([m], desc: m.scheduled_at)
    |> limit(10)
    |> Repo.all()
  end

  def get_meeting_statistics(user_id) do
    meetings = list_meetings(user_id)

    total_meetings = length(meetings)
    could_have_been_email = Enum.count(meetings, & &1.could_have_been_email)
    rated_meetings = Enum.filter(meetings, & &1.actual_productivity_score)
    total_duration = Enum.sum(Enum.map(meetings, &(&1.duration_minutes || 0)))

    average_productivity =
      if length(rated_meetings) > 0 do
        Enum.sum(Enum.map(rated_meetings, & &1.actual_productivity_score)) /
          length(rated_meetings)
      else
        nil
      end

    %{
      total_meetings: total_meetings,
      could_have_been_email_count: could_have_been_email,
      could_have_been_email_percentage: Meeting.could_have_been_email_percentage(meetings),
      total_hours_in_meetings: (total_duration / 60) |> Float.round(1),
      average_productivity_score:
        if(average_productivity, do: Float.round(average_productivity, 1)),
      rated_meetings: length(rated_meetings),
      unrated_meetings: total_meetings - length(rated_meetings),
      standup_meetings: Enum.count(meetings, &(&1.meeting_type == :standup)),
      all_hands_meetings: Enum.count(meetings, &(&1.meeting_type == :all_hands)),
      one_on_one_meetings: Enum.count(meetings, &(&1.meeting_type == :one_on_one)),
      brainstorm_meetings: Enum.count(meetings, &(&1.meeting_type == :brainstorm)),
      status_update_meetings: Enum.count(meetings, &(&1.meeting_type == :status_update)),
      other_meetings: Enum.count(meetings, &(&1.meeting_type == :other))
    }
  end

  def get_weekly_meeting_report(user_id) do
    week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)
    now = DateTime.utc_now()

    meetings = list_meetings_for_date_range(user_id, week_ago, now)

    %{
      week_meetings: length(meetings),
      week_hours:
        (Enum.sum(Enum.map(meetings, &(&1.duration_minutes || 0))) / 60) |> Float.round(1),
      week_could_have_been_email: Meeting.could_have_been_email_percentage(meetings),
      week_attendees: Enum.sum(Enum.map(meetings, & &1.attendee_count)),
      collective_human_hours_lost: calculate_collective_hours_lost(meetings)
    }
  end

  defp calculate_collective_hours_lost(meetings) do
    meetings
    |> Enum.filter(& &1.could_have_been_email)
    |> Enum.map(fn meeting ->
      duration_hours = (meeting.duration_minutes || 0) / 60
      duration_hours * meeting.attendee_count
    end)
    |> Enum.sum()
    |> then(&if &1 == 0, do: 0.0, else: &1)
    |> Float.round(1)
  end

  def sync_meeting_from_external(user_id, service_connection_id, external_data) do
    existing_meeting =
      Meeting
      |> where(
        [m],
        m.user_id == ^user_id and m.external_calendar_id == ^external_data.external_id
      )
      |> Repo.one()

    meeting_attrs = %{
      external_calendar_id: external_data.external_id,
      title: external_data.title,
      duration_minutes: external_data.duration_minutes,
      attendee_count: length(external_data.attendees || []),
      scheduled_at: external_data.start_time,
      meeting_type: classify_meeting_type(external_data.title)
    }

    case existing_meeting do
      nil ->
        create_meeting(user_id, service_connection_id, meeting_attrs)

      meeting ->
        update_meeting(meeting, meeting_attrs)
    end
  end

  defp classify_meeting_type(title) do
    title_lower = String.downcase(title)

    cond do
      String.contains?(title_lower, ["standup", "stand-up", "daily"]) ->
        :standup

      String.contains?(title_lower, ["all hands", "all-hands", "town hall", "company meeting"]) ->
        :all_hands

      String.contains?(title_lower, ["1:1", "one-on-one", "1 on 1", "check-in"]) ->
        :one_on_one

      String.contains?(title_lower, ["brainstorm", "ideation", "creative", "planning"]) ->
        :brainstorm

      String.contains?(title_lower, ["status", "update", "sync", "review"]) ->
        :status_update

      true ->
        :other
    end
  end
end
