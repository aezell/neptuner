defmodule NeptunerWeb.AchievementsLive.Index do
  use NeptunerWeb, :live_view

  alias Neptuner.Achievements

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "Achievement Deflation Engine")
      |> assign(:user_id, user_id)
      |> assign(:filter_category, "all")
      |> assign(:show_completed_only, false)
      |> load_achievements()
      |> load_statistics()

    {:ok, socket}
  end

  def handle_event("filter_category", %{"category" => category}, socket) do
    socket =
      socket
      |> assign(:filter_category, category)
      |> load_achievements()

    {:noreply, socket}
  end

  def handle_event("toggle_completed", _params, socket) do
    socket =
      socket
      |> assign(:show_completed_only, !socket.assigns.show_completed_only)
      |> load_achievements()

    {:noreply, socket}
  end

  def handle_event("check_achievements", _params, socket) do
    {:ok, newly_completed} = Achievements.check_achievements_for_user(socket.assigns.user_id)

    message =
      case length(newly_completed) do
        0 -> "Achievement check complete - no new achievements unlocked"
        1 -> "🏆 1 new achievement unlocked!"
        count -> "🏆 #{count} new achievements unlocked!"
      end

    socket =
      socket
      |> put_flash(:info, message)
      |> load_achievements()
      |> load_statistics()

    {:noreply, socket}
  end

  defp load_achievements(socket) do
    category =
      if socket.assigns.filter_category == "all", do: nil, else: socket.assigns.filter_category

    user_achievements =
      Achievements.list_user_achievements(socket.assigns.user_id,
        category: category,
        completed_only: socket.assigns.show_completed_only
      )

    all_achievements = Achievements.list_achievements(category: category)

    # Merge user progress with all achievements
    achievements_with_progress =
      all_achievements
      |> Enum.map(fn achievement ->
        user_achievement =
          Enum.find(user_achievements, fn ua ->
            ua.achievement_id == achievement.id
          end)

        %{
          achievement: achievement,
          user_achievement: user_achievement,
          completed: user_achievement && user_achievement.completed_at,
          progress_value: if(user_achievement, do: user_achievement.progress_value, else: 0)
        }
      end)
      |> Enum.filter(fn item ->
        if socket.assigns.show_completed_only do
          item.completed
        else
          true
        end
      end)

    assign(socket, :achievements_with_progress, achievements_with_progress)
  end

  defp load_statistics(socket) do
    stats = Achievements.get_achievement_statistics(socket.assigns.user_id)
    assign(socket, :statistics, stats)
  end

  defp progress_percentage(progress_value, threshold_value) do
    if threshold_value && threshold_value > 0 do
      min(round(progress_value / threshold_value * 100), 100)
    else
      if progress_value > 0, do: 100, else: 0
    end
  end

  defp achievement_categories do
    [
      {"all", "All Achievements"},
      {"tasks", "Task Management"},
      {"habits", "Habit Tracking"},
      {"meetings", "Meeting Survival"},
      {"emails", "Email Archaeology"},
      {"connections", "Digital Integration"},
      {"productivity_theater", "Productivity Theater"}
    ]
  end
end
