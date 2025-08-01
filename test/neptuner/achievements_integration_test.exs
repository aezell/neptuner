defmodule Neptuner.AchievementsIntegrationTest do
  use Neptuner.DataCase

  alias Neptuner.Achievements
  alias Neptuner.Achievements.{Achievement, UserAchievement}

  describe "full achievement lifecycle" do
    test "user progresses through achievement completion cycle" do
      user = insert(:user)

      achievement =
        insert(:achievement,
          key: "test_achievement",
          threshold_value: 10,
          threshold_type: "count"
        )

      # Initial state - no user achievement exists
      assert is_nil(Achievements.get_user_achievement_by_key(user.id, "test_achievement"))

      # First progress update - creates user achievement
      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_achievement", 3)

      assert user_achievement.progress_value == 3
      assert is_nil(user_achievement.completed_at)
      assert is_nil(user_achievement.notified_at)

      # Progress continues but not completed yet
      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_achievement", 8)

      assert user_achievement.progress_value == 8
      assert is_nil(user_achievement.completed_at)

      # Final progress - achievement completed
      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_achievement", 15)

      assert user_achievement.progress_value == 15
      assert user_achievement.completed_at
      assert is_nil(user_achievement.notified_at)

      # Mark as notified
      assert {:ok, user_achievement} =
               Achievements.mark_achievement_notified(user.id, "test_achievement")

      assert user_achievement.notified_at

      # Verify helper functions work correctly
      assert UserAchievement.completed?(user_achievement)
      assert UserAchievement.notified?(user_achievement)
      assert UserAchievement.progress_percentage(user_achievement, achievement) == 100
    end

    test "achievement completion with nil threshold_value" do
      user = insert(:user)

      achievement =
        insert(:achievement,
          key: "instant_achievement",
          threshold_value: nil
        )

      # Any progress should complete the achievement immediately
      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "instant_achievement", 1)

      assert user_achievement.progress_value == 1
      assert user_achievement.completed_at
      assert UserAchievement.progress_percentage(user_achievement, achievement) == 100
    end

    test "multiple users progressing on same achievement" do
      user1 = insert(:user)
      user2 = insert(:user)

      _achievement =
        insert(:achievement,
          key: "shared_achievement",
          threshold_value: 5
        )

      # User 1 makes progress
      assert {:ok, ua1} =
               Achievements.create_or_update_user_achievement(user1.id, "shared_achievement", 3)

      # User 2 makes different progress
      assert {:ok, ua2} =
               Achievements.create_or_update_user_achievement(user2.id, "shared_achievement", 7)

      # Verify they have separate records
      assert ua1.id != ua2.id
      assert ua1.progress_value == 3
      assert ua2.progress_value == 7
      assert is_nil(ua1.completed_at)
      # User 2 completed it
      assert ua2.completed_at
    end

    test "achievement statistics update correctly as user progresses" do
      user = insert(:user)
      insert(:achievement, key: "achievement_1", threshold_value: 10)
      insert(:achievement, key: "achievement_2", threshold_value: 5)
      insert(:achievement, key: "achievement_3", threshold_value: 15)

      # Initial stats - no progress
      stats = Achievements.get_achievement_statistics(user.id)
      assert stats.total_achievements == 3
      assert stats.completed == 0
      assert stats.in_progress == 0
      assert stats.completion_percentage == 0

      # Start progress on one achievement
      Achievements.create_or_update_user_achievement(user.id, "achievement_1", 5)

      stats = Achievements.get_achievement_statistics(user.id)
      assert stats.total_achievements == 3
      assert stats.completed == 0
      assert stats.in_progress == 1
      assert stats.completion_percentage == 0

      # Complete one achievement
      Achievements.create_or_update_user_achievement(user.id, "achievement_1", 12)

      stats = Achievements.get_achievement_statistics(user.id)
      assert stats.total_achievements == 3
      assert stats.completed == 1
      assert stats.in_progress == 0
      # 1/3 * 100
      assert stats.completion_percentage == 33

      # Start progress on another
      Achievements.create_or_update_user_achievement(user.id, "achievement_2", 3)

      stats = Achievements.get_achievement_statistics(user.id)
      assert stats.total_achievements == 3
      assert stats.completed == 1
      assert stats.in_progress == 1
      assert stats.completion_percentage == 33
    end
  end

  describe "achievement querying and filtering" do
    test "list_user_achievements with various filters" do
      user = insert(:user)
      task_achievement = insert(:task_achievement)
      habit_achievement = insert(:habit_achievement)

      # Create user achievements in different states
      completed_task_ua =
        insert(:completed_user_achievement,
          user: user,
          achievement: task_achievement,
          completed_at: DateTime.utc_now() |> DateTime.add(-1, :day)
        )

      in_progress_habit_ua =
        insert(:user_achievement,
          user: user,
          achievement: habit_achievement,
          progress_value: 5,
          completed_at: nil
        )

      # Test no filters - should return all user achievements with achievements preloaded
      all_achievements = Achievements.list_user_achievements(user.id)
      assert length(all_achievements) == 2

      # Should be ordered by completed_at desc, then category/title
      # Find completed and in-progress achievements in the result
      completed_results = Enum.filter(all_achievements, & &1.completed_at)
      in_progress_results = Enum.filter(all_achievements, &is_nil(&1.completed_at))

      assert length(completed_results) == 1
      assert length(in_progress_results) == 1
      assert hd(completed_results).id == completed_task_ua.id
      assert hd(in_progress_results).id == in_progress_habit_ua.id

      # Verify achievements are preloaded
      for ua <- all_achievements do
        assert %Achievement{} = ua.achievement
      end

      # Test category filter
      task_achievements = Achievements.list_user_achievements(user.id, category: "tasks")
      assert length(task_achievements) == 1
      assert hd(task_achievements).achievement.category == "tasks"

      # Test completed only filter
      completed_achievements = Achievements.list_user_achievements(user.id, completed_only: true)
      assert length(completed_achievements) == 1
      assert hd(completed_achievements).id == completed_task_ua.id

      # Test without achievement preloading
      minimal_achievements =
        Achievements.list_user_achievements(user.id, include_achievement: false)

      assert length(minimal_achievements) == 2

      for ua <- minimal_achievements do
        refute Ecto.assoc_loaded?(ua.achievement)
      end
    end

    test "achievement listing with category and active filters" do
      insert(:achievement, category: "tasks", key: "task_active", is_active: true)
      insert(:achievement, category: "tasks", key: "task_inactive", is_active: false)
      insert(:achievement, category: "habits", key: "habit_active", is_active: true)

      # Default - active only
      active_achievements = Achievements.list_achievements()
      assert length(active_achievements) == 2
      assert Enum.all?(active_achievements, & &1.is_active)

      # All achievements
      all_achievements = Achievements.list_achievements(active_only: false)
      assert length(all_achievements) == 3

      # Category filter with active achievements
      task_achievements = Achievements.list_achievements(category: "tasks", active_only: true)
      assert length(task_achievements) == 1

      # Category filter with all achievements  
      all_task_achievements =
        Achievements.list_achievements(category: "tasks", active_only: false)

      assert length(all_task_achievements) == 2
    end
  end

  describe "edge cases and error handling" do
    test "handles concurrent updates to same user achievement" do
      user = insert(:user)
      _achievement = insert(:achievement, key: "concurrent_test", threshold_value: 10)

      # Create initial user achievement
      {:ok, _} = Achievements.create_or_update_user_achievement(user.id, "concurrent_test", 5)

      # Multiple updates should work (simulating concurrent access)
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            Achievements.create_or_update_user_achievement(user.id, "concurrent_test", 5 + i)
          end)
        end

      results = Task.await_many(tasks, 5000)

      # All should succeed
      assert Enum.all?(results, fn result -> match?({:ok, _}, result) end)

      # Final state should be consistent
      final_ua = Achievements.get_user_achievement_by_key(user.id, "concurrent_test")
      # At least one update succeeded
      assert final_ua.progress_value >= 6
    end

    test "handles achievement key that doesn't exist" do
      user = insert(:user)

      assert_raise Ecto.NoResultsError, fn ->
        Achievements.create_or_update_user_achievement(user.id, "nonexistent_key", 5)
      end
    end

    test "handles user that doesn't exist" do
      _achievement = insert(:achievement, key: "test_key")

      # This will fail with a foreign key constraint error due to invalid user_id
      invalid_user_id = Ecto.UUID.generate()

      assert_raise Ecto.ConstraintError, fn ->
        Achievements.create_or_update_user_achievement(invalid_user_id, "test_key", 5)
      end
    end

    test "handles achievement deletion cascade" do
      user = insert(:user)
      achievement = insert(:achievement)
      user_achievement = insert(:user_achievement, user: user, achievement: achievement)

      # Delete the achievement
      {:ok, _} = Achievements.delete_achievement(achievement)

      # User achievement should be deleted due to cascade
      refute Repo.get(UserAchievement, user_achievement.id)
    end

    test "achievement progress percentage edge cases" do
      # Zero threshold
      achievement_zero = build(:achievement, threshold_value: 0)
      ua_not_completed = build(:user_achievement, progress_value: 5, completed_at: nil)
      ua_completed = build(:user_achievement, progress_value: 5, completed_at: DateTime.utc_now())

      assert UserAchievement.progress_percentage(ua_not_completed, achievement_zero) == 0
      assert UserAchievement.progress_percentage(ua_completed, achievement_zero) == 100

      # Nil threshold  
      achievement_nil = build(:achievement, threshold_value: nil)
      assert UserAchievement.progress_percentage(ua_not_completed, achievement_nil) == 0
      assert UserAchievement.progress_percentage(ua_completed, achievement_nil) == 100

      # Very large progress vs small threshold
      achievement_small = build(:achievement, threshold_value: 1)
      ua_large_progress = build(:user_achievement, progress_value: 1000)
      assert UserAchievement.progress_percentage(ua_large_progress, achievement_small) == 100
    end
  end

  describe "data consistency and relationships" do
    test "user achievement unique constraint enforcement" do
      user = insert(:user)
      achievement = insert(:achievement)

      # First insertion should succeed
      assert {:ok, _} =
               Repo.insert(%UserAchievement{
                 user_id: user.id,
                 achievement_id: achievement.id,
                 progress_value: 5
               })

      # Second insertion with same user_id/achievement_id should fail
      changeset =
        UserAchievement.changeset(
          %UserAchievement{
            user_id: user.id,
            achievement_id: achievement.id
          },
          %{progress_value: 10}
        )

      assert {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).user_id
    end

    test "achievement key unique constraint enforcement" do
      # First achievement with key should succeed
      assert {:ok, _} =
               Achievements.create_achievement(%{
                 key: "unique_test",
                 title: "First Achievement",
                 description: "First description",
                 category: "tasks"
               })

      # Second achievement with same key should fail
      assert {:error, changeset} =
               Achievements.create_achievement(%{
                 key: "unique_test",
                 title: "Second Achievement",
                 description: "Second description",
                 category: "habits"
               })

      assert "has already been taken" in errors_on(changeset).key
    end

    test "cascading deletes work properly" do
      achievement = insert(:achievement)
      user1 = insert(:user)
      user2 = insert(:user)

      ua1 = insert(:user_achievement, user: user1, achievement: achievement)
      ua2 = insert(:user_achievement, user: user2, achievement: achievement)

      # Delete achievement should cascade to user achievements
      Achievements.delete_achievement(achievement)

      refute Repo.get(UserAchievement, ua1.id)
      refute Repo.get(UserAchievement, ua2.id)
      refute Repo.get(Achievement, achievement.id)
    end
  end
end
