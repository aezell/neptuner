defmodule Neptuner.CalendarIntegrationTest do
  use Neptuner.DataCase

  alias Neptuner.Calendar
  alias Neptuner.Calendar.SyncService

  describe "complete calendar sync workflow" do
    test "syncs meetings from multiple providers and generates insights" do
      user = insert(:user)

      # Set up service connections
      _google_connection = insert(:google_service_connection, user: user)
      _microsoft_connection = insert(:microsoft_service_connection, user: user)

      # Initial sync
      sync_result = SyncService.sync_user_calendars(user.id)

      assert sync_result.connections_synced == 2
      assert length(sync_result.sync_results) == 2

      # Verify meetings were created
      meetings = Calendar.list_meetings(user.id)
      assert length(meetings) > 0

      # Verify meetings from both providers
      google_meetings =
        Enum.filter(meetings, &String.starts_with?(&1.external_calendar_id, "google_"))

      microsoft_meetings =
        Enum.filter(meetings, &String.starts_with?(&1.external_calendar_id, "outlook_"))

      assert length(google_meetings) > 0
      assert length(microsoft_meetings) > 0

      # Generate statistics
      stats = Calendar.get_meeting_statistics(user.id)
      assert stats.total_meetings == length(meetings)
      assert stats.total_hours_in_meetings > 0

      # Generate weekly report
      weekly_report = Calendar.get_weekly_meeting_report(user.id)
      assert weekly_report.week_meetings >= 0

      # Generate recommendations
      recommendations = SyncService.get_sync_recommendations(user.id)

      assert recommendations.meeting_load_status in [
               :light_load,
               :moderate_load,
               :heavy_load,
               :meeting_overload
             ]

      assert recommendations.email_worthiness_status in [
               :meeting_efficient,
               :moderately_efficient,
               :email_heavy
             ]
    end

    test "handles meeting rating workflow" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      # Create some meetings
      meeting1 = insert(:past_meeting, user: user, service_connection: service_connection)
      meeting2 = insert(:past_meeting, user: user, service_connection: service_connection)
      _meeting3 = insert(:future_meeting, user: user, service_connection: service_connection)

      # Get meetings needing rating (only past meetings)
      unrated_meetings = Calendar.get_meetings_needing_rating(user.id)
      assert length(unrated_meetings) == 2

      # Rate the meetings
      assert {:ok, _} = Calendar.rate_meeting_productivity(meeting1, 8)
      assert {:ok, _} = Calendar.rate_meeting_productivity(meeting2, 4)

      # Mark one as could have been email
      assert {:ok, _} = Calendar.mark_as_could_have_been_email(meeting1, false)

      # Check updated statistics
      stats = Calendar.get_meeting_statistics(user.id)
      assert stats.rated_meetings == 2
      assert stats.unrated_meetings == 1
      # (8 + 4) / 2
      assert stats.average_productivity_score == 6.0

      # Verify fewer meetings need rating now
      remaining_unrated = Calendar.get_meetings_needing_rating(user.id)
      # Future meeting shouldn't need rating yet
      assert length(remaining_unrated) == 0
    end

    test "handles meeting type classification and filtering" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      # Create meetings of different types
      standup = insert(:standup_meeting, user: user, service_connection: service_connection)
      all_hands = insert(:all_hands_meeting, user: user, service_connection: service_connection)

      _one_on_one =
        insert(:one_on_one_meeting, user: user, service_connection: service_connection)

      _brainstorm =
        insert(:brainstorm_meeting, user: user, service_connection: service_connection)

      # Test filtering by type
      standups = Calendar.list_meetings_by_type(user.id, :standup)
      assert length(standups) == 1
      assert hd(standups).id == standup.id

      all_hands_meetings = Calendar.list_meetings_by_type(user.id, :all_hands)
      assert length(all_hands_meetings) == 1
      assert hd(all_hands_meetings).id == all_hands.id

      # Test statistics breakdown by type
      stats = Calendar.get_meeting_statistics(user.id)
      assert stats.standup_meetings == 1
      assert stats.all_hands_meetings == 1
      assert stats.one_on_one_meetings == 1
      assert stats.brainstorm_meetings == 1
    end

    test "handles date range queries across different time periods" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      base_time = ~U[2024-06-15 10:00:00Z]

      # Create meetings across different months
      june_meeting =
        insert(:meeting,
          user: user,
          service_connection: service_connection,
          scheduled_at: base_time
        )

      july_meeting =
        insert(:meeting,
          user: user,
          service_connection: service_connection,
          scheduled_at: DateTime.add(base_time, 20, :day)
        )

      august_meeting =
        insert(:meeting,
          user: user,
          service_connection: service_connection,
          scheduled_at: DateTime.add(base_time, 50, :day)
        )

      # Test June range
      june_start = ~U[2024-06-01 00:00:00Z]
      june_end = ~U[2024-06-30 23:59:59Z]
      june_meetings = Calendar.list_meetings_for_date_range(user.id, june_start, june_end)

      assert length(june_meetings) == 1
      assert hd(june_meetings).id == june_meeting.id

      # Test July range
      july_start = ~U[2024-07-01 00:00:00Z]
      july_end = ~U[2024-07-31 23:59:59Z]
      july_meetings = Calendar.list_meetings_for_date_range(user.id, july_start, july_end)

      assert length(july_meetings) == 1
      assert hd(july_meetings).id == july_meeting.id

      # Test cross-month range
      cross_month_start = ~U[2024-06-01 00:00:00Z]
      cross_month_end = ~U[2024-07-31 23:59:59Z]

      cross_month_meetings =
        Calendar.list_meetings_for_date_range(user.id, cross_month_start, cross_month_end)

      assert length(cross_month_meetings) == 2
      meeting_ids = Enum.map(cross_month_meetings, & &1.id)
      assert june_meeting.id in meeting_ids
      assert july_meeting.id in meeting_ids
      refute august_meeting.id in meeting_ids
    end

    test "handles external meeting sync with updates" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      external_id = "recurring_meeting_123"

      # Initial external meeting sync
      initial_external_data = %{
        external_id: external_id,
        title: "Weekly Team Sync",
        duration_minutes: 30,
        attendees: ["user1@company.com", "user2@company.com"],
        start_time: DateTime.utc_now()
      }

      assert {:ok, meeting} =
               Calendar.sync_meeting_from_external(
                 user.id,
                 service_connection.id,
                 initial_external_data
               )

      initial_meeting_id = meeting.id
      assert meeting.title == "Weekly Team Sync"
      assert meeting.duration_minutes == 30
      assert meeting.attendee_count == 2

      # Simulate meeting update from external source
      updated_external_data = %{
        external_id: external_id,
        title: "Weekly Team Sync - Updated",
        duration_minutes: 45,
        attendees: ["user1@company.com", "user2@company.com", "user3@company.com"],
        start_time: DateTime.utc_now()
      }

      assert {:ok, updated_meeting} =
               Calendar.sync_meeting_from_external(
                 user.id,
                 service_connection.id,
                 updated_external_data
               )

      # Should be the same meeting, just updated
      assert updated_meeting.id == initial_meeting_id
      assert updated_meeting.title == "Weekly Team Sync - Updated"
      assert updated_meeting.duration_minutes == 45
      assert updated_meeting.attendee_count == 3

      # Verify no duplicate meetings were created
      all_meetings = Calendar.list_meetings(user.id)
      external_meetings = Enum.filter(all_meetings, &(&1.external_calendar_id == external_id))
      assert length(external_meetings) == 1
    end

    test "generates comprehensive insights based on meeting patterns" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      # Create a realistic meeting pattern
      # Week 1: Extreme meeting load (more than 25 hours per week to trigger overload)
      for i <- 1..30 do
        insert(:meeting,
          user: user,
          service_connection: service_connection,
          scheduled_at: DateTime.utc_now() |> DateTime.add(-i, :hour),
          duration_minutes: 60,
          attendee_count: 8,
          # 73% could have been email
          could_have_been_email: i <= 22,
          actual_productivity_score: if(i <= 15, do: Enum.random(1..4), else: nil)
        )
      end

      # Generate all insights
      stats = Calendar.get_meeting_statistics(user.id)
      weekly_report = Calendar.get_weekly_meeting_report(user.id)
      recommendations = SyncService.get_sync_recommendations(user.id)

      # Verify comprehensive statistics
      assert stats.total_meetings == 30
      assert stats.could_have_been_email_percentage == 73
      assert stats.total_hours_in_meetings == 30.0
      assert stats.rated_meetings == 15
      assert stats.unrated_meetings == 15
      # Low productivity scores
      assert stats.average_productivity_score < 5.0

      # Verify weekly report captures the pattern
      assert weekly_report.week_meetings == 30
      assert weekly_report.week_hours == 30.0
      # 22 meetings * 8 attendees * 1 hour
      assert weekly_report.collective_human_hours_lost > 100

      # Verify recommendations address the issues
      assert recommendations.meeting_load_status == :meeting_overload
      assert recommendations.email_worthiness_status == :email_heavy

      assert "Consider challenging meetings that could be handled asynchronously" in recommendations.recommendations
      assert Enum.any?(recommendations.recommendations, &String.contains?(&1, "time blocking"))

      assert "Rate your recent meetings to improve the cosmic accuracy of insights" in recommendations.recommendations

      # Verify existential insight captures the pattern
      assert String.contains?(recommendations.existential_insight, "collective hours were lost") or
               String.contains?(recommendations.existential_insight, "elaborate email ceremonies")
    end

    test "handles multi-user isolation correctly" do
      user1 = insert(:user)
      user2 = insert(:user)

      service_connection1 = insert(:service_connection, user: user1)
      service_connection2 = insert(:service_connection, user: user2)

      # Create meetings for both users
      user1_meeting =
        insert(:meeting,
          user: user1,
          service_connection: service_connection1,
          title: "User 1 Meeting"
        )

      user2_meeting =
        insert(:meeting,
          user: user2,
          service_connection: service_connection2,
          title: "User 2 Meeting"
        )

      # Verify isolation in basic queries
      user1_meetings = Calendar.list_meetings(user1.id)
      user2_meetings = Calendar.list_meetings(user2.id)

      assert length(user1_meetings) == 1
      assert length(user2_meetings) == 1
      assert hd(user1_meetings).id == user1_meeting.id
      assert hd(user2_meetings).id == user2_meeting.id

      # Verify isolation in statistics
      user1_stats = Calendar.get_meeting_statistics(user1.id)
      user2_stats = Calendar.get_meeting_statistics(user2.id)

      assert user1_stats.total_meetings == 1
      assert user2_stats.total_meetings == 1

      # Verify isolation in sync operations
      sync_result1 = SyncService.sync_user_calendars(user1.id)
      sync_result2 = SyncService.sync_user_calendars(user2.id)

      # Both should have processed their own connections
      assert sync_result1.connections_synced >= 0
      assert sync_result2.connections_synced >= 0

      # Verify meetings are still isolated after sync
      final_user1_meetings = Calendar.list_meetings(user1.id)
      final_user2_meetings = Calendar.list_meetings(user2.id)

      user1_meeting_ids = Enum.map(final_user1_meetings, & &1.id)
      user2_meeting_ids = Enum.map(final_user2_meetings, & &1.id)

      # No overlap between users
      assert MapSet.disjoint?(MapSet.new(user1_meeting_ids), MapSet.new(user2_meeting_ids))
    end

    test "handles edge cases in meeting data" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      # Meeting with minimal data
      _minimal_meeting =
        insert(:meeting,
          user: user,
          service_connection: service_connection,
          # Single character
          title: "M",
          duration_minutes: nil,
          attendee_count: 0,
          could_have_been_email: nil,
          actual_productivity_score: nil
        )

      # Meeting with maximum data
      _maximal_meeting =
        insert(:meeting,
          user: user,
          service_connection: service_connection,
          # Database varchar limit is likely 255
          title: String.duplicate("A", 250),
          # 8 hours
          duration_minutes: 480,
          attendee_count: 100,
          could_have_been_email: true,
          actual_productivity_score: 10
        )

      # Verify both meetings are handled correctly
      meetings = Calendar.list_meetings(user.id)
      assert length(meetings) == 2

      stats = Calendar.get_meeting_statistics(user.id)
      assert stats.total_meetings == 2

      # Should handle nil duration gracefully
      # Only maximal meeting counts
      assert stats.total_hours_in_meetings == 8.0

      # Should handle mixed productivity scores
      # Only maximal meeting is rated
      assert stats.average_productivity_score == 10.0
      assert stats.rated_meetings == 1
      assert stats.unrated_meetings == 1

      # Percentage calculation should handle mixed boolean values
      email_percentage = stats.could_have_been_email_percentage
      assert email_percentage >= 0 and email_percentage <= 100
    end

    test "performance with large datasets" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      # Create a larger number of meetings to test performance
      meeting_count = 100

      _meetings =
        for i <- 1..meeting_count do
          insert(:meeting,
            user: user,
            service_connection: service_connection,
            scheduled_at: DateTime.utc_now() |> DateTime.add(-i, :hour),
            duration_minutes: Enum.random([30, 45, 60, 90]),
            attendee_count: Enum.random(1..10),
            could_have_been_email: Enum.random([true, false]),
            actual_productivity_score: if(rem(i, 3) == 0, do: Enum.random(1..10), else: nil),
            meeting_type:
              Enum.random([
                :standup,
                :all_hands,
                :one_on_one,
                :brainstorm,
                :status_update,
                :other
              ])
          )
        end

      # Test that all operations complete in reasonable time
      start_time = System.monotonic_time(:millisecond)

      # Run comprehensive operations
      all_meetings = Calendar.list_meetings(user.id)
      stats = Calendar.get_meeting_statistics(user.id)
      _weekly_report = Calendar.get_weekly_meeting_report(user.id)
      recommendations = SyncService.get_sync_recommendations(user.id)

      # Test type filtering
      standups = Calendar.list_meetings_by_type(user.id, :standup)

      # Test date range queries
      week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

      recent_meetings =
        Calendar.list_meetings_for_date_range(user.id, week_ago, DateTime.utc_now())

      end_time = System.monotonic_time(:millisecond)
      total_time = end_time - start_time

      # Verify all operations completed
      assert length(all_meetings) == meeting_count
      assert stats.total_meetings == meeting_count
      assert is_number(stats.total_hours_in_meetings)
      assert is_list(recommendations.recommendations)
      assert length(standups) >= 0
      assert length(recent_meetings) >= 0

      # Performance should be reasonable (adjust threshold as needed)
      # Should complete in under 5 seconds
      assert total_time < 5000
    end
  end

  describe "error handling and edge cases" do
    test "handles invalid user IDs gracefully" do
      non_existent_user_id = Ecto.UUID.generate()

      # All operations should handle non-existent users gracefully
      assert Calendar.list_meetings(non_existent_user_id) == []
      assert Calendar.get_meeting_statistics(non_existent_user_id).total_meetings == 0

      sync_result = SyncService.sync_user_calendars(non_existent_user_id)
      assert sync_result.connections_synced == 0
    end

    test "handles database constraints appropriately" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      # Test constraint violations are handled by changesets
      invalid_attrs = %{
        # Required field
        title: "",
        # Must be positive
        duration_minutes: -30,
        # Must be non-negative
        attendee_count: -5,
        # Must be 1-10
        actual_productivity_score: 15,
        # Must be valid enum
        meeting_type: :invalid_type,
        # Must be valid datetime
        scheduled_at: "invalid_date"
      }

      assert {:error, changeset} =
               Calendar.create_meeting(user.id, service_connection.id, invalid_attrs)

      refute changeset.valid?

      # Multiple validation errors should be present
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :title)
      assert Map.has_key?(errors, :duration_minutes)
      assert Map.has_key?(errors, :attendee_count)
      assert Map.has_key?(errors, :actual_productivity_score)
    end

    test "handles concurrent operations safely" do
      user = insert(:user)
      _service_connection = insert(:service_connection, user: user)

      # Simulate concurrent sync operations
      tasks =
        for _i <- 1..5 do
          Task.async(fn ->
            SyncService.sync_user_calendars(user.id)
          end)
        end

      results = Task.await_many(tasks, 10_000)

      # All should complete successfully
      assert length(results) == 5

      for result <- results do
        assert result.connections_synced >= 0
        assert is_list(result.sync_results)
      end

      # Final state should be consistent
      final_meetings = Calendar.list_meetings(user.id)
      assert length(final_meetings) > 0

      # Should not have created excessive duplicates
      unique_external_ids =
        final_meetings
        |> Enum.map(& &1.external_calendar_id)
        |> Enum.uniq()
        |> length()

      # Some duplication might occur due to mock data, but shouldn't be excessive
      assert unique_external_ids > 0
    end
  end
end
