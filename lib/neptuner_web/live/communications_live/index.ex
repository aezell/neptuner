defmodule NeptunerWeb.CommunicationsLive.Index do
  use NeptunerWeb, :live_view

  alias Neptuner.Communications
  alias Neptuner.Connections

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "Email Intelligence Dashboard")
      |> assign(:user_id, user_id)
      |> assign(:filter_classification, "all")
      |> assign(:show_insights, false)
      |> assign(:sync_status, nil)
      |> load_emails()
      |> load_statistics()
      |> load_insights()
      |> check_email_connections()

    {:ok, socket}
  end

  def handle_event("filter_classification", %{"classification" => classification}, socket) do
    socket =
      socket
      |> assign(:filter_classification, classification)
      |> load_emails()

    {:noreply, socket}
  end

  def handle_event("toggle_insights", _params, socket) do
    {:noreply, assign(socket, :show_insights, !socket.assigns.show_insights)}
  end

  def handle_event("sync_emails", _params, socket) do
    case Communications.sync_emails_from_connections(socket.assigns.user_id) do
      {:ok, message} ->
        socket =
          socket
          |> put_flash(:info, message)
          |> assign(:sync_status, :success)
          |> load_emails()
          |> load_statistics()
          |> load_insights()

        {:noreply, socket}

      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to sync emails: #{reason}")
          |> assign(:sync_status, :error)

        {:noreply, socket}
    end
  end

  def handle_event("mark_read", %{"id" => id}, socket) do
    email = Communications.get_user_email_summary!(socket.assigns.user_id, id)

    case Communications.update_email_summary(email, %{is_read: true}) do
      {:ok, _email} ->
        socket =
          socket
          |> put_flash(:info, "Email marked as read")
          |> load_emails()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to mark email as read")}
    end
  end

  def handle_event("delete_email", %{"id" => id}, socket) do
    email = Communications.get_user_email_summary!(socket.assigns.user_id, id)

    case Communications.delete_email_summary(email) do
      {:ok, _email} ->
        socket =
          socket
          |> put_flash(:info, "Email deleted from analysis")
          |> load_emails()
          |> load_statistics()
          |> load_insights()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete email")}
    end
  end

  defp load_emails(socket) do
    classification =
      if socket.assigns.filter_classification == "all",
        do: nil,
        else: socket.assigns.filter_classification

    emails =
      Communications.list_email_summaries(socket.assigns.user_id,
        classification: classification,
        limit: 50
      )

    assign(socket, :emails, emails)
  end

  defp load_statistics(socket) do
    stats = Communications.get_communication_statistics(socket.assigns.user_id)
    assign(socket, :statistics, stats)
  end

  defp load_insights(socket) do
    insights = Communications.get_email_pattern_insights(socket.assigns.user_id)
    assign(socket, :insights, insights)
  end

  defp check_email_connections(socket) do
    email_connections = Connections.get_email_connections(socket.assigns.user_id)
    assign(socket, :email_connections, email_connections)
  end

  defp classification_badge_class(:urgent_important), do: "badge-error"
  defp classification_badge_class(:urgent_unimportant), do: "badge-warning"
  defp classification_badge_class(:not_urgent_important), do: "badge-info"
  defp classification_badge_class(:digital_noise), do: "badge-ghost"

  defp time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :hour)

    cond do
      diff < 1 -> "Less than an hour ago"
      diff < 24 -> "#{diff} hours ago"
      diff < 168 -> "#{div(diff, 24)} days ago"
      true -> "#{div(diff, 168)} weeks ago"
    end
  end

  defp productivity_score_color(score) when score >= 8, do: "text-success"
  defp productivity_score_color(score) when score >= 6, do: "text-info"
  defp productivity_score_color(score) when score >= 4, do: "text-warning"
  defp productivity_score_color(_score), do: "text-error"
end
