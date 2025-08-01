defmodule Neptuner.CalendarTest do
  use Neptuner.DataCase

  alias Neptuner.Calendar

  describe "list_meetings/1" do
    test "returns all meetings for a user ordered by scheduled_at desc" do
      user = insert(:user)
      other_user = insert(:user)

      # Create meetings for the user
      old_meeting = insert(:meeting, user: user, scheduled_at: ~U[2024-01-01 10:00:00Z])
      new_meeting = insert(:meeting, user: user, scheduled_at: ~U[2024-01-02 10:00:00Z])

      # Create meeting for another user (should not be returned)
      insert(:meeting, user: other_user)

      meetings = Calendar.list_meetings(user.id)

      assert length(meetings) == 2

      # Verify meetings are ordered by scheduled_at desc (newest first)
      meeting_ids = Enum.map(meetings, & &1.id)
      assert new_meeting.id in meeting_ids
      assert old_meeting.id in meeting_ids

      # Verify ordering: new_meeting should come first (desc order)
      assert hd(meetings).id == new_meeting.id
    end

    test "returns empty list when user has no meetings" do
      user = insert(:user)

      meetings = Calendar.list_meetings(user.id)

      assert meetings == []
    end
  end

  describe "list_meetings_for_date_range/3" do
    test "returns meetings within date range ordered by scheduled_at asc" do
      user = insert(:user)

      # Create meetings at different times
      before_range = insert(:meeting, user: user, scheduled_at: ~U[2024-01-01 10:00:00Z])
      in_range_1 = insert(:meeting, user: user, scheduled_at: ~U[2024-01-02 10:00:00Z])
      in_range_2 = insert(:meeting, user: user, scheduled_at: ~U[2024-01-03 10:00:00Z])
      after_range = insert(:meeting, user: user, scheduled_at: ~U[2024-01-05 10:00:00Z])

      start_date = ~U[2024-01-02 00:00:00Z]
      end_date = ~U[2024-01-04 00:00:00Z]

      meetings = Calendar.list_meetings_for_date_range(user.id, start_date, end_date)

      assert length(meetings) == 2

      # Verify correct meetings are included (ordered by scheduled_at asc)
      meeting_ids = Enum.map(meetings, & &1.id)
      assert in_range_1.id in meeting_ids
      assert in_range_2.id in meeting_ids
      refute Enum.any?(meeting_ids, &(&1 == before_range.id))
      refute Enum.any?(meeting_ids, &(&1 == after_range.id))

      # Verify ascending order
      assert hd(meetings).id == in_range_1.id
    end

    test "includes meetings exactly at range boundaries" do
      user = insert(:user)

      start_date = ~U[2024-01-02 10:00:00Z]
      end_date = ~U[2024-01-03 10:00:00Z]

      at_start = insert(:meeting, user: user, scheduled_at: start_date)
      at_end = insert(:meeting, user: user, scheduled_at: end_date)

      meetings = Calendar.list_meetings_for_date_range(user.id, start_date, end_date)

      assert length(meetings) == 2
      meeting_ids = Enum.map(meetings, & &1.id)
      assert at_start.id in meeting_ids
      assert at_end.id in meeting_ids
    end
  end

  describe "list_meetings_by_type/2" do
    test "returns meetings of specific type for user" do
      user = insert(:user)
      other_user = insert(:user)

      standup1 = insert(:standup_meeting, user: user)
      standup2 = insert(:standup_meeting, user: user)
      insert(:all_hands_meeting, user: user)
      insert(:standup_meeting, user: other_user)

      standups = Calendar.list_meetings_by_type(user.id, :standup)

      assert length(standups) == 2
      meeting_ids = Enum.map(standups, & &1.id)
      assert standup1.id in meeting_ids
      assert standup2.id in meeting_ids
    end

    test "returns empty list when no meetings of type exist" do
      user = insert(:user)
      insert(:standup_meeting, user: user)

      brainstorms = Calendar.list_meetings_by_type(user.id, :brainstorm)

      assert brainstorms == []
    end
  end

  describe "get_meeting!/1" do
    test "returns meeting by id" do
      meeting = insert(:meeting)

      result = Calendar.get_meeting!(meeting.id)

      assert result.id == meeting.id
      assert result.title == meeting.title
    end

    test "raises when meeting doesn't exist" do
      non_existent_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        Calendar.get_meeting!(non_existent_id)
      end
    end
  end

  describe "get_user_meeting!/2" do
    test "returns meeting belonging to user" do
      user = insert(:user)
      meeting = insert(:meeting, user: user)

      result = Calendar.get_user_meeting!(user.id, meeting.id)

      assert result.id == meeting.id
    end

    test "raises when meeting doesn't belong to user" do
      user = insert(:user)
      other_user = insert(:user)
      meeting = insert(:meeting, user: other_user)

      assert_raise Ecto.NoResultsError, fn ->
        Calendar.get_user_meeting!(user.id, meeting.id)
      end
    end

    test "raises when meeting doesn't exist" do
      user = insert(:user)
      non_existent_id = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        Calendar.get_user_meeting!(user.id, non_existent_id)
      end
    end
  end

  describe "create_meeting/3" do
    test "creates meeting with valid attrs" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      attrs = %{
        title: "Test Meeting",
        duration_minutes: 60,
        attendee_count: 5,
        meeting_type: :standup,
        scheduled_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      assert {:ok, meeting} = Calendar.create_meeting(user.id, service_connection.id, attrs)

      assert meeting.title == "Test Meeting"
      assert meeting.user_id == user.id
      assert meeting.service_connection_id == service_connection.id
      assert meeting.synced_at != nil
    end

    test "returns error with invalid attrs" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      # Missing required scheduled_at
      attrs = %{title: ""}

      assert {:error, changeset} = Calendar.create_meeting(user.id, service_connection.id, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).scheduled_at
    end

    test "sets synced_at timestamp automatically" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      before_create = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        title: "Test Meeting",
        scheduled_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      assert {:ok, meeting} = Calendar.create_meeting(user.id, service_connection.id, attrs)

      # synced_at should be set and not be before our test started
      assert meeting.synced_at != nil
      assert DateTime.compare(meeting.synced_at, before_create) in [:eq, :gt]
    end
  end

  describe "update_meeting/2" do
    test "updates meeting with valid attrs" do
      meeting = insert(:meeting, title: "Old Title")

      attrs = %{title: "New Title", duration_minutes: 90}

      assert {:ok, updated_meeting} = Calendar.update_meeting(meeting, attrs)

      assert updated_meeting.title == "New Title"
      assert updated_meeting.duration_minutes == 90
      assert updated_meeting.id == meeting.id
    end

    test "returns error with invalid attrs" do
      meeting = insert(:meeting)

      attrs = %{title: "", duration_minutes: -10}

      assert {:error, changeset} = Calendar.update_meeting(meeting, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "must be greater than 0" in errors_on(changeset).duration_minutes
    end
  end

  describe "delete_meeting/1" do
    test "deletes the meeting" do
      meeting = insert(:meeting)

      assert {:ok, deleted_meeting} = Calendar.delete_meeting(meeting)

      assert deleted_meeting.id == meeting.id

      assert_raise Ecto.NoResultsError, fn ->
        Calendar.get_meeting!(meeting.id)
      end
    end
  end

  describe "change_meeting/2" do
    test "returns changeset for meeting" do
      meeting = insert(:meeting)

      changeset = Calendar.change_meeting(meeting)

      assert %Ecto.Changeset{} = changeset
      assert changeset.data.id == meeting.id
    end

    test "returns changeset with attrs" do
      meeting = insert(:meeting)
      attrs = %{title: "New Title"}

      changeset = Calendar.change_meeting(meeting, attrs)

      assert changeset.changes.title == "New Title"
    end
  end

  describe "rate_meeting_productivity/2" do
    test "updates meeting with productivity score" do
      meeting = insert(:meeting, actual_productivity_score: nil)

      assert {:ok, updated_meeting} = Calendar.rate_meeting_productivity(meeting, 8)

      assert updated_meeting.actual_productivity_score == 8
    end

    test "updates existing productivity score" do
      meeting = insert(:meeting, actual_productivity_score: 5)

      assert {:ok, updated_meeting} = Calendar.rate_meeting_productivity(meeting, 9)

      assert updated_meeting.actual_productivity_score == 9
    end

    test "validates score is in range 1-10" do
      meeting = insert(:meeting)

      for score <- 1..10 do
        assert {:ok, _} = Calendar.rate_meeting_productivity(meeting, score)
      end
    end
  end

  describe "mark_as_could_have_been_email/2" do
    test "marks meeting as could have been email" do
      meeting = insert(:meeting, could_have_been_email: false)

      assert {:ok, updated_meeting} = Calendar.mark_as_could_have_been_email(meeting, true)

      assert updated_meeting.could_have_been_email == true
    end

    test "marks meeting as could not have been email" do
      meeting = insert(:meeting, could_have_been_email: true)

      assert {:ok, updated_meeting} = Calendar.mark_as_could_have_been_email(meeting, false)

      assert updated_meeting.could_have_been_email == false
    end

    test "defaults to true when not specified" do
      meeting = insert(:meeting, could_have_been_email: false)

      assert {:ok, updated_meeting} = Calendar.mark_as_could_have_been_email(meeting)

      assert updated_meeting.could_have_been_email == true
    end
  end

  describe "upsert_meeting_by_external_id/4" do
    test "creates new meeting when external_id doesn't exist" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)
      external_id = "ext_123"

      attrs = %{
        title: "External Meeting",
        duration_minutes: 45,
        scheduled_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      assert {:ok, meeting} =
               Calendar.upsert_meeting_by_external_id(
                 user.id,
                 service_connection.id,
                 external_id,
                 attrs
               )

      assert meeting.title == "External Meeting"
      assert meeting.external_calendar_id == external_id
      assert meeting.user_id == user.id
    end

    test "updates existing meeting when external_id exists" do
      user = insert(:user)
      external_id = "ext_123"

      existing_meeting =
        insert(:meeting, user: user, external_calendar_id: external_id, title: "Old Title")

      service_connection = insert(:service_connection, user: user)

      attrs = %{title: "Updated Title", duration_minutes: 60}

      assert {:ok, updated_meeting} =
               Calendar.upsert_meeting_by_external_id(
                 user.id,
                 service_connection.id,
                 external_id,
                 attrs
               )

      assert updated_meeting.id == existing_meeting.id
      assert updated_meeting.title == "Updated Title"
      assert updated_meeting.external_calendar_id == external_id
    end
  end

  describe "get_meeting_by_external_id/2" do
    test "returns meeting with matching external_id for user" do
      user = insert(:user)
      external_id = "ext_123"
      meeting = insert(:meeting, user: user, external_calendar_id: external_id)

      result = Calendar.get_meeting_by_external_id(user.id, external_id)

      assert result.id == meeting.id
    end

    test "returns nil when no matching external_id" do
      user = insert(:user)

      result = Calendar.get_meeting_by_external_id(user.id, "nonexistent")

      assert result == nil
    end

    test "returns nil when external_id belongs to different user" do
      user = insert(:user)
      other_user = insert(:user)
      external_id = "ext_123"
      insert(:meeting, user: other_user, external_calendar_id: external_id)

      result = Calendar.get_meeting_by_external_id(user.id, external_id)

      assert result == nil
    end
  end

  describe "get_meetings_needing_rating/1" do
    test "returns unrated meetings older than yesterday" do
      user = insert(:user)

      # Create meetings at different times with different rating states
      old_unrated =
        insert(:unrated_meeting,
          user: user,
          scheduled_at: DateTime.utc_now() |> DateTime.add(-2, :day)
        )

      _old_rated =
        insert(:rated_meeting,
          user: user,
          scheduled_at: DateTime.utc_now() |> DateTime.add(-2, :day)
        )

      _recent_unrated =
        insert(:unrated_meeting,
          user: user,
          scheduled_at: DateTime.utc_now() |> DateTime.add(-5, :hour)
        )

      meetings = Calendar.get_meetings_needing_rating(user.id)

      assert length(meetings) == 1
      assert hd(meetings).id == old_unrated.id
    end

    test "limits results to 10 meetings" do
      user = insert(:user)

      # Create 15 old unrated meetings
      for i <- 1..15 do
        insert(:unrated_meeting,
          user: user,
          scheduled_at: DateTime.utc_now() |> DateTime.add(-i - 1, :day)
        )
      end

      meetings = Calendar.get_meetings_needing_rating(user.id)

      assert length(meetings) == 10
    end

    test "orders by scheduled_at desc (most recent first)" do
      user = insert(:user)

      older =
        insert(:unrated_meeting,
          user: user,
          scheduled_at: DateTime.utc_now() |> DateTime.add(-3, :day)
        )

      newer =
        insert(:unrated_meeting,
          user: user,
          scheduled_at: DateTime.utc_now() |> DateTime.add(-2, :day)
        )

      meetings = Calendar.get_meetings_needing_rating(user.id)

      assert length(meetings) == 2
      meeting_ids = Enum.map(meetings, & &1.id)
      assert newer.id in meeting_ids
      assert older.id in meeting_ids

      # Verify desc order (newer first)
      assert hd(meetings).id == newer.id
    end
  end

  describe "get_meeting_statistics/1" do
    test "calculates comprehensive meeting statistics" do
      user = insert(:user)

      # Create diverse meetings with explicit types
      insert(:could_have_been_email_meeting,
        user: user,
        duration_minutes: 60,
        meeting_type: :status_update
      )

      insert(:meeting,
        user: user,
        duration_minutes: 90,
        actual_productivity_score: 8,
        could_have_been_email: false,
        meeting_type: :other
      )

      insert(:standup_meeting,
        user: user,
        duration_minutes: 30,
        actual_productivity_score: 6,
        could_have_been_email: false
      )

      insert(:all_hands_meeting, user: user, duration_minutes: 60, could_have_been_email: true)
      insert(:one_on_one_meeting, user: user, duration_minutes: 30, could_have_been_email: false)

      stats = Calendar.get_meeting_statistics(user.id)

      assert stats.total_meetings == 5
      # status_update + all_hands 
      assert stats.could_have_been_email_count == 2
      # 270 minutes / 60
      assert stats.total_hours_in_meetings == 4.5
      # (8 + 6) / 2
      assert stats.average_productivity_score == 7.0
      assert stats.rated_meetings == 2
      assert stats.unrated_meetings == 3
      assert stats.standup_meetings == 1
      assert stats.all_hands_meetings == 1
      assert stats.one_on_one_meetings == 1
      assert stats.status_update_meetings == 1
      # the explicitly created :other meeting
      assert stats.other_meetings == 1
    end

    test "handles empty meeting list" do
      user = insert(:user)

      stats = Calendar.get_meeting_statistics(user.id)

      assert stats.total_meetings == 0
      assert stats.could_have_been_email_count == 0
      assert stats.total_hours_in_meetings == 0.0
      assert stats.average_productivity_score == nil
      assert stats.rated_meetings == 0
      assert stats.unrated_meetings == 0
    end

    test "handles meetings with nil duration" do
      user = insert(:user)
      insert(:meeting, user: user, duration_minutes: nil)
      insert(:meeting, user: user, duration_minutes: 60)

      stats = Calendar.get_meeting_statistics(user.id)

      # Only counts the 60-minute meeting
      assert stats.total_hours_in_meetings == 1.0
    end
  end

  describe "get_weekly_meeting_report/1" do
    test "generates weekly report for meetings" do
      user = insert(:user)

      # Create meetings in the last week
      _this_week_1 =
        insert(:this_week_meeting,
          user: user,
          duration_minutes: 60,
          attendee_count: 5,
          could_have_been_email: true
        )

      _this_week_2 =
        insert(:this_week_meeting,
          user: user,
          duration_minutes: 30,
          attendee_count: 3,
          could_have_been_email: false
        )

      # Create meeting outside the week range
      insert(:meeting,
        user: user,
        scheduled_at: DateTime.utc_now() |> DateTime.add(-8, :day)
      )

      report = Calendar.get_weekly_meeting_report(user.id)

      assert report.week_meetings == 2
      # 90 minutes / 60
      assert report.week_hours == 1.5
      assert report.week_attendees == 8
      # 1 hour * 5 attendees
      assert report.collective_human_hours_lost == 5.0
    end

    test "handles empty week" do
      user = insert(:user)

      report = Calendar.get_weekly_meeting_report(user.id)

      assert report.week_meetings == 0
      assert report.week_hours == 0.0
      assert report.week_attendees == 0
      assert report.collective_human_hours_lost == 0.0
    end
  end

  describe "sync_meeting_from_external/3" do
    test "creates new meeting from external data" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      external_data = %{
        external_id: "ext_meeting_123",
        title: "External Team Sync",
        duration_minutes: 45,
        attendees: ["user1@company.com", "user2@company.com", "user3@company.com"],
        start_time: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      assert {:ok, meeting} =
               Calendar.sync_meeting_from_external(user.id, service_connection.id, external_data)

      assert meeting.external_calendar_id == "ext_meeting_123"
      assert meeting.title == "External Team Sync"
      assert meeting.duration_minutes == 45
      assert meeting.attendee_count == 3
      # Classified from "sync" in title
      assert meeting.meeting_type == :status_update
    end

    test "updates existing meeting from external data" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      existing_meeting =
        insert(:meeting,
          user: user,
          external_calendar_id: "ext_meeting_123",
          title: "Old Title"
        )

      external_data = %{
        external_id: "ext_meeting_123",
        title: "Updated Team Sync",
        duration_minutes: 60,
        attendees: ["user1@company.com", "user2@company.com"],
        start_time: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      assert {:ok, updated_meeting} =
               Calendar.sync_meeting_from_external(user.id, service_connection.id, external_data)

      assert updated_meeting.id == existing_meeting.id
      assert updated_meeting.title == "Updated Team Sync"
      assert updated_meeting.duration_minutes == 60
      assert updated_meeting.attendee_count == 2
    end

    test "classifies meeting types correctly" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      test_cases = [
        {"Daily Standup", :standup},
        {"Stand-up Meeting", :standup},
        {"All Hands Meeting", :all_hands},
        {"Town Hall", :all_hands},
        {"1:1 with Manager", :one_on_one},
        {"One-on-one Check-in", :one_on_one},
        {"Brainstorming Session", :brainstorm},
        {"Creative Planning", :brainstorm},
        {"Status Update Meeting", :status_update},
        {"Weekly Sync", :status_update},
        {"Random Meeting", :other}
      ]

      for {title, expected_type} <- test_cases do
        external_data = %{
          external_id: "ext_#{:rand.uniform(10000)}",
          title: title,
          duration_minutes: 30,
          attendees: ["user@company.com"],
          start_time: DateTime.utc_now() |> DateTime.truncate(:second)
        }

        assert {:ok, meeting} =
                 Calendar.sync_meeting_from_external(
                   user.id,
                   service_connection.id,
                   external_data
                 )

        assert meeting.meeting_type == expected_type,
               "Title '#{title}' should classify as #{expected_type}"
      end
    end

    test "handles empty attendees list" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      external_data = %{
        external_id: "ext_solo_meeting",
        title: "Solo Planning",
        duration_minutes: 30,
        # No attendees
        attendees: nil,
        start_time: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      assert {:ok, meeting} =
               Calendar.sync_meeting_from_external(user.id, service_connection.id, external_data)

      assert meeting.attendee_count == 0
    end
  end
end
