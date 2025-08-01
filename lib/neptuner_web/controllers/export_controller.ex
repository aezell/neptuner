defmodule NeptunerWeb.ExportController do
  @moduledoc """
  Controller for premium data export functionality.
  Provides cosmic productivity insights in various formats.
  """

  use NeptunerWeb, :controller
  alias Neptuner.DataExport
  require Logger

  @doc """
  Export all user data in the requested format.
  Premium feature - requires cosmic_enlightenment or enterprise tier.
  """
  def export_all(conn, params) do
    user_id = conn.assigns.current_scope.user.id
    format = String.to_atom(params["format"] || "json")

    options = build_export_options(params)

    case DataExport.export_user_data(user_id, format, options) do
      {:ok, export_result} ->
        conn
        |> put_resp_content_type(export_result.content_type)
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{export_result.filename}\""
        )
        |> send_resp(200, export_result.data)

      {:error, :insufficient_cosmic_privileges} ->
        conn
        |> put_flash(
          :error,
          "Data export requires cosmic enlightenment. Upgrade to premium to unlock this universal wisdom."
        )
        |> redirect(to: ~p"/subscription")

      {:error, reason} ->
        Logger.error("Data export failed for user #{user_id}: #{inspect(reason)}")

        conn
        |> put_flash(
          :error,
          "The cosmic forces are temporarily misaligned. Export failed due to universal interference."
        )
        |> redirect(to: ~p"/dashboard")
    end
  end

  @doc """
  Export specific dataset (tasks, habits, meetings, etc.)
  """
  def export_dataset(conn, params) do
    user_id = conn.assigns.current_scope.user.id
    dataset = String.to_atom(params["dataset"])
    format = String.to_atom(params["format"] || "json")

    options = build_export_options(params)

    case DataExport.export_dataset(user_id, dataset, format, options) do
      {:ok, export_result} ->
        conn
        |> put_resp_content_type(export_result.content_type)
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=\"#{export_result.filename}\""
        )
        |> send_resp(200, export_result.data)

      {:error, :insufficient_cosmic_privileges} ->
        conn
        |> put_flash(
          :error,
          "Dataset export requires cosmic enlightenment. Upgrade to premium to access this data dimension."
        )
        |> redirect(to: ~p"/subscription")

      {:error, :unknown_dataset} ->
        conn
        |> put_flash(
          :error,
          "Unknown dataset requested. The cosmic database doesn't recognize that dimension."
        )
        |> redirect(to: ~p"/dashboard")

      {:error, reason} ->
        Logger.error(
          "Dataset export failed for user #{user_id}, dataset #{dataset}: #{inspect(reason)}"
        )

        conn
        |> put_flash(
          :error,
          "Export failed due to cosmic interference. Please try again when the stars are better aligned."
        )
        |> redirect(to: ~p"/dashboard")
    end
  end

  @doc """
  Show export options page for premium users.
  """
  def export_options(conn, _params) do
    user_id = conn.assigns.current_scope.user.id

    # Check if user has premium access
    case check_premium_access(user_id) do
      true ->
        render(conn, :export_options, %{
          available_datasets: get_available_datasets(),
          available_formats: get_available_formats(),
          export_examples: get_export_examples()
        })

      false ->
        conn
        |> put_flash(
          :info,
          "Data export is a premium cosmic feature. Unlock universal data access with subscription upgrade."
        )
        |> redirect(to: ~p"/subscription")
    end
  end

  # Private functions

  defp build_export_options(params) do
    options = %{}

    # Add date range if provided
    options =
      if params["start_date"] do
        case Date.from_iso8601(params["start_date"]) do
          {:ok, date} -> Map.put(options, :start_date, date)
          _ -> options
        end
      else
        options
      end

    options =
      if params["end_date"] do
        case Date.from_iso8601(params["end_date"]) do
          {:ok, date} -> Map.put(options, :end_date, date)
          _ -> options
        end
      else
        options
      end

    options
  end

  defp check_premium_access(user_id) do
    case Neptuner.Subscriptions.get_user_subscription_tier(user_id) do
      {:ok, tier} when tier in [:cosmic_enlightenment, :enterprise] -> true
      _ -> false
    end
  end

  defp get_available_datasets do
    [
      %{
        key: :tasks,
        name: "Cosmic Tasks",
        description: "All your tasks with cosmic priority analysis and reality check scores"
      },
      %{
        key: :habits,
        name: "Existential Habits",
        description: "Habit tracking data with philosophical category insights"
      },
      %{
        key: :meetings,
        name: "Meeting Analysis",
        description: "Calendar events with productivity scores and email potential assessments"
      },
      %{
        key: :communications,
        name: "Digital Communications",
        description: "Email summaries with cosmic classification and importance ratings"
      },
      %{
        key: :achievements,
        name: "Achievement Universe",
        description: "Unlocked achievements with cosmic significance ratings"
      },
      %{
        key: :analytics,
        name: "Cosmic Insights",
        description: "Advanced productivity analytics and existential observations"
      }
    ]
  end

  defp get_available_formats do
    [
      %{
        key: :json,
        name: "JSON",
        description: "Structured data format perfect for analysis and integration",
        recommended: true
      },
      %{
        key: :csv,
        name: "CSV",
        description: "Spreadsheet-compatible format for data analysis",
        recommended: false
      },
      %{
        key: :excel,
        name: "Excel",
        description: "Microsoft Excel format (coming soon to this cosmic dimension)",
        available: false
      }
    ]
  end

  defp get_export_examples do
    %{
      tasks_json: """
      {
        "export_metadata": {
          "dataset": "tasks",
          "generated_at": "2024-01-15T10:30:00Z"
        },
        "tasks": [
          {
            "id": 123,
            "title": "Contemplate the meaning of productivity",
            "priority": "cosmic",
            "reality_check_score": 85,
            "existential_weight": "high"
          }
        ]
      }
      """,
      analytics_insight: """
      Your cosmic insights will include:
      • Productivity balance across cosmic scales
      • Time allocation between meetings and deep work
      • Digital wellness metrics from email analysis
      • Existential observations about your patterns
      • Philosophical recommendations for evolution
      """
    }
  end
end
