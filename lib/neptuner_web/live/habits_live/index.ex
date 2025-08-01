defmodule NeptunerWeb.HabitsLive.Index do
  use NeptunerWeb, :live_view

  alias Neptuner.Habits
  alias Neptuner.Habits.Habit

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "Existential Habit Tracking")
      |> assign(:user_id, user_id)
      |> assign(:filter_type, "all")
      |> assign(:show_insights, false)
      |> assign(:form, to_form(Habits.change_habit(%Habit{})))
      |> load_habits()
      |> load_statistics()

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:habit, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:habit, %Habit{})
    |> assign(:form, to_form(Habits.change_habit(%Habit{})))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    habit = Habits.get_user_habit!(socket.assigns.user_id, id)

    socket
    |> assign(:habit, habit)
    |> assign(:form, to_form(Habits.change_habit(habit)))
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    socket =
      socket
      |> assign(:filter_type, type)
      |> load_habits()

    {:noreply, socket}
  end

  def handle_event("toggle_insights", _params, socket) do
    {:noreply, assign(socket, :show_insights, !socket.assigns.show_insights)}
  end

  def handle_event("check_in_habit", %{"id" => id}, socket) do
    habit_id = String.to_integer(id)
    today = Date.utc_today()

    case Habits.check_in_habit(habit_id, today) do
      {:ok, _entry} ->
        socket =
          socket
          |> put_flash(
            :info,
            "Habit checked in! The universe notices your dedication (probably)."
          )
          |> load_habits()
          |> load_statistics()

        {:noreply, socket}

      {:error, %Ecto.Changeset{errors: errors}} ->
        error_message =
          if Keyword.has_key?(errors, :completed_on) do
            "Already checked in today. Overachievement detected."
          else
            "Unable to check in habit"
          end

        {:noreply, put_flash(socket, :error, error_message)}
    end
  end

  def handle_event("delete_habit", %{"id" => id}, socket) do
    habit = Habits.get_user_habit!(socket.assigns.user_id, id)

    case Habits.delete_habit(habit) do
      {:ok, _habit} ->
        socket =
          socket
          |> put_flash(
            :info,
            "Habit deleted. Sometimes giving up is the most honest thing you can do."
          )
          |> load_habits()
          |> load_statistics()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete habit")}
    end
  end

  def handle_event("save_habit", %{"habit" => habit_params}, socket) do
    save_habit(socket, socket.assigns.live_action, habit_params)
  end

  def handle_event("validate_habit", %{"habit" => habit_params}, socket) do
    changeset =
      socket.assigns.habit
      |> Habits.change_habit(habit_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("suggest_habit_type", %{"name" => name}, socket) when name != "" do
    suggestion = suggest_habit_type(name)

    socket =
      if suggestion do
        put_flash(socket, :info, "Existential suggestion: #{suggestion}")
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("suggest_habit_type", _params, socket), do: {:noreply, socket}

  defp save_habit(socket, :edit, habit_params) do
    case Habits.update_habit(socket.assigns.habit, habit_params) do
      {:ok, _habit} ->
        socket =
          socket
          |> put_flash(:info, "Habit updated successfully")
          |> push_navigate(to: ~p"/habits")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_habit(socket, :new, habit_params) do
    case Habits.create_habit(socket.assigns.user_id, habit_params) do
      {:ok, _habit} ->
        socket =
          socket
          |> put_flash(:info, "Habit created successfully")
          |> push_navigate(to: ~p"/habits")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp load_habits(socket) do
    user_id = socket.assigns.user_id
    type_filter = socket.assigns.filter_type

    habits =
      case type_filter do
        "all" ->
          Habits.list_habits(user_id)

        type when type != "all" ->
          type_atom = String.to_existing_atom(type)

          Habits.list_habits(user_id)
          |> Enum.filter(&(&1.habit_type == type_atom))
      end

    habits_with_today_status = Enum.map(habits, &add_today_status/1)
    stream(socket, :habits, habits_with_today_status, reset: true)
  end

  defp add_today_status(habit) do
    today = Date.utc_today()
    today_entries = Habits.list_habit_entries(habit.id)

    checked_in_today =
      Enum.any?(today_entries, fn entry ->
        Date.compare(entry.completed_on, today) == :eq
      end)

    Map.put(habit, :checked_in_today, checked_in_today)
  end

  defp load_statistics(socket) do
    stats = Habits.get_habit_statistics(socket.assigns.user_id)
    assign(socket, :stats, stats)
  end

  defp suggest_habit_type(name) do
    name_lower = String.downcase(name)

    cond do
      String.contains?(name_lower, ["sleep", "eat", "shower", "brush", "drink water", "exercise"]) ->
        "Basic biological maintenance. Probably: basic_human_function"

      String.contains?(name_lower, ["meditate", "journal", "read", "gratitude", "affirmation"]) ->
        "Classic self-help ritual detected. Likely: self_improvement_theater"

      String.contains?(name_lower, ["skill", "practice", "learn", "study", "work", "save money"]) ->
        "Might actually improve your life. Consider: actually_useful"

      String.contains?(name_lower, ["track", "log", "measure", "optimize", "productivity"]) ->
        "Meta-productivity theater. Almost certainly: self_improvement_theater"

      true ->
        "Most habits are performance art. Start with self_improvement_theater and prove otherwise."
    end
  end

  defp type_badge_class(:basic_human_function), do: "badge-success"
  defp type_badge_class(:self_improvement_theater), do: "badge-warning"
  defp type_badge_class(:actually_useful), do: "badge-info"

  defp format_habit_type(:basic_human_function), do: "Basic Function"
  defp format_habit_type(:self_improvement_theater), do: "Theater"
  defp format_habit_type(:actually_useful), do: "Actually Useful"

  defp streak_color(streak) when streak >= 30, do: "text-purple-600 font-bold"
  defp streak_color(streak) when streak >= 14, do: "text-green-600 font-semibold"
  defp streak_color(streak) when streak >= 7, do: "text-blue-600"
  defp streak_color(streak) when streak > 0, do: "text-gray-600"
  defp streak_color(_), do: "text-gray-400"

  defp get_latest_commentary(habit) do
    case Habits.list_habit_entries(habit.id) do
      [latest_entry | _] -> latest_entry.existential_commentary
      [] -> "No existential insights yet. The void of habit formation awaits."
    end
  end

  defp days_since_last_entry(habit) do
    case Habits.list_habit_entries(habit.id) do
      [latest_entry | _] ->
        Date.diff(Date.utc_today(), latest_entry.completed_on)

      [] ->
        "∞"
    end
  end
end
