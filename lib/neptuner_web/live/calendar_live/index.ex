defmodule NeptunerWeb.CalendarLive.Index do
  use NeptunerWeb, :live_view

  alias Neptuner.Calendar
  alias Neptuner.Calendar.Meeting
  alias Neptuner.Connections

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "Existential Meeting Analysis")
      |> assign(:user_id, user_id)
      |> assign(:filter_type, "all")
      |> assign(:view_mode, "dashboard")
      |> assign(:show_weekly_report, false)
      |> assign(:rating_meeting, nil)
      |> load_meetings()
      |> load_statistics()
      |> load_weekly_report()
      |> load_connections()
      |> load_unrated_meetings()

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    socket =
      socket
      |> assign(:filter_type, type)
      |> load_meetings()

    {:noreply, socket}
  end

  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  def handle_event("toggle_weekly_report", _params, socket) do
    {:noreply, assign(socket, :show_weekly_report, !socket.assigns.show_weekly_report)}
  end

  def handle_event("mark_could_have_been_email", %{"id" => id, "value" => value}, socket) do
    meeting = Calendar.get_user_meeting!(socket.assigns.user_id, id)
    could_have_been = value == "true"

    case Calendar.mark_as_could_have_been_email(meeting, could_have_been) do
      {:ok, _meeting} ->
        message =
          if could_have_been do
            "Meeting marked as email-worthy. Another victory for asynchronous communication."
          else
            "Meeting deemed actually necessary. Rare but cosmic."
          end

        socket =
          socket
          |> put_flash(:info, message)
          |> load_meetings()
          |> load_statistics()
          |> load_weekly_report()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to update meeting")}
    end
  end

  def handle_event("start_rating", %{"id" => id}, socket) do
    meeting = Calendar.get_user_meeting!(socket.assigns.user_id, id)
    {:noreply, assign(socket, :rating_meeting, meeting)}
  end

  def handle_event("cancel_rating", _params, socket) do
    {:noreply, assign(socket, :rating_meeting, nil)}
  end

  def handle_event("submit_rating", %{"score" => score}, socket) do
    score_int = String.to_integer(score)
    meeting = socket.assigns.rating_meeting

    case Calendar.rate_meeting_productivity(meeting, score_int) do
      {:ok, _meeting} ->
        socket =
          socket
          |> put_flash(:info, "Meeting rated! The universe has been informed of your experience.")
          |> assign(:rating_meeting, nil)
          |> load_meetings()
          |> load_statistics()
          |> load_unrated_meetings()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to rate meeting")}
    end
  end

  def handle_event("sync_calendar", %{"connection_id" => _connection_id}, socket) do
    # This would trigger a background sync job in a real implementation
    # For now, we'll just show a message
    socket =
      put_flash(
        socket,
        :info,
        "Calendar sync initiated. The digital overlords are being consulted."
      )

    {:noreply, socket}
  end

  def handle_event("delete_meeting", %{"id" => id}, socket) do
    meeting = Calendar.get_user_meeting!(socket.assigns.user_id, id)

    case Calendar.delete_meeting(meeting) do
      {:ok, _meeting} ->
        socket =
          socket
          |> put_flash(:info, "Meeting deleted. It never happened. Very zen.")
          |> load_meetings()
          |> load_statistics()
          |> load_weekly_report()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete meeting")}
    end
  end

  defp load_meetings(socket) do
    user_id = socket.assigns.user_id
    type_filter = socket.assigns.filter_type

    meetings =
      case type_filter do
        "all" ->
          Calendar.list_meetings(user_id)

        "unrated" ->
          unrated_meetings = Calendar.get_meetings_needing_rating(user_id)
          all_meetings = Calendar.list_meetings(user_id)

          unrated_meetings ++
            Enum.filter(all_meetings, fn m ->
              not Enum.any?(unrated_meetings, &(&1.id == m.id))
            end)

        type when type != "all" ->
          type_atom = String.to_existing_atom(type)
          Calendar.list_meetings_by_type(user_id, type_atom)
      end

    stream(socket, :meetings, meetings, reset: true)
  end

  defp load_statistics(socket) do
    stats = Calendar.get_meeting_statistics(socket.assigns.user_id)
    assign(socket, :stats, stats)
  end

  defp load_weekly_report(socket) do
    weekly_report = Calendar.get_weekly_meeting_report(socket.assigns.user_id)
    assign(socket, :weekly_report, weekly_report)
  end

  defp load_connections(socket) do
    calendar_connections =
      Connections.list_service_connections_by_type(socket.assigns.user_id, :calendar)

    assign(socket, :calendar_connections, calendar_connections)
  end

  defp load_unrated_meetings(socket) do
    unrated = Calendar.get_meetings_needing_rating(socket.assigns.user_id)
    assign(socket, :unrated_meetings, unrated)
  end

  defp type_badge_class(:standup), do: "badge-warning"
  defp type_badge_class(:all_hands), do: "badge-error"
  defp type_badge_class(:one_on_one), do: "badge-info"
  defp type_badge_class(:brainstorm), do: "badge-success"
  defp type_badge_class(:status_update), do: "badge-secondary"
  defp type_badge_class(:other), do: "badge-ghost"

  defp format_meeting_type(:standup), do: "Standup"
  defp format_meeting_type(:all_hands), do: "All Hands"
  defp format_meeting_type(:one_on_one), do: "1:1"
  defp format_meeting_type(:brainstorm), do: "Brainstorm"
  defp format_meeting_type(:status_update), do: "Status Update"
  defp format_meeting_type(:other), do: "Other"

  defp productivity_color(nil), do: "text-gray-400"
  defp productivity_color(score) when score >= 8, do: "text-green-600 font-bold"
  defp productivity_color(score) when score >= 6, do: "text-green-500"
  defp productivity_color(score) when score >= 4, do: "text-yellow-600"
  defp productivity_color(score) when score >= 2, do: "text-orange-600"
  defp productivity_color(_), do: "text-red-600"

  defp format_duration(nil), do: "Unknown"
  defp format_duration(minutes) when minutes < 60, do: "#{minutes}m"

  defp format_duration(minutes) do
    hours = div(minutes, 60)
    remaining_minutes = rem(minutes, 60)
    if remaining_minutes == 0, do: "#{hours}h", else: "#{hours}h #{remaining_minutes}m"
  end

  defp format_datetime(datetime) do
    Elixir.Calendar.strftime(datetime, "%m/%d %I:%M %p")
  end

  defp meeting_urgency_class(%{scheduled_at: scheduled_at}) do
    now = DateTime.utc_now()
    diff_hours = DateTime.diff(now, scheduled_at, :hour)

    cond do
      diff_hours < 24 -> "border-l-4 border-red-400"
      diff_hours < 72 -> "border-l-4 border-yellow-400"
      true -> "border-l-4 border-gray-200"
    end
  end

  defp get_existential_insight(%{actual_productivity_score: score, could_have_been_email: email?}) do
    cond do
      score == nil ->
        "Awaiting your cosmic evaluation of this temporal gathering."

      score <= 2 and email? ->
        "A perfect storm of futility - low productivity AND could have been email."

      score >= 8 and not email? ->
        "Rare unicorn detected: A genuinely productive in-person gathering."

      email? ->
        "Another entry in the 'Great Email vs Meeting' debate. Email is winning."

      score >= 7 ->
        "Surprisingly effective human coordination event."

      true ->
        "Standard corporate ritual - neither catastrophic nor transcendent."
    end
  end
end
