defmodule Neptuner.Achievements.AchievementTest do
  use Neptuner.DataCase

  alias Neptuner.Achievements.Achievement

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        key: "test_achievement",
        title: "Test Achievement",
        description: "A test achievement",
        category: "tasks"
      }

      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
    end

    test "changeset with all fields" do
      attrs = %{
        key: "complete_achievement",
        title: "Complete Achievement", 
        description: "A complete test achievement",
        ironic_description: "Another meaningless digital trophy",
        category: "productivity_theater",
        icon: "hero-star",
        color: "purple",
        threshold_value: 42,
        threshold_type: "count",
        is_active: false
      }

      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :key) == "complete_achievement"
      assert get_change(changeset, :threshold_value) == 42
      assert get_change(changeset, :is_active) == false
    end

    test "requires key field" do
      attrs = %{
        title: "Test Achievement",
        description: "A test achievement", 
        category: "tasks"
      }

      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).key
    end

    test "requires title field" do
      attrs = %{
        key: "test_achievement",
        description: "A test achievement",
        category: "tasks"
      }

      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "requires description field" do
      attrs = %{
        key: "test_achievement", 
        title: "Test Achievement",
        category: "tasks"
      }

      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
    end

    test "requires category field" do
      attrs = %{
        key: "test_achievement",
        title: "Test Achievement", 
        description: "A test achievement"
      }

      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).category
    end

    test "validates unique key constraint" do
      achievement = insert(:achievement, key: "unique_key")
      
      attrs = %{
        key: "unique_key",
        title: "Another Achievement",
        description: "Should fail due to duplicate key",
        category: "tasks"
      }

      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
      
      {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).key
    end

    test "validates category inclusion" do
      valid_categories = ["tasks", "habits", "meetings", "emails", "connections", "productivity_theater"]
      
      for category <- valid_categories do
        attrs = %{
          key: "test_#{category}",
          title: "Test Achievement",
          description: "A test achievement",
          category: category
        }

        changeset = Achievement.changeset(%Achievement{}, attrs)
        assert changeset.valid?, "Expected #{category} to be valid"
      end

      invalid_attrs = %{
        key: "test_invalid",
        title: "Test Achievement", 
        description: "A test achievement",
        category: "invalid_category"
      }

      changeset = Achievement.changeset(%Achievement{}, invalid_attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).category
    end

    test "validates threshold_type inclusion" do
      valid_types = ["count", "streak", "percentage", "hours", "ratio"]
      
      for threshold_type <- valid_types do
        attrs = %{
          key: "test_#{threshold_type}",
          title: "Test Achievement",
          description: "A test achievement", 
          category: "tasks",
          threshold_type: threshold_type
        }

        changeset = Achievement.changeset(%Achievement{}, attrs)
        assert changeset.valid?, "Expected #{threshold_type} to be valid"
      end

      invalid_attrs = %{
        key: "test_invalid_type",
        title: "Test Achievement",
        description: "A test achievement",
        category: "tasks", 
        threshold_type: "invalid_type"
      }

      changeset = Achievement.changeset(%Achievement{}, invalid_attrs)
      refute changeset.valid?
      assert "must be a valid threshold type" in errors_on(changeset).threshold_type
    end

    test "sets default values" do
      achievement = %Achievement{}
      assert achievement.icon == "hero-trophy"
      assert achievement.color == "yellow" 
      assert achievement.is_active == true
    end
  end

  describe "helper functions" do
    test "category_display_name/1 returns proper display names" do
      assert Achievement.category_display_name("tasks") == "Task Management"
      assert Achievement.category_display_name("habits") == "Habit Tracking"
      assert Achievement.category_display_name("meetings") == "Meeting Survival"
      assert Achievement.category_display_name("emails") == "Email Archaeology"
      assert Achievement.category_display_name("connections") == "Digital Integration"
      assert Achievement.category_display_name("productivity_theater") == "Productivity Theater"
      assert Achievement.category_display_name("unknown") == "General"
    end

    test "color_class/1 returns proper CSS classes" do
      assert Achievement.color_class("red") == "text-error"
      assert Achievement.color_class("yellow") == "text-warning"
      assert Achievement.color_class("green") == "text-success"
      assert Achievement.color_class("blue") == "text-info"
      assert Achievement.color_class("purple") == "text-secondary"
      assert Achievement.color_class("unknown") == "text-primary"
    end

    test "badge_class/1 returns proper badge classes" do
      assert Achievement.badge_class("red") == "badge-error"
      assert Achievement.badge_class("yellow") == "badge-warning"
      assert Achievement.badge_class("green") == "badge-success"
      assert Achievement.badge_class("blue") == "badge-info"
      assert Achievement.badge_class("purple") == "badge-secondary"
      assert Achievement.badge_class("unknown") == "badge-primary"
    end
  end
end