defmodule Neptuner.Integrations.MicrosoftTasks do
  @moduledoc """
  Microsoft Graph Tasks API integration for syncing Microsoft To Do tasks.
  Transforms productivity tasks into cosmic task management enlightenment.
  """

  require Logger
  alias Neptuner.{Tasks, Connections}
  alias Neptuner.Connections.ServiceConnection

  @microsoft_graph_api_base "https://graph.microsoft.com/v1.0"

  @doc """
  Syncs tasks from Microsoft Graph for a specific connection.
  Returns {:ok, count} on success or {:error, reason} on failure.
  """
  def sync_tasks(%ServiceConnection{} = connection) do
    with {:ok, access_token} <- ensure_valid_token(connection),
         {:ok, task_lists} <- get_task_lists(access_token),
         {:ok, tasks} <- fetch_all_tasks(access_token, task_lists),
         {:ok, count} <- import_tasks(connection, tasks) do
      # Update last sync timestamp
      Connections.update_service_connection(connection, %{
        last_sync_at: DateTime.utc_now(),
        connection_status: :active
      })

      {:ok, count}
    else
      {:error, reason} ->
        Logger.error(
          "Microsoft Tasks sync failed for connection #{connection.id}: #{inspect(reason)}"
        )

        Connections.update_service_connection(connection, %{
          connection_status: :error
        })

        {:error, reason}
    end
  end

  @doc """
  Creates or updates a task in Microsoft To Do from a Neptuner task.
  """
  def create_or_update_task(%ServiceConnection{} = connection, task) do
    with {:ok, access_token} <- ensure_valid_token(connection),
         {:ok, task_lists} <- get_task_lists(access_token),
         {:ok, primary_list} <- get_primary_task_list(task_lists) do
      task_data = transform_neptuner_task_to_microsoft(task)

      case task.external_id do
        nil ->
          create_microsoft_task(access_token, primary_list["id"], task_data)

        external_id ->
          update_microsoft_task(access_token, external_id, task_data)
      end
    end
  end

  @doc """
  Marks a Microsoft To Do task as completed or incomplete.
  """
  def update_task_completion(%ServiceConnection{} = connection, external_id, completed) do
    with {:ok, access_token} <- ensure_valid_token(connection) do
      update_data = %{
        status: if(completed, do: "completed", else: "notStarted"),
        completedDateTime: if(completed, do: DateTime.utc_now() |> DateTime.to_iso8601(), else: nil)
      }

      update_microsoft_task(access_token, external_id, update_data)
    end
  end

  # Private functions

  defp ensure_valid_token(%ServiceConnection{} = connection) do
    if ServiceConnection.needs_refresh?(connection) do
      case Connections.refresh_service_connection_token(connection) do
        {:ok, updated_connection} -> {:ok, updated_connection.access_token}
        {:error, reason} -> {:error, reason}
      end
    else
      {:ok, connection.access_token}
    end
  end

  defp get_task_lists(access_token) do
    url = "#{@microsoft_graph_api_base}/me/todo/lists"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: response}} ->
        task_lists = response["value"] || []
        {:ok, task_lists}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Microsoft task lists fetch failed: #{status} - #{inspect(body)}")
        {:error, "Failed to fetch task lists"}

      {:error, reason} ->
        Logger.error("Microsoft Graph API request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp fetch_all_tasks(access_token, task_lists) do
    all_tasks =
      task_lists
      |> Enum.flat_map(fn task_list ->
        case get_tasks_from_list(access_token, task_list["id"]) do
          {:ok, tasks} ->
            # Add task list info to each task
            Enum.map(tasks, fn task ->
              Map.put(task, "_taskList", task_list)
            end)

          {:error, _} ->
            []
        end
      end)
      |> Enum.filter(&valid_task?/1)

    {:ok, all_tasks}
  end

  defp get_tasks_from_list(access_token, list_id) do
    url = "#{@microsoft_graph_api_base}/me/todo/lists/#{list_id}/tasks"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    params = %{
      top: 100,
      orderBy: "createdDateTime desc"
    }

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: response}} ->
        tasks = response["value"] || []
        {:ok, tasks}

      {:ok, %{status: status, body: body}} ->
        Logger.error(
          "Microsoft tasks fetch failed for list #{list_id}: #{status} - #{inspect(body)}"
        )

        {:error, "Failed to fetch tasks"}

      {:error, reason} ->
        Logger.error("Microsoft tasks API request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp valid_task?(task) do
    # Filter out invalid or corrupted tasks
    task["title"] != nil and task["title"] != ""
  end

  defp import_tasks(connection, tasks) do
    imported_count =
      tasks
      |> Enum.map(fn task -> {transform_to_neptuner_task(connection, task), task} end)
      |> Enum.filter(fn {task_attrs, _task} -> task_attrs != nil end)
      |> Enum.reduce(0, fn {task_attrs, task}, acc ->
        case Tasks.create_task(connection.user_id, task_attrs) do
          {:ok, _task} ->
            acc + 1

          {:error, reason} ->
            Logger.warning("Failed to import task #{task["id"]}: #{inspect(reason)}")
            acc
        end
      end)

    {:ok, imported_count}
  end

  defp transform_to_neptuner_task(_connection, task) do
    due_date = parse_microsoft_date(task["dueDateTime"])
    completed_at = if task["status"] == "completed", do: parse_microsoft_date(task["completedDateTime"]), else: nil
    
    # Apply cosmic task analysis
    priority = determine_cosmic_priority(task)
    significance_level = calculate_cosmic_significance(task, due_date)
    
    %{
      external_id: task_to_external_id(task),
      title: task["title"] || "Untitled Cosmic Task",
      description: extract_task_description(task),
      priority: priority,
      due_date: due_date,
      completed: task["status"] == "completed",
      completed_at: completed_at,
      list_name: get_task_list_name(task),
      external_created_at: parse_microsoft_date(task["createdDateTime"]),
      external_updated_at: parse_microsoft_date(task["lastModifiedDateTime"]),
      synced_at: DateTime.utc_now(),
      # Cosmic analysis fields
      cosmic_significance: significance_level,
      procrastination_index: calculate_procrastination_index(task, due_date),
      existential_weight: assess_existential_weight(task)
    }
  end

  defp transform_neptuner_task_to_microsoft(task) do
    %{
      title: task.title,
      body: %{
        content: task.description || "",
        contentType: "text"
      },
      dueDateTime: if(task.due_date, do: %{
        dateTime: DateTime.to_iso8601(task.due_date),
        timeZone: "UTC"
      }, else: nil),
      importance: map_priority_to_importance(task.priority),
      status: if(task.completed, do: "completed", else: "notStarted")
    }
  end

  defp create_microsoft_task(access_token, list_id, task_data) do
    url = "#{@microsoft_graph_api_base}/me/todo/lists/#{list_id}/tasks"
    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    case Req.post(url, headers: headers, json: task_data) do
      {:ok, %{status: 201, body: response}} ->
        {:ok, response}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Microsoft task creation failed: #{status} - #{inspect(body)}")
        {:error, "Task creation failed"}

      {:error, reason} ->
        Logger.error("Microsoft task creation request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp update_microsoft_task(access_token, task_id, task_data) do
    # Extract task ID from external ID if needed
    actual_task_id = String.replace(task_id, "microsoft_tasks_", "")
    
    url = "#{@microsoft_graph_api_base}/me/todo/lists/tasks/#{actual_task_id}"
    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    case Req.patch(url, headers: headers, json: task_data) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, response}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Microsoft task update failed: #{status} - #{inspect(body)}")
        {:error, "Task update failed"}

      {:error, reason} ->
        Logger.error("Microsoft task update request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp get_primary_task_list(task_lists) do
    # Find the default task list or use the first one
    primary = Enum.find(task_lists, fn list ->
      list["isDefaultList"] == true or list["wellknownListName"] == "defaultList"
    end) || List.first(task_lists)

    if primary do
      {:ok, primary}
    else
      {:error, "No task list found"}
    end
  end

  defp parse_microsoft_date(nil), do: nil
  defp parse_microsoft_date(%{"dateTime" => date_time}) when is_binary(date_time) do
    case DateTime.from_iso8601(date_time) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_microsoft_date(date_time) when is_binary(date_time) do
    case DateTime.from_iso8601(date_time) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_microsoft_date(_), do: nil

  defp determine_cosmic_priority(task) do
    title = String.downcase(task["title"] || "")
    importance = task["importance"]

    cond do
      importance == "high" -> :matters_10_years
      String.contains?(title, ["urgent", "critical", "asap", "important"]) -> :matters_10_years
      String.contains?(title, ["someday", "maybe", "consider", "might"]) -> :matters_to_nobody
      String.contains?(title, ["routine", "daily", "weekly"]) -> :matters_10_days
      importance == "low" -> :matters_to_nobody
      true -> :matters_10_days
    end
  end

  defp calculate_cosmic_significance(task, due_date) do
    title = String.downcase(task["title"] || "")
    base_significance = 50

    # Due date urgency (the cosmic pressure of time)
    time_pressure = 
      if due_date do
        days_until_due = DateTime.diff(due_date, DateTime.utc_now(), :day)
        cond do
          days_until_due < 0 -> 25  # Overdue tasks gain cosmic weight
          days_until_due == 0 -> 20  # Today's tasks are significant
          days_until_due <= 3 -> 15  # Imminent tasks
          days_until_due <= 7 -> 10  # This week
          days_until_due <= 30 -> 5  # This month
          true -> 0  # Future tasks fade into cosmic background
        end
      else
        -10  # Tasks without deadlines lose significance in the void
      end

    # Content-based significance analysis
    content_weight = cond do
      String.contains?(title, ["project", "goal", "vision", "strategy"]) -> 20
      String.contains?(title, ["meeting", "call", "appointment"]) -> 10
      String.contains?(title, ["email", "respond", "reply"]) -> -5
      String.contains?(title, ["organize", "clean", "sort"]) -> -10
      String.length(title) > 100 -> -5  # Verbose tasks often lack focus
      true -> 0
    end

    # Microsoft importance flag
    importance_bonus = case task["importance"] do
      "high" -> 15
      "low" -> -10
      _ -> 0
    end

    total_significance = base_significance + time_pressure + content_weight + importance_bonus
    max(0, min(100, total_significance))
  end

  defp calculate_procrastination_index(task, due_date) do
    created_at = parse_microsoft_date(task["createdDateTime"])
    
    if created_at && due_date do
      total_time = DateTime.diff(due_date, created_at, :day)
      time_remaining = DateTime.diff(due_date, DateTime.utc_now(), :day)
      
      if total_time > 0 do
        procrastination_ratio = 1 - (time_remaining / total_time)
        round(procrastination_ratio * 100)
      else
        0
      end
    else
      # No due date = infinite procrastination potential
      if created_at do
        days_old = DateTime.diff(DateTime.utc_now(), created_at, :day)
        min(100, days_old * 2)
      else
        50
      end
    end
  end

  defp assess_existential_weight(task) do
    title = String.downcase(task["title"] || "")
    description = task["body"]["content"] || ""
    combined_text = "#{title} #{description}"

    # Existential analysis based on task content
    weight = 0
    
    # Meaningful work patterns
    weight = weight + if String.contains?(combined_text, ["purpose", "meaning", "why", "vision", "impact"]), do: 30, else: 0
    
    # Busy work patterns
    weight = weight - if String.contains?(combined_text, ["status", "update", "sync", "check", "review"]), do: 20, else: 0
    
    # Creative/growth patterns
    weight = weight + if String.contains?(combined_text, ["create", "learn", "grow", "improve", "develop"]), do: 20, else: 0
    
    # Administrative burden
    weight = weight - if String.contains?(combined_text, ["expense", "receipt", "form", "paperwork"]), do: 15, else: 0
    
    # Personal development
    weight = weight + if String.contains?(combined_text, ["skill", "course", "book", "practice"]), do: 15, else: 0

    max(0, min(100, 50 + weight))
  end

  defp extract_task_description(task) do
    case task["body"] do
      %{"content" => content} when is_binary(content) and content != "" -> content
      _ -> nil
    end
  end

  defp get_task_list_name(task) do
    case task["_taskList"] do
      %{"displayName" => name} -> name
      _ -> "Tasks"
    end
  end

  defp task_to_external_id(task) do
    "microsoft_tasks_#{task["id"]}"
  end

  defp map_priority_to_importance(priority) do
    case priority do
      :matters_10_years -> "high"
      :matters_10_days -> "normal"
      :matters_to_nobody -> "low"
      _ -> "normal"
    end
  end
end