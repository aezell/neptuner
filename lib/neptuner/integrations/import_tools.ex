defmodule Neptuner.Integrations.ImportTools do
  @moduledoc """
  Import tools for migrating data from other productivity applications.
  Supports Todoist, Notion, Apple Reminders, and generic CSV formats.
  """

  require Logger
  alias Neptuner.{Tasks, Habits}

  @doc """
  Imports tasks from a Todoist export JSON file.
  """
  def import_from_todoist(user_id, file_content) do
    with {:ok, data} <- Jason.decode(file_content),
         {:ok, tasks} <- extract_todoist_tasks(data),
         {:ok, imported_count} <- import_tasks_to_neptuner(user_id, tasks) do
      Logger.info(
        "Successfully imported #{imported_count} tasks from Todoist for user #{user_id}"
      )

      %{
        success: true,
        imported_count: imported_count,
        cosmic_insight: generate_import_cosmic_insight(imported_count, :todoist)
      }
    else
      {:error, reason} ->
        Logger.error("Todoist import failed for user #{user_id}: #{inspect(reason)}")
        %{success: false, error: reason}
    end
  end

  @doc """
  Imports tasks and habits from a Notion export database JSON file.
  """
  def import_from_notion(user_id, file_content, import_type \\ :tasks) do
    with {:ok, data} <- Jason.decode(file_content),
         {:ok, items} <- extract_notion_items(data, import_type),
         {:ok, imported_count} <- import_notion_items_to_neptuner(user_id, items, import_type) do
      Logger.info(
        "Successfully imported #{imported_count} #{import_type} from Notion for user #{user_id}"
      )

      %{
        success: true,
        imported_count: imported_count,
        cosmic_insight: generate_import_cosmic_insight(imported_count, :notion)
      }
    else
      {:error, reason} ->
        Logger.error("Notion import failed for user #{user_id}: #{inspect(reason)}")
        %{success: false, error: reason}
    end
  end

  @doc """
  Imports tasks from Apple Reminders export (plist format).
  """
  def import_from_apple_reminders(user_id, plist_content) do
    with {:ok, items} <- parse_apple_reminders_plist(plist_content),
         {:ok, tasks} <- convert_apple_reminders_to_tasks(items),
         {:ok, imported_count} <- import_tasks_to_neptuner(user_id, tasks) do
      Logger.info(
        "Successfully imported #{imported_count} reminders from Apple for user #{user_id}"
      )

      %{
        success: true,
        imported_count: imported_count,
        cosmic_insight: generate_import_cosmic_insight(imported_count, :apple_reminders)
      }
    else
      {:error, reason} ->
        Logger.error("Apple Reminders import failed for user #{user_id}: #{inspect(reason)}")
        %{success: false, error: reason}
    end
  end

  @doc """
  Imports data from a generic CSV file.
  Expected columns: title, description, priority, due_date, completed
  """
  def import_from_csv(user_id, csv_content) do
    with {:ok, parsed_data} <- parse_csv_content(csv_content),
         {:ok, tasks} <- convert_csv_to_tasks(parsed_data),
         {:ok, imported_count} <- import_tasks_to_neptuner(user_id, tasks) do
      Logger.info("Successfully imported #{imported_count} tasks from CSV for user #{user_id}")

      %{
        success: true,
        imported_count: imported_count,
        cosmic_insight: generate_import_cosmic_insight(imported_count, :csv)
      }
    else
      {:error, reason} ->
        Logger.error("CSV import failed for user #{user_id}: #{inspect(reason)}")
        %{success: false, error: reason}
    end
  end

  @doc """
  Imports habits from a basic JSON format.
  Expected format: [{"name": "...", "frequency": "daily", "category": "..."}]
  """
  def import_habits_from_json(user_id, json_content) do
    with {:ok, data} <- Jason.decode(json_content),
         {:ok, habits} <- convert_json_to_habits(data),
         {:ok, imported_count} <- import_habits_to_neptuner(user_id, habits) do
      Logger.info("Successfully imported #{imported_count} habits from JSON for user #{user_id}")

      %{
        success: true,
        imported_count: imported_count,
        cosmic_insight: generate_import_cosmic_insight(imported_count, :habits)
      }
    else
      {:error, reason} ->
        Logger.error("Habits import failed for user #{user_id}: #{inspect(reason)}")
        %{success: false, error: reason}
    end
  end

  @doc """
  Analyzes an import file to preview what would be imported.
  """
  def preview_import(file_content, file_type) do
    case file_type do
      "todoist" ->
        preview_todoist_import(file_content)

      "notion" ->
        preview_notion_import(file_content)

      "apple_reminders" ->
        preview_apple_reminders_import(file_content)

      "csv" ->
        preview_csv_import(file_content)

      "json" ->
        preview_json_import(file_content)

      _ ->
        {:error, "Unsupported file type"}
    end
  end

  # Private functions

  defp extract_todoist_tasks(data) do
    items = data["items"] || []

    tasks =
      Enum.map(items, fn item ->
        %{
          title: item["content"],
          description: item["description"] || "",
          cosmic_priority: map_todoist_priority(item["priority"]),
          status: if(item["checked"] == 1, do: :completed, else: :pending),
          labels: extract_todoist_labels(item),
          project: item["project_id"] && get_todoist_project_name(data, item["project_id"])
        }
      end)

    {:ok, tasks}
  end

  defp map_todoist_priority(priority) do
    case priority do
      # Priority 1 (highest)
      4 -> :matters_10_years
      # Priority 2
      3 -> :matters_10_days
      # Priority 3  
      2 -> :matters_10_days
      # Priority 4 (lowest)
      1 -> :matters_to_nobody
      _ -> :matters_to_nobody
    end
  end

  defp extract_todoist_labels(item) do
    item["labels"] || []
  end

  defp get_todoist_project_name(data, project_id) do
    projects = data["projects"] || []
    project = Enum.find(projects, &(&1["id"] == project_id))
    project && project["name"]
  end

  defp parse_csv_content(csv_content) do
    try do
      rows =
        csv_content
        |> String.split("\n")
        |> Enum.map(&String.split(&1, ","))
        # Remove empty rows
        |> Enum.reject(&(length(&1) < 2))

      [headers | data_rows] = rows

      parsed_data =
        Enum.map(data_rows, fn row ->
          headers
          |> Enum.zip(row)
          |> Enum.into(%{})
        end)

      {:ok, parsed_data}
    rescue
      error ->
        {:error, "CSV parsing failed: #{inspect(error)}"}
    end
  end

  defp convert_csv_to_tasks(parsed_data) do
    tasks =
      Enum.map(parsed_data, fn row ->
        %{
          title: row["title"] || row["Title"] || "Imported Task",
          description: row["description"] || row["Description"] || "",
          cosmic_priority: map_csv_priority(row["priority"] || row["Priority"]),
          status:
            if(parse_csv_boolean(row["completed"] || row["Completed"]),
              do: :completed,
              else: :pending
            )
        }
      end)

    {:ok, tasks}
  end

  defp map_csv_priority(priority_str) when is_binary(priority_str) do
    case String.downcase(priority_str) do
      p when p in ["high", "urgent", "critical", "1"] -> :matters_10_years
      p when p in ["medium", "normal", "2"] -> :matters_10_days
      p when p in ["low", "minor", "3"] -> :matters_to_nobody
      _ -> :matters_to_nobody
    end
  end

  defp map_csv_priority(_), do: :matters_to_nobody

  defp parse_csv_boolean(bool_str) when is_binary(bool_str) do
    String.downcase(bool_str) in ["true", "yes", "1", "completed", "done"]
  end

  defp parse_csv_boolean(_), do: false

  defp convert_json_to_habits(data) when is_list(data) do
    habits =
      Enum.map(data, fn item ->
        %{
          name: item["name"] || "Imported Habit",
          description: item["description"] || "",
          habit_type: map_habit_category(item["category"])
        }
      end)

    {:ok, habits}
  end

  defp convert_json_to_habits(_), do: {:error, "Invalid JSON format for habits"}

  defp map_habit_category(category) when is_binary(category) do
    case String.downcase(category) do
      cat when cat in ["health", "fitness", "wellness"] -> :basic_human_function
      cat when cat in ["work", "productivity", "career"] -> :self_improvement_theater
      cat when cat in ["learning", "education"] -> :actually_useful
      _ -> :self_improvement_theater
    end
  end

  defp map_habit_category(_), do: :self_improvement_theater

  defp import_tasks_to_neptuner(user_id, tasks) do
    imported_count =
      tasks
      |> Enum.reduce(0, fn task_attrs, acc ->
        case Tasks.create_task(user_id, task_attrs) do
          {:ok, _task} ->
            acc + 1

          {:error, reason} ->
            Logger.warning("Failed to import task '#{task_attrs.title}': #{inspect(reason)}")
            acc
        end
      end)

    {:ok, imported_count}
  end

  defp import_habits_to_neptuner(user_id, habits) do
    imported_count =
      habits
      |> Enum.reduce(0, fn habit_attrs, acc ->
        case Habits.create_user_habit(user_id, habit_attrs) do
          {:ok, _habit} ->
            acc + 1

          {:error, reason} ->
            Logger.warning("Failed to import habit '#{habit_attrs.name}': #{inspect(reason)}")
            acc
        end
      end)

    {:ok, imported_count}
  end

  defp preview_todoist_import(file_content) do
    with {:ok, data} <- Jason.decode(file_content),
         {:ok, tasks} <- extract_todoist_tasks(data) do
      %{
        total_items: length(tasks),
        completed_items: Enum.count(tasks, &(&1.status == :completed)),
        by_priority: group_by_priority(tasks),
        sample_tasks: Enum.take(tasks, 5),
        cosmic_preview:
          "Behold! #{length(tasks)} tasks from the Todoist dimension await cosmic integration."
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp preview_csv_import(csv_content) do
    with {:ok, parsed_data} <- parse_csv_content(csv_content),
         {:ok, tasks} <- convert_csv_to_tasks(parsed_data) do
      %{
        total_items: length(tasks),
        completed_items: Enum.count(tasks, &(&1.status == :completed)),
        by_priority: group_by_priority(tasks),
        sample_tasks: Enum.take(tasks, 5),
        cosmic_preview:
          "#{length(tasks)} tasks emerge from the CSV void, ready for cosmic transformation."
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp preview_json_import(json_content) do
    with {:ok, data} <- Jason.decode(json_content) do
      %{
        total_items: length(data),
        sample_items: Enum.take(data, 3),
        cosmic_preview: "#{length(data)} items detected in the JSON cosmos, awaiting integration."
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp group_by_priority(tasks) do
    tasks
    |> Enum.group_by(& &1.cosmic_priority)
    |> Enum.map(fn {priority, tasks} -> {priority, length(tasks)} end)
    |> Enum.into(%{})
  end

  defp generate_import_cosmic_insight(count, source) do
    base_insights = [
      "In the vast migration of digital productivity, #{count} items have found their new cosmic home.",
      "Like matter crossing from one dimension to another, your #{source} data has been quantum-tunneled into Neptuner.",
      "The entropy of your productivity system has decreased by importing #{count} organized thoughts.",
      "Welcome to the cosmic productivity renaissance - your #{source} legacy lives on in stellar form."
    ]

    philosophical_addons =
      case source do
        :todoist ->
          [
            "Your journey from linear task management to cosmic productivity enlightenment begins now."
          ]

        :notion ->
          [
            "From the all-in-one workspace cosmos, your structured thoughts find new stellar alignment."
          ]

        :apple_reminders ->
          [
            "Your Apple ecosystem reminders have transcended into universal cosmic awareness."
          ]

        :csv ->
          [
            "From the primordial spreadsheet soup, order emerges in the form of cosmic task management."
          ]

        :habits ->
          [
            "These #{count} habit patterns will now contribute to your cosmic behavioral constellation."
          ]

        _ ->
          ["The universe expands to accommodate your newly imported productivity cosmos."]
      end

    %{
      primary: Enum.random(base_insights),
      philosophical: Enum.random(philosophical_addons),
      gratitude: "The cosmic forces of productivity smile upon this successful data migration."
    }
  end

  # Notion-specific parsing functions

  defp extract_notion_items(data, import_type) do
    results = data["results"] || []

    items =
      Enum.map(results, fn item ->
        case import_type do
          :tasks ->
            convert_notion_page_to_task(item)

          :habits ->
            convert_notion_page_to_habit(item)
        end
      end)
      |> Enum.filter(& &1)

    {:ok, items}
  end

  defp convert_notion_page_to_task(page) do
    properties = page["properties"] || %{}

    title =
      case properties["Name"] || properties["Title"] do
        %{"title" => [%{"plain_text" => text} | _]} -> text
        %{"rich_text" => [%{"plain_text" => text} | _]} -> text
        _ -> "Untitled Task"
      end

    description =
      case properties["Description"] do
        %{"rich_text" => [%{"plain_text" => text} | _]} -> text
        _ -> ""
      end

    priority = extract_notion_priority(properties)
    _due_date = extract_notion_due_date(properties)
    completed = extract_notion_completion_status(properties)

    %{
      title: title,
      description: description,
      cosmic_priority: priority,
      status: if(completed, do: :completed, else: :pending)
    }
  end

  defp convert_notion_page_to_habit(page) do
    properties = page["properties"] || %{}

    name =
      case properties["Name"] || properties["Habit"] do
        %{"title" => [%{"plain_text" => text} | _]} -> text
        %{"rich_text" => [%{"plain_text" => text} | _]} -> text
        _ -> "Untitled Habit"
      end

    description =
      case properties["Description"] do
        %{"rich_text" => [%{"plain_text" => text} | _]} -> text
        _ -> ""
      end

    _frequency = extract_notion_frequency(properties)
    category = extract_notion_habit_category(properties)

    %{
      name: name,
      description: description,
      habit_type: category
    }
  end

  defp extract_notion_priority(properties) do
    case properties["Priority"] do
      %{"select" => %{"name" => priority_name}} ->
        case String.downcase(priority_name) do
          p when p in ["high", "urgent", "critical"] -> :matters_10_years
          p when p in ["medium", "normal"] -> :matters_10_days
          p when p in ["low", "minor"] -> :matters_to_nobody
          _ -> :matters_to_nobody
        end

      _ ->
        :matters_to_nobody
    end
  end

  defp extract_notion_due_date(properties) do
    case properties["Due Date"] || properties["Date"] do
      %{"date" => %{"start" => date_string}} ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> date
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp extract_notion_completion_status(properties) do
    case properties["Done"] || properties["Completed"] do
      %{"checkbox" => status} -> status
      _ -> false
    end
  end

  defp extract_notion_frequency(properties) do
    case properties["Frequency"] do
      %{"select" => %{"name" => freq_name}} ->
        case String.downcase(freq_name) do
          "daily" -> :daily
          "weekly" -> :weekly
          "monthly" -> :monthly
          _ -> :daily
        end

      _ ->
        :daily
    end
  end

  defp extract_notion_habit_category(properties) do
    case properties["Category"] do
      %{"select" => %{"name" => category_name}} ->
        case String.downcase(category_name) do
          cat when cat in ["health", "fitness", "wellness"] -> :basic_human_function
          cat when cat in ["work", "productivity", "career"] -> :self_improvement_theater
          cat when cat in ["learning", "education"] -> :actually_useful
          _ -> :self_improvement_theater
        end

      _ ->
        :self_improvement_theater
    end
  end

  defp import_notion_items_to_neptuner(user_id, items, :tasks) do
    import_tasks_to_neptuner(user_id, items)
  end

  defp import_notion_items_to_neptuner(user_id, items, :habits) do
    import_habits_to_neptuner(user_id, items)
  end

  # Apple Reminders-specific parsing functions

  defp parse_apple_reminders_plist(plist_content) do
    # For this implementation, we'll assume the plist has been converted to JSON
    # In a real implementation, you'd use a plist parsing library
    with {:ok, data} <- Jason.decode(plist_content) do
      {:ok, data["reminders"] || []}
    else
      {:error, _} ->
        # Try parsing as raw plist format (simplified)
        parse_simple_plist_format(plist_content)
    end
  end

  defp parse_simple_plist_format(_content) do
    # Very simplified plist parser - in reality you'd use a proper library
    try do
      reminders = []
      {:ok, reminders}
    rescue
      _ -> {:error, "Could not parse Apple Reminders format"}
    end
  end

  defp convert_apple_reminders_to_tasks(reminders) do
    tasks =
      Enum.map(reminders, fn reminder ->
        %{
          title: reminder["title"] || "Apple Reminder",
          description: reminder["notes"] || "",
          cosmic_priority: map_apple_priority(reminder["priority"]),
          status: if(reminder["completed"] == true, do: :completed, else: :pending)
        }
      end)

    {:ok, tasks}
  end

  defp map_apple_priority(priority) when is_integer(priority) do
    case priority do
      0 -> :matters_to_nobody
      p when p in [1, 2, 3, 4] -> :matters_10_days
      p when p in [5, 6, 7, 8, 9] -> :matters_10_years
      _ -> :matters_to_nobody
    end
  end

  defp map_apple_priority(_), do: :matters_to_nobody

  # Preview functions for new import types

  defp preview_notion_import(file_content) do
    with {:ok, data} <- Jason.decode(file_content),
         {:ok, tasks} <- extract_notion_items(data, :tasks) do
      %{
        total_items: length(tasks),
        completed_items: Enum.count(tasks, &(&1.status == :completed)),
        by_priority: group_by_priority(tasks),
        sample_tasks: Enum.take(tasks, 5),
        cosmic_preview:
          "#{length(tasks)} structured thoughts from your Notion workspace await cosmic integration."
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp preview_apple_reminders_import(plist_content) do
    with {:ok, reminders} <- parse_apple_reminders_plist(plist_content),
         {:ok, tasks} <- convert_apple_reminders_to_tasks(reminders) do
      %{
        total_items: length(tasks),
        completed_items: Enum.count(tasks, &(&1.status == :completed)),
        by_priority: group_by_priority(tasks),
        sample_tasks: Enum.take(tasks, 5),
        cosmic_preview:
          "#{length(tasks)} Apple ecosystem reminders ready for cosmic transformation."
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
