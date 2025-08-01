defmodule Neptuner.Integrations.ImportToolsTest do
  use Neptuner.DataCase
  alias Neptuner.Integrations.ImportTools
  alias Neptuner.{Tasks, Habits}

  describe "import_from_todoist/2" do
    test "imports tasks from valid Todoist JSON" do
      user = insert(:user)

      todoist_json = """
      {
        "items": [
          {
            "content": "Complete project proposal",
            "description": "Draft the Q4 project proposal",
            "priority": 4,
            "checked": 0,
            "due": {"date": "2024-12-15"},
            "labels": ["work"],
            "project_id": 1
          },
          {
            "content": "Buy groceries",
            "description": "",
            "priority": 1,
            "checked": 1,
            "due": null,
            "labels": [],
            "project_id": 2
          }
        ],
        "projects": [
          {"id": 1, "name": "Work"},
          {"id": 2, "name": "Personal"}
        ]
      }
      """

      result = ImportTools.import_from_todoist(user.id, todoist_json)

      assert result.success == true
      assert result.imported_count == 2
      assert result.cosmic_insight.primary
      assert result.cosmic_insight.philosophical

      # Verify tasks were created
      tasks = Tasks.list_tasks(user.id)
      assert length(tasks) == 2

      task1 = Enum.find(tasks, &(&1.title == "Complete project proposal"))
      assert task1.cosmic_priority == :matters_10_years
      assert task1.status == :pending

      task2 = Enum.find(tasks, &(&1.title == "Buy groceries"))
      assert task2.cosmic_priority == :matters_to_nobody
      assert task2.status == :completed
    end

    test "handles invalid JSON" do
      user = insert(:user)

      result = ImportTools.import_from_todoist(user.id, "invalid json")

      assert result.success == false
      assert result.error
    end
  end

  describe "import_from_csv/2" do
    test "imports tasks from valid CSV" do
      user = insert(:user)

      csv_content = """
      title,description,priority,due_date,completed
      Complete project proposal,Draft the Q4 project proposal,high,2024-12-15,false
      Buy groceries,Weekly grocery shopping,low,,true
      Team meeting,Weekly team sync,medium,2024-08-01,false
      """

      result = ImportTools.import_from_csv(user.id, csv_content)

      assert result.success == true
      assert result.imported_count == 3
      assert result.cosmic_insight.primary

      # Verify tasks were created
      tasks = Tasks.list_tasks(user.id)
      assert length(tasks) == 3

      high_priority_task = Enum.find(tasks, &(&1.cosmic_priority == :matters_10_years))
      assert high_priority_task.title == "Complete project proposal"

      completed_task = Enum.find(tasks, &(&1.status == :completed))
      assert completed_task.title == "Buy groceries"
    end
  end

  describe "import_habits_from_json/2" do
    test "imports habits from valid JSON" do
      user = insert(:user)

      habits_json = """
      [
        {
          "name": "Morning meditation",
          "description": "10 minutes of mindfulness",
          "frequency": "daily",
          "category": "wellness"
        },
        {
          "name": "Read technical articles",
          "description": "Stay updated with industry trends",
          "frequency": "weekly",
          "category": "learning"
        }
      ]
      """

      result = ImportTools.import_habits_from_json(user.id, habits_json)

      assert result.success == true
      assert result.imported_count == 2
      assert result.cosmic_insight.primary

      # Verify habits were created
      habits = Habits.list_habits(user.id)
      assert length(habits) == 2

      meditation_habit = Enum.find(habits, &(&1.name == "Morning meditation"))
      assert meditation_habit.habit_type == :basic_human_function

      reading_habit = Enum.find(habits, &(&1.name == "Read technical articles"))
      assert reading_habit.habit_type == :actually_useful
    end
  end

  describe "preview_import/2" do
    test "previews Todoist import correctly" do
      todoist_json = """
      {
        "items": [
          {
            "content": "Task 1",
            "description": "Description 1",
            "priority": 4,
            "checked": 0
          },
          {
            "content": "Task 2",
            "description": "Description 2",
            "priority": 1,
            "checked": 1
          }
        ]
      }
      """

      result = ImportTools.preview_import(todoist_json, "todoist")

      assert result.total_items == 2
      assert result.completed_items == 1
      assert result.cosmic_preview
      assert length(result.sample_tasks) == 2
    end

    test "previews CSV import correctly" do
      csv_content = """
      title,description,priority,completed
      Task 1,Description 1,high,false
      Task 2,Description 2,low,true
      Task 3,Description 3,medium,false
      """

      result = ImportTools.preview_import(csv_content, "csv")

      assert result.total_items == 3
      assert result.completed_items == 1
      assert result.cosmic_preview
      assert length(result.sample_tasks) == 3
    end
  end
end
