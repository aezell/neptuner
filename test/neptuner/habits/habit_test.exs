defmodule Neptuner.Habits.HabitTest do
  use Neptuner.DataCase, async: true

  alias Neptuner.Habits.Habit
  import Neptuner.Factory

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        name: "Morning Exercise"
      }

      changeset = Habit.changeset(%Habit{}, attrs)

      assert changeset.valid?
      assert changeset.changes.name == "Morning Exercise"
    end

    test "valid changeset with all fields" do
      attrs = %{
        name: "Daily Meditation",
        description: "10 minutes of mindfulness practice every morning",
        habit_type: :actually_useful,
        frequency: :weekly,
        current_streak: 15,
        longest_streak: 30
      }

      changeset = Habit.changeset(%Habit{}, attrs)

      assert changeset.valid?
      assert changeset.changes.name == "Daily Meditation"
      assert changeset.changes.description == "10 minutes of mindfulness practice every morning"
      assert changeset.changes.habit_type == :actually_useful
      assert changeset.changes.frequency == :weekly
      assert changeset.changes.current_streak == 15
      assert changeset.changes.longest_streak == 30
    end

    test "requires name" do
      changeset = Habit.changeset(%Habit{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "validates name length" do
      # Test minimum length (empty string fails required validation)
      changeset = Habit.changeset(%Habit{}, %{name: ""})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name

      # Test maximum length
      long_name = String.duplicate("a", 256)
      changeset = Habit.changeset(%Habit{}, %{name: long_name})

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).name

      # Test valid length
      changeset = Habit.changeset(%Habit{}, %{name: "Valid Name"})
      assert changeset.valid?
    end

    test "validates description length" do
      long_description = String.duplicate("a", 1001)

      changeset =
        Habit.changeset(%Habit{}, %{
          name: "Test Habit",
          description: long_description
        })

      refute changeset.valid?
      assert "should be at most 1000 character(s)" in errors_on(changeset).description
    end

    test "validates current_streak is non-negative" do
      changeset =
        Habit.changeset(%Habit{}, %{
          name: "Test Habit",
          current_streak: -1
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).current_streak
    end

    test "validates longest_streak is non-negative" do
      changeset =
        Habit.changeset(%Habit{}, %{
          name: "Test Habit",
          longest_streak: -5
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).longest_streak
    end

    test "validates habit_type enum values" do
      valid_types = [:basic_human_function, :self_improvement_theater, :actually_useful]

      for habit_type <- valid_types do
        changeset =
          Habit.changeset(%Habit{}, %{
            name: "Test Habit",
            habit_type: habit_type
          })

        assert changeset.valid?
      end
    end

    test "validates frequency enum values" do
      valid_frequencies = [:daily, :weekly, :monthly]

      for frequency <- valid_frequencies do
        changeset =
          Habit.changeset(%Habit{}, %{
            name: "Test Habit",
            frequency: frequency
          })

        assert changeset.valid?
      end
    end

    test "sets default values correctly" do
      changeset = Habit.changeset(%Habit{}, %{name: "Test Habit"})

      habit = apply_changes(changeset)

      assert habit.current_streak == 0
      assert habit.longest_streak == 0
      assert habit.habit_type == :self_improvement_theater
      assert habit.frequency == :daily
    end

    test "ensures longest_streak consistency when current_streak is higher" do
      changeset =
        Habit.changeset(%Habit{}, %{
          name: "Test Habit",
          current_streak: 25,
          longest_streak: 10
        })

      assert changeset.valid?
      assert changeset.changes.longest_streak == 25
    end

    test "maintains longest_streak when current_streak is lower" do
      changeset =
        Habit.changeset(%Habit{}, %{
          name: "Test Habit",
          current_streak: 5,
          longest_streak: 15
        })

      assert changeset.valid?
      assert changeset.changes.longest_streak == 15
    end

    test "handles existing habit with streak updates" do
      existing_habit = %Habit{
        name: "Existing Habit",
        current_streak: 10,
        longest_streak: 20
      }

      # Update with higher current streak
      changeset = Habit.changeset(existing_habit, %{current_streak: 25})

      assert changeset.valid?
      assert changeset.changes.longest_streak == 25

      # Update with lower current streak
      changeset = Habit.changeset(existing_habit, %{current_streak: 5})

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :longest_streak)
    end
  end

  describe "habit_type_description/1" do
    test "returns correct descriptions for all habit types" do
      assert Habit.habit_type_description(:basic_human_function) ==
               "Essential activities that keep you alive and functional"

      assert Habit.habit_type_description(:self_improvement_theater) ==
               "Activities that feel productive but mostly exist to make you feel better about yourself"

      assert Habit.habit_type_description(:actually_useful) ==
               "Genuinely beneficial practices with measurable positive impact"
    end
  end

  describe "database integration" do
    test "can insert and retrieve habit with all fields" do
      user = insert(:user)

      habit =
        insert(:habit,
          user: user,
          name: "Database Test Habit",
          description: "Testing database operations",
          habit_type: :actually_useful,
          frequency: :weekly,
          current_streak: 5,
          longest_streak: 10
        )

      retrieved = Repo.get!(Habit, habit.id) |> Repo.preload(:user)

      assert retrieved.name == "Database Test Habit"
      assert retrieved.description == "Testing database operations"
      assert retrieved.habit_type == :actually_useful
      assert retrieved.frequency == :weekly
      assert retrieved.current_streak == 5
      assert retrieved.longest_streak == 10
      assert retrieved.user.id == user.id
    end

    test "belongs_to user association works correctly" do
      user = insert(:user)
      habit = insert(:habit, user: user)

      retrieved = Repo.get!(Habit, habit.id) |> Repo.preload(:user)

      assert retrieved.user.id == user.id
      assert retrieved.user.email == user.email
    end

    test "deleting user cascades to habits" do
      user = insert(:user)
      habit = insert(:habit, user: user)

      assert Repo.get(Habit, habit.id)

      Repo.delete!(user)

      refute Repo.get(Habit, habit.id)
    end

    test "has_many relationship with habit_entries" do
      habit = insert(:habit)
      entry1 = insert(:habit_entry, habit: habit)
      entry2 = insert(:habit_entry, habit: habit)

      retrieved = Repo.get!(Habit, habit.id) |> Repo.preload(:habit_entries)

      assert length(retrieved.habit_entries) == 2
      entry_ids = Enum.map(retrieved.habit_entries, & &1.id)
      assert entry1.id in entry_ids
      assert entry2.id in entry_ids
    end

    test "deleting habit cascades to habit_entries" do
      habit = insert(:habit)
      entry = insert(:habit_entry, habit: habit)

      assert Repo.get(Neptuner.Habits.HabitEntry, entry.id)

      Repo.delete!(habit)

      refute Repo.get(Neptuner.Habits.HabitEntry, entry.id)
    end
  end

  describe "factory variants" do
    test "basic_human_function_habit factory creates correct type" do
      habit = build(:basic_human_function_habit)

      assert habit.habit_type == :basic_human_function
      assert habit.name in ["Brush teeth", "Eat food", "Sleep", "Breathe consciously"]
    end

    test "self_improvement_theater_habit factory creates correct type" do
      habit = build(:self_improvement_theater_habit)

      assert habit.habit_type == :self_improvement_theater
      assert habit.name in ["Meditate", "Journal", "Read self-help", "Wake up at 5 AM"]
    end

    test "actually_useful_habit factory creates correct type" do
      habit = build(:actually_useful_habit)

      assert habit.habit_type == :actually_useful
      assert habit.name in ["Exercise regularly", "Learn a skill", "Save money", "Call family"]
    end

    test "daily_habit factory creates daily frequency" do
      habit = build(:daily_habit)

      assert habit.frequency == :daily
      assert habit.name == "Daily practice"
    end

    test "weekly_habit factory creates weekly frequency" do
      habit = build(:weekly_habit)

      assert habit.frequency == :weekly
      assert habit.name == "Weekly goal"
    end

    test "monthly_habit factory creates monthly frequency" do
      habit = build(:monthly_habit)

      assert habit.frequency == :monthly
      assert habit.name == "Monthly objective"
    end

    test "active_streak_habit factory creates habit with current streak" do
      habit = build(:active_streak_habit)

      assert habit.current_streak >= 5
      assert habit.current_streak <= 20
      assert habit.longest_streak >= habit.current_streak
    end

    test "broken_streak_habit factory creates habit with no current streak" do
      habit = build(:broken_streak_habit)

      assert habit.current_streak == 0
      assert habit.longest_streak >= 10
    end

    test "perfect_habit factory creates habit with equal streaks" do
      habit = build(:perfect_habit)

      assert habit.current_streak == habit.longest_streak
      assert habit.current_streak >= 50
    end
  end
end
