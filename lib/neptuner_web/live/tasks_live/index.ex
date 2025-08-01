defmodule NeptunerWeb.TasksLive.Index do
  use NeptunerWeb, :live_view

  alias Neptuner.{Tasks, Subscriptions, Achievements}
  alias Neptuner.Tasks.Task

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "Cosmic Task Management")
      |> assign(:user_id, user_id)
      |> assign(:filter_priority, "all")
      |> assign(:filter_status, "all")
      |> assign(:show_reality_check, false)
      |> assign(:form, to_form(Tasks.change_task(%Task{})))
      |> load_tasks()
      |> load_statistics()

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:task, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:task, %Task{})
    |> assign(:form, to_form(Tasks.change_task(%Task{})))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    task = Tasks.get_user_task!(socket.assigns.user_id, id)

    socket
    |> assign(:task, task)
    |> assign(:form, to_form(Tasks.change_task(task)))
  end

  def handle_event("filter_priority", %{"priority" => priority}, socket) do
    socket =
      socket
      |> assign(:filter_priority, priority)
      |> load_tasks()

    {:noreply, socket}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    socket =
      socket
      |> assign(:filter_status, status)
      |> load_tasks()

    {:noreply, socket}
  end

  def handle_event("toggle_reality_check", _params, socket) do
    {:noreply, assign(socket, :show_reality_check, !socket.assigns.show_reality_check)}
  end

  def handle_event("complete_task", %{"id" => id}, socket) do
    task = Tasks.get_user_task!(socket.assigns.user_id, id)

    case Tasks.complete_task(task) do
      {:ok, _task} ->
        # Check for new achievements
        {:ok, newly_completed} = Achievements.check_achievements_for_user(socket.assigns.user_id)

        achievement_message =
          case length(newly_completed) do
            0 -> ""
            1 -> " 🏆 Achievement unlocked!"
            count -> " 🏆 #{count} achievements unlocked!"
          end

        socket =
          socket
          |> put_flash(
            :info,
            "Task completed! Another step toward enlightenment (or busy work).#{achievement_message}"
          )
          |> load_tasks()
          |> load_statistics()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to complete task")}
    end
  end

  def handle_event("abandon_task", %{"id" => id}, socket) do
    task = Tasks.get_user_task!(socket.assigns.user_id, id)

    case Tasks.abandon_task(task) do
      {:ok, _task} ->
        socket =
          socket
          |> put_flash(
            :info,
            "Task wisely abandoned. Sometimes the most productive thing is to stop."
          )
          |> load_tasks()
          |> load_statistics()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to abandon task")}
    end
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    task = Tasks.get_user_task!(socket.assigns.user_id, id)

    case Tasks.delete_task(task) do
      {:ok, _task} ->
        socket =
          socket
          |> put_flash(:info, "Task deleted. It never existed. Very zen.")
          |> load_tasks()
          |> load_statistics()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete task")}
    end
  end

  def handle_event("save_task", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.live_action, task_params)
  end

  def handle_event("validate_task", %{"task" => task_params}, socket) do
    changeset =
      socket.assigns.task
      |> Tasks.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("suggest_priority", %{"title" => title}, socket) when title != "" do
    suggestion = suggest_cosmic_priority(title)

    socket =
      if suggestion do
        put_flash(socket, :info, "Cosmic suggestion: #{suggestion}")
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("suggest_priority", _params, socket), do: {:noreply, socket}

  defp save_task(socket, :edit, task_params) do
    case Tasks.update_task(socket.assigns.task, task_params) do
      {:ok, _task} ->
        socket =
          socket
          |> put_flash(:info, "Task updated successfully")
          |> push_navigate(to: ~p"/tasks")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_task(socket, :new, task_params) do
    user = socket.assigns.current_scope.user
    current_task_count = length(socket.assigns.tasks)

    if Subscriptions.within_limit?(user, :tasks_limit, current_task_count) do
      case Tasks.create_task(socket.assigns.user_id, task_params) do
        {:ok, _task} ->
          socket =
            socket
            |> put_flash(:info, "Task created successfully")
            |> push_navigate(to: ~p"/tasks")

          {:noreply, socket}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    else
      limit = Subscriptions.get_feature_limit(user, :tasks_limit)

      socket =
        socket
        |> put_flash(
          :error,
          "Task limit reached (#{limit}). Upgrade to Cosmic Enlightenment for unlimited tasks."
        )
        |> push_navigate(to: ~p"/subscription")

      {:noreply, socket}
    end
  end

  defp load_tasks(socket) do
    user_id = socket.assigns.user_id
    priority_filter = socket.assigns.filter_priority
    status_filter = socket.assigns.filter_status

    tasks =
      case {priority_filter, status_filter} do
        {"all", "all"} ->
          Tasks.list_tasks(user_id)

        {priority, "all"} when priority != "all" ->
          priority_atom = String.to_existing_atom(priority)
          Tasks.list_tasks_by_cosmic_priority(user_id, priority_atom)

        {"all", status} when status != "all" ->
          status_atom = String.to_existing_atom(status)
          Tasks.list_tasks_by_status(user_id, status_atom)

        {priority, status} ->
          priority_atom = String.to_existing_atom(priority)
          status_atom = String.to_existing_atom(status)

          Tasks.list_tasks(user_id)
          |> Enum.filter(&(&1.cosmic_priority == priority_atom and &1.status == status_atom))
      end

    stream(socket, :tasks, tasks, reset: true)
  end

  defp load_statistics(socket) do
    stats = Tasks.get_task_statistics(socket.assigns.user_id)
    assign(socket, :stats, stats)
  end

  defp suggest_cosmic_priority(title) do
    title_lower = String.downcase(title)

    cond do
      String.contains?(title_lower, [
        "health",
        "family",
        "relationship",
        "career",
        "education",
        "finance"
      ]) ->
        "This might actually matter in 10 years. Consider: matters_10_years"

      String.contains?(title_lower, ["urgent", "deadline", "meeting", "call", "appointment"]) ->
        "Seems time-sensitive. Maybe: matters_10_days"

      String.contains?(title_lower, [
        "email",
        "slack",
        "organize",
        "clean",
        "sort",
        "update",
        "check"
      ]) ->
        "Classic busy work detected. Probably: matters_to_nobody"

      String.length(title) > 100 ->
        "The longer the description, the less important it usually is. Likely: matters_to_nobody"

      true ->
        "Most tasks matter to nobody. Start there and prove otherwise."
    end
  end

  defp priority_badge_class(:matters_10_years), do: "badge-error"
  defp priority_badge_class(:matters_10_days), do: "badge-warning"
  defp priority_badge_class(:matters_to_nobody), do: "badge-ghost"

  defp status_badge_class(:pending), do: "badge-info"
  defp status_badge_class(:completed), do: "badge-success"
  defp status_badge_class(:abandoned_wisely), do: "badge-secondary"

  defp format_priority(:matters_10_years), do: "10 Years"
  defp format_priority(:matters_10_days), do: "10 Days"
  defp format_priority(:matters_to_nobody), do: "Nobody"

  defp format_status(:pending), do: "Pending"
  defp format_status(:completed), do: "Completed"
  defp format_status(:abandoned_wisely), do: "Wisely Abandoned"
end
