defmodule Neptuner.Habits.HabitEntryTest do
  use Neptuner.DataCase, async: true

  alias Neptuner.Habits.HabitEntry
  import Neptuner.Factory

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        completed_on: Date.utc_today()
      }

      changeset = HabitEntry.changeset(%HabitEntry{}, attrs)

      assert changeset.valid?
      assert changeset.changes.completed_on == Date.utc_today()
      # Commentary should be auto-generated
      assert changeset.changes.existential_commentary != nil
      assert is_binary(changeset.changes.existential_commentary)
    end

    test "valid changeset with all fields" do
      custom_commentary = "Today I transcended the mundane through disciplined action"

      attrs = %{
        completed_on: Date.utc_today() |> Date.add(-1),
        existential_commentary: custom_commentary
      }

      changeset = HabitEntry.changeset(%HabitEntry{}, attrs)

      assert changeset.valid?
      assert changeset.changes.completed_on == Date.utc_today() |> Date.add(-1)
      assert changeset.changes.existential_commentary == custom_commentary
    end

    test "requires completed_on" do
      changeset = HabitEntry.changeset(%HabitEntry{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).completed_on
    end

    test "auto-generates existential_commentary when not provided" do
      changeset =
        HabitEntry.changeset(%HabitEntry{}, %{
          completed_on: Date.utc_today()
        })

      assert changeset.valid?
      commentary = changeset.changes.existential_commentary
      assert commentary != nil
      assert is_binary(commentary)
      assert String.length(commentary) > 0
    end

    test "preserves custom existential_commentary when provided" do
      custom_commentary = "My own profound observation about this habit completion"

      changeset =
        HabitEntry.changeset(%HabitEntry{}, %{
          completed_on: Date.utc_today(),
          existential_commentary: custom_commentary
        })

      assert changeset.valid?
      assert changeset.changes.existential_commentary == custom_commentary
    end

    test "generates random commentary from predefined list" do
      expected_commentaries = [
        "Another day of convincing yourself this routine matters in the grand scheme of things.",
        "The algorithm of self-improvement continues its relentless execution.",
        "Today's episode of 'Humans Performing Optimality Theater' is now complete.",
        "Successfully maintained the illusion of progress through repetitive behavior.",
        "The habit has been acknowledged by the universe, which remains indifferent.",
        "Another data point in the infinite spreadsheet of personal optimization.",
        "The machine of habit completion churns on, indifferent to cosmic significance.",
        "Today's ritual of self-imposed discipline has been ceremonially observed.",
        "The daily demonstration that free will and determination can coexist with absurdity.",
        "Another brick in the endless wall of 'becoming the person you want to be.'"
      ]

      # Generate multiple changesets to test randomness
      commentaries =
        for _ <- 1..20 do
          changeset = HabitEntry.changeset(%HabitEntry{}, %{completed_on: Date.utc_today()})
          changeset.changes.existential_commentary
        end

      # All generated commentaries should be from our expected list
      assert Enum.all?(commentaries, &(&1 in expected_commentaries))

      # Should have some variety (not all the same)
      unique_commentaries = Enum.uniq(commentaries)
      assert length(unique_commentaries) > 1
    end

    test "unique constraint on habit_id and completed_on combination is defined" do
      # This will be tested at the database level, but we can verify the constraint is present
      changeset =
        HabitEntry.changeset(%HabitEntry{}, %{
          completed_on: Date.utc_today()
        })

      assert changeset.valid?

      # Check that the unique constraint is present (structure may vary)
      constraint_names = Enum.map(changeset.constraints, & &1.constraint)
      assert "habit_entries_habit_id_completed_on_index" in constraint_names
    end
  end

  describe "database integration" do
    test "can insert and retrieve habit entry with all fields" do
      habit = insert(:habit)
      completion_date = Date.utc_today() |> Date.add(-5)
      custom_commentary = "Philosophical musings about habit completion"

      habit_entry =
        insert(:habit_entry,
          habit: habit,
          completed_on: completion_date,
          existential_commentary: custom_commentary
        )

      retrieved = Repo.get!(HabitEntry, habit_entry.id) |> Repo.preload(:habit)

      assert retrieved.completed_on == completion_date
      assert retrieved.existential_commentary == custom_commentary
      assert retrieved.habit.id == habit.id
    end

    test "belongs_to habit association works correctly" do
      habit = insert(:habit)
      habit_entry = insert(:habit_entry, habit: habit)

      retrieved = Repo.get!(HabitEntry, habit_entry.id) |> Repo.preload(:habit)

      assert retrieved.habit.id == habit.id
      assert retrieved.habit.name == habit.name
    end

    test "deleting habit cascades to habit entries" do
      habit = insert(:habit)
      habit_entry = insert(:habit_entry, habit: habit)

      assert Repo.get(HabitEntry, habit_entry.id)

      Repo.delete!(habit)

      refute Repo.get(HabitEntry, habit_entry.id)
    end

    test "enforces unique constraint on habit_id and completed_on" do
      habit = insert(:habit)
      completion_date = Date.utc_today()

      # First entry should work
      insert(:habit_entry, habit: habit, completed_on: completion_date)

      # Second entry with same habit and date should fail
      assert_raise Ecto.ConstraintError, fn ->
        insert(:habit_entry, habit: habit, completed_on: completion_date)
      end
    end

    test "allows same completion date for different habits" do
      habit1 = insert(:habit)
      habit2 = insert(:habit)
      completion_date = Date.utc_today()

      # Both entries should work fine
      entry1 = insert(:habit_entry, habit: habit1, completed_on: completion_date)
      entry2 = insert(:habit_entry, habit: habit2, completed_on: completion_date)

      assert entry1.completed_on == completion_date
      assert entry2.completed_on == completion_date
      assert entry1.habit_id != entry2.habit_id
    end

    test "allows different completion dates for same habit" do
      habit = insert(:habit)

      entry1 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today())
      entry2 = insert(:habit_entry, habit: habit, completed_on: Date.utc_today() |> Date.add(-1))

      assert entry1.habit_id == entry2.habit_id
      assert entry1.completed_on != entry2.completed_on
    end

    test "auto-generates commentary when not provided" do
      habit = insert(:habit)

      # Use the context function to create the entry (which uses the changeset)
      {:ok, habit_entry} =
        Neptuner.Habits.create_habit_entry(habit.id, %{
          completed_on: Date.utc_today()
        })

      assert habit_entry.existential_commentary != nil
      assert is_binary(habit_entry.existential_commentary)
      assert String.length(habit_entry.existential_commentary) > 0
    end
  end

  describe "factory variants" do
    test "recent_habit_entry factory creates entry within last few days" do
      entry = build(:recent_habit_entry)

      days_diff = Date.diff(Date.utc_today(), entry.completed_on)
      assert days_diff >= 0
      assert days_diff <= 3
    end

    test "old_habit_entry factory creates entry from distant past" do
      entry = build(:old_habit_entry)

      days_diff = Date.diff(Date.utc_today(), entry.completed_on)
      assert days_diff >= 30
      assert days_diff <= 365
    end

    test "today_habit_entry factory creates entry for today" do
      entry = build(:today_habit_entry)

      assert entry.completed_on == Date.utc_today()
    end

    test "yesterday_habit_entry factory creates entry for yesterday" do
      entry = build(:yesterday_habit_entry)

      assert entry.completed_on == Date.utc_today() |> Date.add(-1)
    end

    test "custom_commentary_habit_entry factory has custom commentary" do
      entry = build(:custom_commentary_habit_entry)

      assert entry.existential_commentary ==
               "Today I conquered the void of meaninglessness through routine"
    end

    test "default habit_entry factory generates random completion date" do
      # Generate multiple entries to test randomness
      entries = for _ <- 1..10, do: build(:habit_entry)
      completion_dates = Enum.map(entries, & &1.completed_on)

      # All dates should be in the past (within 30 days)
      assert Enum.all?(completion_dates, fn date ->
               days_diff = Date.diff(Date.utc_today(), date)
               days_diff >= 0 and days_diff <= 30
             end)

      # Should have some variety in dates
      unique_dates = Enum.uniq(completion_dates)
      assert length(unique_dates) > 1
    end
  end

  describe "existential commentary generation" do
    test "commentary has appropriate philosophical tone" do
      changeset = HabitEntry.changeset(%HabitEntry{}, %{completed_on: Date.utc_today()})
      commentary = changeset.changes.existential_commentary

      # Commentary should contain existential or philosophical themes
      existential_keywords = [
        "routine",
        "algorithm",
        "theater",
        "illusion",
        "universe",
        "cosmic",
        "spreadsheet",
        "optimization",
        "machine",
        "ritual",
        "discipline",
        "absurdity",
        "existence",
        "grand scheme",
        "indifferent"
      ]

      has_existential_theme =
        Enum.any?(existential_keywords, fn keyword ->
          String.contains?(String.downcase(commentary), keyword)
        end)

      assert has_existential_theme, "Commentary should contain existential themes: #{commentary}"
    end

    test "commentary is appropriately cynical but not offensive" do
      changeset = HabitEntry.changeset(%HabitEntry{}, %{completed_on: Date.utc_today()})
      commentary = changeset.changes.existential_commentary

      # Should be cynical/philosophical but not contain offensive language
      offensive_words = ["hate", "stupid", "idiot", "damn", "hell"]

      contains_offensive =
        Enum.any?(offensive_words, fn word ->
          String.contains?(String.downcase(commentary), word)
        end)

      refute contains_offensive, "Commentary should not contain offensive language: #{commentary}"
    end

    test "all predefined commentaries are reasonable length" do
      # Test multiple generations to hit different commentaries
      commentaries =
        for _ <- 1..50 do
          changeset = HabitEntry.changeset(%HabitEntry{}, %{completed_on: Date.utc_today()})
          changeset.changes.existential_commentary
        end

      unique_commentaries = Enum.uniq(commentaries)

      # All commentaries should be reasonable length (not too short or too long)
      assert Enum.all?(unique_commentaries, fn commentary ->
               length = String.length(commentary)
               length >= 20 and length <= 200
             end)
    end
  end
end
