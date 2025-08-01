defmodule Neptuner.HabitsTest do
  use Neptuner.DataCase, async: true

  alias Neptuner.Habits
  alias Neptuner.Habits.{Habit, HabitEntry}
  import Neptuner.Factory

  describe "habits" do
    test "list_habits/1 returns all habits for user" do
      user1 = insert(:user)
      user2 = insert(:user)

      habit1 = insert(:habit, user: user1, name: "User 1 Habit")
      habit2 = insert(:habit, user: user1, name: "Another User 1 Habit")
      _habit3 = insert(:habit, user: user2, name: "User 2 Habit")

      user1_habits = Habits.list_habits(user1.id)
      user2_habits = Habits.list_habits(user2.id)

      assert length(user1_habits) == 2
      assert length(user2_habits) == 1

      habit_names = Enum.map(user1_habits, & &1.name)
      assert "User 1 Habit" in habit_names
      assert "Another User 1 Habit" in habit_names
    end

    test "list_habits/1 orders by insertion date descending" do
      user = insert(:user)

      # Insert habits with specific timestamps
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      habit1 =
        insert(:habit,
          user: user,
          name: "First Habit",
          inserted_at: DateTime.add(now, -60, :second)
        )

      habit2 =
        insert(:habit,
          user: user,
          name: "Second Habit",
          inserted_at: DateTime.add(now, -30, :second)
        )

      habit3 = insert(:habit, user: user, name: "Third Habit", inserted_at: now)

      habits = Habits.list_habits(user.id)

      # Should be ordered by most recent first
      habit_names = Enum.map(habits, & &1.name)
      assert habit_names == ["Third Habit", "Second Habit", "First Habit"]
    end

    test "get_habit!/1 returns the habit with given id" do
      habit = insert(:habit, name: "Test Habit")

      retrieved = Habits.get_habit!(habit.id)

      assert retrieved.id == habit.id
      assert retrieved.name == "Test Habit"
    end

    test "get_habit!/1 raises Ecto.NoResultsError when habit not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Habits.get_habit!(Ecto.UUID.generate())
      end
    end

    test "get_user_habit!/2 returns habit for specific user" do
      user = insert(:user)
      habit = insert(:habit, user: user, name: "User Habit")

      retrieved = Habits.get_user_habit!(user.id, habit.id)

      assert retrieved.id == habit.id
      assert retrieved.name == "User Habit"
    end

    test "get_user_habit!/2 raises when habit belongs to different user" do
      user1 = insert(:user)
      user2 = insert(:user)
      habit = insert(:habit, user: user1)

      assert_raise Ecto.NoResultsError, fn ->
        Habits.get_user_habit!(user2.id, habit.id)
      end
    end

    test "create_habit/2 with valid data creates a habit" do
      user = insert(:user)

      attrs = %{
        name: "New Habit",
        description: "A brand new habit",
        habit_type: :actually_useful,
        frequency: :weekly
      }

      assert {:ok, %Habit{} = habit} = Habits.create_habit(user.id, attrs)
      assert habit.name == "New Habit"
      assert habit.description == "A brand new habit"
      assert habit.habit_type == :actually_useful
      assert habit.frequency == :weekly
      assert habit.user_id == user.id
    end

    test "create_habit/2 with invalid data returns error changeset" do
      user = insert(:user)
      attrs = %{name: ""}

      assert {:error, %Ecto.Changeset{}} = Habits.create_habit(user.id, attrs)
    end

    test "create_user_habit/2 is alias for create_habit/2" do
      user = insert(:user)
      attrs = %{name: "Alias Test Habit"}

      assert {:ok, %Habit{} = habit} = Habits.create_user_habit(user.id, attrs)
      assert habit.name == "Alias Test Habit"
    end

    test "update_habit/2 with valid data updates the habit" do
      habit = insert(:habit, name: "Original Name")

      update_attrs = %{
        name: "Updated Name",
        description: "Updated description",
        habit_type: :basic_human_function
      }

      assert {:ok, %Habit{} = updated_habit} = Habits.update_habit(habit, update_attrs)
      assert updated_habit.name == "Updated Name"
      assert updated_habit.description == "Updated description"
      assert updated_habit.habit_type == :basic_human_function
    end

    test "update_habit/2 with invalid data returns error changeset" do
      habit = insert(:habit)
      update_attrs = %{name: ""}

      assert {:error, %Ecto.Changeset{}} = Habits.update_habit(habit, update_attrs)

      # Ensure original data is unchanged
      unchanged = Habits.get_habit!(habit.id)
      assert unchanged.name == habit.name
    end

    test "delete_habit/1 deletes the habit" do
      habit = insert(:habit)

      assert {:ok, %Habit{}} = Habits.delete_habit(habit)
      assert_raise Ecto.NoResultsError, fn -> Habits.get_habit!(habit.id) end
    end

    test "change_habit/1 returns a habit changeset" do
      habit = insert(:habit)

      assert %Ecto.Changeset{} = Habits.change_habit(habit)
    end

    test "change_habit/2 returns a habit changeset with changes" do
      habit = insert(:habit)
      attrs = %{name: "Changed Name"}

      changeset = Habits.change_habit(habit, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.name == "Changed Name"
    end
  end

  describe "habit_entries" do
    test "list_habit_entries/1 returns all entries for habit" do
      habit = insert(:habit)
      entry1 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today())
      entry2 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-1))

      # Entry for different habit should not be included
      other_habit = insert(:habit)
      _entry3 = insert(:habit_entry, habit: other_habit)

      entries = Habits.list_habit_entries(habit.id)

      assert length(entries) == 2
      entry_ids = Enum.map(entries, & &1.id)
      assert entry1.id in entry_ids
      assert entry2.id in entry_ids
    end

    test "list_habit_entries/1 orders by completion date descending" do
      habit = insert(:habit)

      entry1 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-2))
      entry2 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today())
      entry3 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-1))

      entries = Habits.list_habit_entries(habit.id)

      # Should be ordered by most recent first
      entry_ids = Enum.map(entries, & &1.id)
      assert entry_ids == [entry2.id, entry3.id, entry1.id]
    end

    test "get_habit_entry!/1 returns the habit entry with given id" do
      entry = insert(:habit_entry)

      retrieved = Habits.get_habit_entry!(entry.id)

      assert retrieved.id == entry.id
      assert retrieved.completed_on == entry.completed_on
    end

    test "create_habit_entry/2 with valid data creates a habit entry" do
      habit = insert(:habit)
      completion_date = Date.utc_today() |> Date.add(-1)

      attrs = %{
        completed_on: completion_date,
        existential_commentary: "Custom commentary"
      }

      assert {:ok, %HabitEntry{} = entry} = Habits.create_habit_entry(habit.id, attrs)
      assert entry.completed_on == completion_date
      assert entry.existential_commentary == "Custom commentary"
      assert entry.habit_id == habit.id
    end

    test "create_habit_entry/2 updates habit streaks" do
      habit = insert(:habit, current_streak: 0, longest_streak: 5)

      # Create entry for today (should start a new streak)
      assert {:ok, _entry} =
               Habits.create_habit_entry(habit.id, %{completed_on: Date.utc_today()})

      # Habit should be updated with new streak
      updated_habit = Habits.get_habit!(habit.id)
      assert updated_habit.current_streak == 1
      # Should remain the same since 1 < 5
      assert updated_habit.longest_streak == 5
    end

    test "create_habit_entry/2 with invalid data returns error changeset" do
      habit = insert(:habit)
      attrs = %{completed_on: nil}

      assert {:error, %Ecto.Changeset{}} = Habits.create_habit_entry(habit.id, attrs)
    end

    test "update_habit_entry/2 with valid data updates the habit entry" do
      entry = insert(:habit_entry, existential_commentary: "Original commentary")

      update_attrs = %{existential_commentary: "Updated commentary"}

      assert {:ok, %HabitEntry{} = updated_entry} = Habits.update_habit_entry(entry, update_attrs)
      assert updated_entry.existential_commentary == "Updated commentary"
    end

    test "delete_habit_entry/1 deletes the habit entry and updates streaks" do
      habit = insert(:habit, current_streak: 5, longest_streak: 10)
      entry = insert(:habit_entry, habit: habit)

      assert {:ok, %HabitEntry{}} = Habits.delete_habit_entry(entry)
      assert_raise Ecto.NoResultsError, fn -> Habits.get_habit_entry!(entry.id) end

      # Streaks should be recalculated
      updated_habit = Habits.get_habit!(habit.id)
      # Since we only had one entry and deleted it, streaks should be reset
      assert updated_habit.current_streak == 0
    end

    test "change_habit_entry/1 returns a habit entry changeset" do
      entry = insert(:habit_entry)

      assert %Ecto.Changeset{} = Habits.change_habit_entry(entry)
    end

    test "check_in_habit/1 creates entry for today" do
      habit = insert(:habit)

      assert {:ok, %HabitEntry{} = entry} = Habits.check_in_habit(habit.id)
      assert entry.completed_on == Date.utc_today()
      assert entry.habit_id == habit.id
    end

    test "check_in_habit/2 creates entry for specified date" do
      habit = insert(:habit)
      target_date = Date.utc_today() |> Date.add(-3)

      assert {:ok, %HabitEntry{} = entry} = Habits.check_in_habit(habit.id, target_date)
      assert entry.completed_on == target_date
    end
  end

  describe "streak calculations" do
    test "calculate_current_streak with consecutive days from today" do
      habit = insert(:habit)

      # Create entries for today and previous 4 days (5-day streak)
      for i <- 0..4 do
        insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-i))
      end

      # Create an entry manually to trigger streak calculation
      {:ok, _} =
        Habits.create_habit_entry(habit.id, %{
          completed_on: Date.utc_today() |> Date.add(-5)
        })

      updated_habit = Habits.get_habit!(habit.id)
      # Original 5 + new entry
      assert updated_habit.current_streak == 6
    end

    test "calculate_current_streak with broken streak" do
      habit = insert(:habit)

      # Create entries with a gap (today and yesterday, but not day before)
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today())
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-1))
      # Gap on day -2
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-3))

      # Trigger streak calculation
      {:ok, _} =
        Habits.create_habit_entry(habit.id, %{
          completed_on: Date.utc_today() |> Date.add(-10)
        })

      updated_habit = Habits.get_habit!(habit.id)
      # Only today and yesterday count
      assert updated_habit.current_streak == 2
    end

    test "calculate_current_streak with no recent entries" do
      habit = insert(:habit)

      # Create old entries (not recent)
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-10))
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-15))

      # Trigger streak calculation
      {:ok, _} =
        Habits.create_habit_entry(habit.id, %{
          completed_on: Date.utc_today() |> Date.add(-20)
        })

      updated_habit = Habits.get_habit!(habit.id)
      assert updated_habit.current_streak == 0
    end

    test "calculate_longest_streak finds maximum consecutive days" do
      habit = insert(:habit, longest_streak: 0)

      # Create multiple streaks with gaps
      # Streak 1: 3 consecutive days
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-01])
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-02])
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-03])

      # Gap

      # Streak 2: 5 consecutive days (longest)
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-10])
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-11])
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-12])
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-13])
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-14])

      # Gap

      # Streak 3: 2 consecutive days
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-20])
      insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-21])

      # Trigger streak calculation
      {:ok, _} = Habits.create_habit_entry(habit.id, %{completed_on: ~D[2024-01-25]})

      updated_habit = Habits.get_habit!(habit.id)
      assert updated_habit.longest_streak == 5
    end

    test "longest_streak preserves existing maximum" do
      # Existing high score
      habit = insert(:habit, longest_streak: 20)

      # Create a shorter streak
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today())
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-1))
      insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-2))

      {:ok, _} =
        Habits.create_habit_entry(habit.id, %{completed_on: Date.utc_today() |> Date.add(-3)})

      updated_habit = Habits.get_habit!(habit.id)
      # Should preserve existing maximum
      assert updated_habit.longest_streak == 20
    end

    test "streak calculation handles single entry" do
      habit = insert(:habit, current_streak: 0, longest_streak: 0)

      {:ok, _} = Habits.create_habit_entry(habit.id, %{completed_on: Date.utc_today()})

      updated_habit = Habits.get_habit!(habit.id)
      assert updated_habit.current_streak == 1
      assert updated_habit.longest_streak == 1
    end

    test "streak calculation handles empty entries" do
      habit = insert(:habit, current_streak: 0, longest_streak: 10)

      # Create some entries first
      {:ok, entry1} = Habits.create_habit_entry(habit.id, %{completed_on: Date.utc_today()})

      {:ok, entry2} =
        Habits.create_habit_entry(habit.id, %{completed_on: Date.utc_today() |> Date.add(-1)})

      # Verify habit has some streaks
      habit_with_entries = Habits.get_habit!(habit.id)
      assert habit_with_entries.current_streak > 0

      # Delete all entries
      {:ok, _} = Habits.delete_habit_entry(entry1)
      {:ok, _} = Habits.delete_habit_entry(entry2)

      # The last delete should have updated streaks to 0
      updated_habit = Habits.get_habit!(habit.id)
      assert updated_habit.current_streak == 0
      # longest_streak should preserve the highest value seen during calculation
      assert updated_habit.longest_streak >= 10
    end
  end

  describe "habit statistics" do
    test "get_habit_statistics/1 returns comprehensive stats" do
      user = insert(:user)

      # Create habits of different types and streak states with explicit values
      insert(:habit,
        user: user,
        habit_type: :basic_human_function,
        current_streak: 5,
        longest_streak: 5
      )

      insert(:habit,
        user: user,
        habit_type: :self_improvement_theater,
        current_streak: 0,
        longest_streak: 10
      )

      insert(:habit,
        user: user,
        habit_type: :actually_useful,
        current_streak: 15,
        longest_streak: 25
      )

      insert(:habit,
        user: user,
        habit_type: :actually_useful,
        current_streak: 8,
        longest_streak: 12
      )

      insert(:habit,
        user: user,
        habit_type: :self_improvement_theater,
        current_streak: 3,
        longest_streak: 20
      )

      stats = Habits.get_habit_statistics(user.id)

      assert stats.total_habits == 5
      # 4 habits with current_streak > 0
      assert stats.active_streaks == 4
      # 5 + 0 + 15 + 8 + 3
      assert stats.total_current_streak == 31
      assert stats.longest_overall_streak == 25
      assert stats.basic_human_functions == 1
      assert stats.self_improvement_theater == 2
      assert stats.actually_useful == 2
    end

    test "get_habit_statistics/1 handles user with no habits" do
      user = insert(:user)

      stats = Habits.get_habit_statistics(user.id)

      assert stats.total_habits == 0
      assert stats.active_streaks == 0
      assert stats.total_current_streak == 0
      assert stats.longest_overall_streak == 0
      assert stats.basic_human_functions == 0
      assert stats.self_improvement_theater == 0
      assert stats.actually_useful == 0
    end

    test "get_habit_statistics/1 isolates users correctly" do
      user1 = insert(:user)
      user2 = insert(:user)

      insert_list(3, :habit, user: user1, current_streak: 5)
      insert_list(2, :habit, user: user2, current_streak: 10)

      user1_stats = Habits.get_habit_statistics(user1.id)
      user2_stats = Habits.get_habit_statistics(user2.id)

      assert user1_stats.total_habits == 3
      assert user1_stats.total_current_streak == 15

      assert user2_stats.total_habits == 2
      assert user2_stats.total_current_streak == 20
    end
  end

  describe "habit tracking and analytics" do
    test "get_habit_tracking_for_range/3 returns entries within date range" do
      habit = insert(:habit)

      start_date = ~D[2024-01-01]
      end_date = ~D[2024-01-31]

      # Entries within range
      entry1 = insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-05])
      entry2 = insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-15])
      entry3 = insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-25])

      # Entries outside range
      _old_entry = insert(:habit_entry, habit: habit, completed_on: ~D[2023-12-31])
      _future_entry = insert(:habit_entry, habit: habit, completed_on: ~D[2024-02-01])

      entries = Habits.get_habit_tracking_for_range(habit.id, start_date, end_date)

      assert length(entries) == 3
      entry_ids = Enum.map(entries, & &1.id)
      assert entry1.id in entry_ids
      assert entry2.id in entry_ids
      assert entry3.id in entry_ids
    end

    test "get_habit_tracking_for_range/3 orders by completion date ascending" do
      habit = insert(:habit)

      entry1 = insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-25])
      entry2 = insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-05])
      entry3 = insert(:habit_entry, habit: habit, completed_on: ~D[2024-01-15])

      entries = Habits.get_habit_tracking_for_range(habit.id, ~D[2024-01-01], ~D[2024-01-31])

      # Should be ordered chronologically
      entry_ids = Enum.map(entries, & &1.id)
      assert entry_ids == [entry2.id, entry3.id, entry1.id]
    end

    test "get_user_habit_stats_for_range/3 calculates completion rates for daily habits" do
      user = insert(:user)

      habit1 = insert(:daily_habit, user: user, name: "Daily Habit 1")
      habit2 = insert(:daily_habit, user: user, name: "Daily Habit 2")

      start_date = ~D[2024-01-01]
      # 10 days total
      end_date = ~D[2024-01-10]

      # Habit 1: 5 out of 10 days = 50%
      for day <- [1, 3, 5, 7, 9] do
        insert(:habit_entry, habit: habit1, completed_on: ~D[2024-01-01] |> Date.add(day - 1))
      end

      # Habit 2: 10 out of 10 days = 100%
      for day <- 1..10 do
        insert(:habit_entry, habit: habit2, completed_on: ~D[2024-01-01] |> Date.add(day - 1))
      end

      stats = Habits.get_user_habit_stats_for_range(user.id, start_date, end_date)

      assert length(stats) == 2

      habit1_stats = Enum.find(stats, &(&1.habit.id == habit1.id))
      habit2_stats = Enum.find(stats, &(&1.habit.id == habit2.id))

      assert habit1_stats.entries_count == 5
      assert habit1_stats.completion_rate == 50.0

      assert habit2_stats.entries_count == 10
      assert habit2_stats.completion_rate == 100.0
    end

    test "get_user_habit_stats_for_range/3 handles weekly and monthly habits" do
      user = insert(:user)

      weekly_habit = insert(:weekly_habit, user: user)
      monthly_habit = insert(:monthly_habit, user: user)

      # Create entries with different dates to avoid unique constraint violations
      insert(:habit_entry, habit: weekly_habit, completed_on: Date.utc_today())
      insert(:habit_entry, habit: weekly_habit, completed_on: Date.utc_today() |> Date.add(-1))
      insert(:habit_entry, habit: weekly_habit, completed_on: Date.utc_today() |> Date.add(-2))

      insert(:habit_entry, habit: monthly_habit, completed_on: Date.utc_today())
      insert(:habit_entry, habit: monthly_habit, completed_on: Date.utc_today() |> Date.add(-1))

      stats =
        Habits.get_user_habit_stats_for_range(
          user.id,
          Date.utc_today() |> Date.add(-2),
          Date.utc_today()
        )

      weekly_stats = Enum.find(stats, &(&1.habit.id == weekly_habit.id))
      monthly_stats = Enum.find(stats, &(&1.habit.id == monthly_habit.id))

      # For non-daily habits, it uses entries_count * 10 as rough score
      # 3 * 10
      assert weekly_stats.completion_rate == 30
      # 2 * 10
      assert monthly_stats.completion_rate == 20
    end

    test "get_user_habit_stats_for_range/3 includes habit and entries data" do
      user = insert(:user)
      habit = insert(:habit, user: user, name: "Test Habit")

      entry1 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today())
      entry2 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-1))

      stats =
        Habits.get_user_habit_stats_for_range(
          user.id,
          Date.utc_today() |> Date.add(-2),
          Date.utc_today()
        )

      assert length(stats) == 1
      habit_stats = List.first(stats)

      assert habit_stats.habit.id == habit.id
      assert habit_stats.habit.name == "Test Habit"
      assert habit_stats.entries_count == 2

      entry_ids = Enum.map(habit_stats.entries, & &1.id)
      assert entry1.id in entry_ids
      assert entry2.id in entry_ids
    end

    test "get_user_habit_stats_for_range/3 handles zero-day range correctly" do
      user = insert(:user)
      habit = insert(:daily_habit, user: user)

      same_date = Date.utc_today()
      insert(:habit_entry, habit: habit, completed_on: same_date)

      stats = Habits.get_user_habit_stats_for_range(user.id, same_date, same_date)

      habit_stats = List.first(stats)
      # 1 entry out of 1 day = 100%
      assert habit_stats.completion_rate == 100.0
    end
  end

  describe "integration tests" do
    test "complete habit workflow with streak tracking" do
      user = insert(:user)

      # Create a new habit
      {:ok, habit} =
        Habits.create_habit(user.id, %{
          name: "Daily Reading",
          description: "Read for 30 minutes",
          habit_type: :actually_useful,
          frequency: :daily
        })

      # Check initial state
      assert habit.current_streak == 0
      assert habit.longest_streak == 0

      # Check in for today
      {:ok, entry1} = Habits.check_in_habit(habit.id)
      updated_habit = Habits.get_habit!(habit.id)

      assert updated_habit.current_streak == 1
      assert updated_habit.longest_streak == 1

      # Check in for yesterday (building streak)
      {:ok, entry2} = Habits.check_in_habit(habit.id, Date.utc_today() |> Date.add(-1))
      updated_habit = Habits.get_habit!(habit.id)

      assert updated_habit.current_streak == 2
      assert updated_habit.longest_streak == 2

      # Verify entries exist
      entries = Habits.list_habit_entries(habit.id)
      assert length(entries) == 2

      # Delete an entry (break streak)
      {:ok, _} = Habits.delete_habit_entry(entry2)
      updated_habit = Habits.get_habit!(habit.id)

      # Only today remains
      assert updated_habit.current_streak == 1
      # Historical maximum preserved
      assert updated_habit.longest_streak == 2

      # Get statistics
      stats = Habits.get_habit_statistics(user.id)
      assert stats.total_habits == 1
      assert stats.active_streaks == 1
      assert stats.actually_useful == 1
    end

    test "multiple users with overlapping habit data remain isolated" do
      user1 = insert(:user)
      user2 = insert(:user)

      # Both users create similar habits
      {:ok, habit1} = Habits.create_habit(user1.id, %{name: "Exercise"})
      {:ok, habit2} = Habits.create_habit(user2.id, %{name: "Exercise"})

      # Both check in today
      {:ok, _} = Habits.check_in_habit(habit1.id)
      {:ok, _} = Habits.check_in_habit(habit2.id)

      # User 1 builds a longer streak
      for i <- 1..5 do
        {:ok, _} = Habits.check_in_habit(habit1.id, Date.utc_today() |> Date.add(-i))
      end

      # Verify isolation
      user1_habits = Habits.list_habits(user1.id)
      user2_habits = Habits.list_habits(user2.id)

      assert length(user1_habits) == 1
      assert length(user2_habits) == 1

      user1_habit = List.first(user1_habits)
      user2_habit = List.first(user2_habits)

      assert user1_habit.current_streak == 6
      assert user2_habit.current_streak == 1

      # Statistics should be isolated
      user1_stats = Habits.get_habit_statistics(user1.id)
      user2_stats = Habits.get_habit_statistics(user2.id)

      assert user1_stats.total_current_streak == 6
      assert user2_stats.total_current_streak == 1
    end
  end
end
