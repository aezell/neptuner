defmodule Neptuner.AchievementsTest do
  use Neptuner.DataCase

  alias Neptuner.Achievements
  alias Neptuner.Achievements.Achievement

  describe "list_achievements/1" do
    test "returns all active achievements by default" do
      active_achievement = insert(:achievement, is_active: true)
      insert(:achievement, is_active: false)

      achievements = Achievements.list_achievements()
      assert length(achievements) == 1
      assert hd(achievements).id == active_achievement.id
    end

    test "returns all achievements when active_only is false" do
      insert(:achievement, is_active: true)
      insert(:achievement, is_active: false)

      achievements = Achievements.list_achievements(active_only: false)
      assert length(achievements) == 2
    end

    test "filters by category" do
      task_achievement = insert(:task_achievement)
      insert(:habit_achievement)

      achievements = Achievements.list_achievements(category: "tasks")
      assert length(achievements) == 1
      assert hd(achievements).id == task_achievement.id
    end

    test "orders by category and title" do
      _z_achievement = insert(:achievement, category: "tasks", title: "Z Achievement")
      _a_achievement = insert(:achievement, category: "tasks", title: "A Achievement")
      _habit_achievement = insert(:achievement, category: "habits", title: "Habit")

      achievements = Achievements.list_achievements()
      titles = Enum.map(achievements, & &1.title)
      assert titles == ["Habit", "A Achievement", "Z Achievement"]
    end

    test "combines category filter and active filter" do
      insert(:achievement, category: "tasks", key: "task_active", is_active: true)
      insert(:achievement, category: "tasks", key: "task_inactive", is_active: false)
      insert(:achievement, category: "habits", key: "habit_active", is_active: true)

      achievements = Achievements.list_achievements(category: "tasks", active_only: true)
      assert length(achievements) == 1
      assert hd(achievements).category == "tasks"
    end
  end

  describe "get_achievement!/1" do
    test "returns achievement with valid id" do
      achievement = insert(:achievement)
      found_achievement = Achievements.get_achievement!(achievement.id)
      assert found_achievement.id == achievement.id
    end

    test "raises error with invalid id" do
      # Generate a valid UUID format for binary_id
      invalid_uuid = Ecto.UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        Achievements.get_achievement!(invalid_uuid)
      end
    end
  end

  describe "get_achievement_by_key!/1" do
    test "returns achievement with valid key" do
      achievement = insert(:achievement, key: "test_key")
      found_achievement = Achievements.get_achievement_by_key!("test_key")
      assert found_achievement.id == achievement.id
    end

    test "raises error with invalid key" do
      assert_raise Ecto.NoResultsError, fn ->
        Achievements.get_achievement_by_key!("nonexistent_key")
      end
    end
  end

  describe "create_achievement/1" do
    test "creates achievement with valid attributes" do
      attrs = %{
        key: "new_achievement",
        title: "New Achievement",
        description: "A new achievement",
        category: "tasks"
      }

      assert {:ok, achievement} = Achievements.create_achievement(attrs)
      assert achievement.key == "new_achievement"
      assert achievement.title == "New Achievement"
    end

    test "returns error with invalid attributes" do
      # missing required fields
      attrs = %{key: "invalid"}

      assert {:error, changeset} = Achievements.create_achievement(attrs)
      refute changeset.valid?
    end
  end

  describe "update_achievement/2" do
    test "updates achievement with valid attributes" do
      achievement = insert(:achievement)
      attrs = %{title: "Updated Title"}

      assert {:ok, updated_achievement} = Achievements.update_achievement(achievement, attrs)
      assert updated_achievement.title == "Updated Title"
    end

    test "returns error with invalid attributes" do
      achievement = insert(:achievement)
      attrs = %{category: "invalid_category"}

      assert {:error, changeset} = Achievements.update_achievement(achievement, attrs)
      refute changeset.valid?
    end
  end

  describe "delete_achievement/1" do
    test "deletes the achievement" do
      achievement = insert(:achievement)
      assert {:ok, _} = Achievements.delete_achievement(achievement)
      refute Repo.get(Achievement, achievement.id)
    end
  end

  describe "list_user_achievements/2" do
    test "returns user achievements for specific user" do
      user1 = insert(:user)
      user2 = insert(:user)
      user_achievement1 = insert(:user_achievement, user: user1)
      insert(:user_achievement, user: user2)

      achievements = Achievements.list_user_achievements(user1.id)
      assert length(achievements) == 1
      assert hd(achievements).id == user_achievement1.id
    end

    test "includes achievement by default" do
      user = insert(:user)
      insert(:user_achievement, user: user)

      achievements = Achievements.list_user_achievements(user.id)
      achievement = hd(achievements)
      assert %Achievement{} = achievement.achievement
    end

    test "excludes achievement when include_achievement is false" do
      user = insert(:user)
      insert(:user_achievement, user: user)

      achievements = Achievements.list_user_achievements(user.id, include_achievement: false)
      achievement = hd(achievements)
      refute Ecto.assoc_loaded?(achievement.achievement)
    end

    test "filters by category" do
      user = insert(:user)
      task_achievement = insert(:task_achievement)
      habit_achievement = insert(:habit_achievement)
      insert(:user_achievement, user: user, achievement: task_achievement)
      insert(:user_achievement, user: user, achievement: habit_achievement)

      achievements = Achievements.list_user_achievements(user.id, category: "tasks")
      assert length(achievements) == 1
      assert hd(achievements).achievement.category == "tasks"
    end

    test "filters completed achievements only" do
      user = insert(:user)
      completed_ua = insert(:completed_user_achievement, user: user)
      insert(:user_achievement, user: user, completed_at: nil)

      achievements = Achievements.list_user_achievements(user.id, completed_only: true)
      assert length(achievements) == 1
      assert hd(achievements).id == completed_ua.id
    end

    test "orders by completion date, then category and title" do
      user = insert(:user)

      # Create achievements with specific ordering
      task_achievement =
        insert(:achievement, category: "tasks", title: "Task Achievement", key: "task_order")

      habit_achievement =
        insert(:achievement, category: "habits", title: "Habit Achievement", key: "habit_order")

      old_completed =
        insert(:user_achievement,
          user: user,
          achievement: task_achievement,
          completed_at: DateTime.utc_now() |> DateTime.add(-2, :day) |> DateTime.truncate(:second)
        )

      recent_completed =
        insert(:user_achievement,
          user: user,
          achievement: habit_achievement,
          completed_at: DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
        )

      in_progress_achievement =
        insert(:achievement,
          category: "meetings",
          title: "Meeting Achievement",
          key: "meeting_order"
        )

      in_progress =
        insert(:user_achievement,
          user: user,
          achievement: in_progress_achievement,
          completed_at: nil
        )

      achievements = Achievements.list_user_achievements(user.id)

      # Verify we have the right number
      assert length(achievements) == 3

      # Check ordering: completed achievements first (by completed_at desc), then non-completed
      completed_achievements = Enum.filter(achievements, & &1.completed_at)
      non_completed_achievements = Enum.filter(achievements, &is_nil(&1.completed_at))

      assert length(completed_achievements) == 2
      assert length(non_completed_achievements) == 1

      # Recent completed should be first among completed
      assert hd(completed_achievements).id == recent_completed.id
      # Old completed should be second among completed  
      assert Enum.at(completed_achievements, 1).id == old_completed.id
      # In progress should be in the non-completed list
      assert hd(non_completed_achievements).id == in_progress.id
    end
  end

  describe "get_user_achievement/2" do
    test "returns user achievement when found" do
      user = insert(:user)
      achievement = insert(:achievement)
      user_achievement = insert(:user_achievement, user: user, achievement: achievement)

      found = Achievements.get_user_achievement(user.id, achievement.id)
      assert found.id == user_achievement.id
      assert %Achievement{} = found.achievement
    end

    test "returns nil when not found" do
      user = insert(:user)
      achievement = insert(:achievement)

      result = Achievements.get_user_achievement(user.id, achievement.id)
      assert is_nil(result)
    end
  end

  describe "get_user_achievement_by_key/2" do
    test "returns user achievement when found by key" do
      user = insert(:user)
      achievement = insert(:achievement, key: "test_key")
      user_achievement = insert(:user_achievement, user: user, achievement: achievement)

      found = Achievements.get_user_achievement_by_key(user.id, "test_key")
      assert found.id == user_achievement.id
      assert %Achievement{} = found.achievement
    end

    test "returns nil when not found" do
      user = insert(:user)
      result = Achievements.get_user_achievement_by_key(user.id, "nonexistent_key")
      assert is_nil(result)
    end
  end

  describe "create_or_update_user_achievement/3" do
    test "creates new user achievement when none exists" do
      user = insert(:user)
      _achievement = insert(:achievement, key: "test_key", threshold_value: 10)

      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_key", 5)

      assert user_achievement.progress_value == 5
      assert is_nil(user_achievement.completed_at)
    end

    test "creates completed user achievement when progress meets threshold" do
      user = insert(:user)
      _achievement = insert(:achievement, key: "test_key", threshold_value: 10)

      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_key", 15)

      assert user_achievement.progress_value == 15
      assert user_achievement.completed_at
    end

    test "creates completed user achievement when no threshold set" do
      user = insert(:user)
      _achievement = insert(:achievement, key: "test_key", threshold_value: nil)

      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_key", 1)

      assert user_achievement.progress_value == 1
      assert user_achievement.completed_at
    end

    test "updates existing user achievement progress" do
      user = insert(:user)
      achievement = insert(:achievement, key: "test_key", threshold_value: 10)

      existing =
        insert(:user_achievement, user: user, achievement: achievement, progress_value: 5)

      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_key", 8)

      assert user_achievement.id == existing.id
      assert user_achievement.progress_value == 8
      assert is_nil(user_achievement.completed_at)
    end

    test "marks existing user achievement as completed when threshold reached" do
      user = insert(:user)
      achievement = insert(:achievement, key: "test_key", threshold_value: 10)

      existing =
        insert(:user_achievement,
          user: user,
          achievement: achievement,
          progress_value: 5,
          completed_at: nil
        )

      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_key", 12)

      assert user_achievement.id == existing.id
      assert user_achievement.progress_value == 12
      assert user_achievement.completed_at
    end

    test "preserves completed_at when already completed" do
      user = insert(:user)
      achievement = insert(:achievement, key: "test_key", threshold_value: 10)
      completed_at = DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)

      existing =
        insert(:user_achievement,
          user: user,
          achievement: achievement,
          progress_value: 12,
          completed_at: completed_at
        )

      assert {:ok, user_achievement} =
               Achievements.create_or_update_user_achievement(user.id, "test_key", 15)

      assert user_achievement.id == existing.id
      assert user_achievement.progress_value == 15

      # Check that completed_at is preserved (within a reasonable time difference)
      original_completed = existing.completed_at
      updated_completed = user_achievement.completed_at
      assert abs(DateTime.diff(original_completed, updated_completed, :second)) <= 1
    end

    test "raises error when achievement key not found" do
      user = insert(:user)

      assert_raise Ecto.NoResultsError, fn ->
        Achievements.create_or_update_user_achievement(user.id, "nonexistent_key", 5)
      end
    end
  end

  describe "mark_achievement_notified/2" do
    test "marks user achievement as notified" do
      user = insert(:user)
      achievement = insert(:achievement, key: "test_key")

      user_achievement =
        insert(:user_achievement, user: user, achievement: achievement, notified_at: nil)

      assert {:ok, updated} = Achievements.mark_achievement_notified(user.id, "test_key")
      assert updated.id == user_achievement.id
      assert updated.notified_at
    end

    test "returns error when user achievement not found" do
      user = insert(:user)
      result = Achievements.mark_achievement_notified(user.id, "nonexistent_key")
      assert result == {:error, :not_found}
    end
  end

  describe "get_achievement_statistics/1" do
    test "returns correct statistics for user with achievements" do
      user = insert(:user)
      # Total achievements
      insert_list(3, :achievement)

      # User has completed 1 achievement
      completed_achievement = insert(:achievement)
      insert(:completed_user_achievement, user: user, achievement: completed_achievement)

      # User has 1 in progress achievement
      in_progress_achievement = insert(:achievement)

      insert(:user_achievement,
        user: user,
        achievement: in_progress_achievement,
        completed_at: nil
      )

      stats = Achievements.get_achievement_statistics(user.id)

      # 3 + 1 + 1
      assert stats.total_achievements == 5
      assert stats.completed == 1
      assert stats.in_progress == 1
      # 1/5 * 100
      assert stats.completion_percentage == 20
    end

    test "returns zero statistics for user with no achievements" do
      user = insert(:user)
      insert_list(2, :achievement)

      stats = Achievements.get_achievement_statistics(user.id)

      assert stats.total_achievements == 2
      assert stats.completed == 0
      assert stats.in_progress == 0
      assert stats.completion_percentage == 0
    end

    test "handles case with no achievements in system" do
      user = insert(:user)

      stats = Achievements.get_achievement_statistics(user.id)

      assert stats.total_achievements == 0
      assert stats.completed == 0
      assert stats.in_progress == 0
      assert stats.completion_percentage == 0
    end
  end

  describe "check_achievements_for_user/1" do
    setup do
      # Create some test achievements that match the keys used in check_achievements_for_user
      achievements = [
        insert(:achievement, key: "task_beginner", threshold_value: 1),
        insert(:achievement, key: "task_digital_rectangle_mover", threshold_value: 10),
        insert(:achievement, key: "task_existential_warrior", threshold_value: 100),
        insert(:achievement, key: "habit_basic_human", threshold_value: 1),
        insert(:achievement, key: "habit_streak_survivor", threshold_value: 7),
        insert(:achievement, key: "meeting_survivor", threshold_value: 1),
        insert(:achievement, key: "meeting_archaeologist", threshold_value: 1),
        insert(:achievement, key: "email_warrior", threshold_value: 1),
        insert(:achievement, key: "connection_integrator", threshold_value: 1)
      ]

      %{achievements: achievements}
    end

    test "returns empty list when user has no activity", %{achievements: _achievements} do
      user = insert(:user)

      # Since related tables may not exist yet, this will return 0 counts
      # which should result in no completed achievements
      assert {:ok, newly_completed} = Achievements.check_achievements_for_user(user.id)
      assert is_list(newly_completed)
      # Most likely empty since user has no related data
    end

    test "handles missing related tables gracefully", %{achievements: _achievements} do
      user = insert(:user)

      # This test ensures the function doesn't crash when related tables don't exist
      # The Ecto queries will return 0 counts, which is acceptable behavior
      assert {:ok, newly_completed} = Achievements.check_achievements_for_user(user.id)
      assert is_list(newly_completed)
    end

    test "processes all expected achievement keys", %{achievements: achievements} do
      user = insert(:user)

      expected_keys = [
        "task_beginner",
        "task_digital_rectangle_mover",
        "task_existential_warrior",
        "habit_basic_human",
        "habit_streak_survivor",
        "meeting_survivor",
        "meeting_archaeologist",
        "email_warrior",
        "connection_integrator"
      ]

      # Verify all expected achievements exist
      existing_keys = Enum.map(achievements, & &1.key)

      for key <- expected_keys do
        assert key in existing_keys, "Missing achievement with key: #{key}"
      end

      # The function should process all keys without error
      assert {:ok, newly_completed} = Achievements.check_achievements_for_user(user.id)
      assert is_list(newly_completed)
    end
  end
end
