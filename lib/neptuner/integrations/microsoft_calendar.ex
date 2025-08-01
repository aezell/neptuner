defmodule Neptuner.Integrations.MicrosoftCalendar do
  @moduledoc """
  Microsoft Graph Calendar API integration for syncing Office 365 calendar events.
  Transforms calendar events into Neptuner's cosmic productivity insights.
  """

  require Logger
  alias Neptuner.{Calendar, Connections}
  alias Neptuner.Connections.ServiceConnection

  @microsoft_graph_api_base "https://graph.microsoft.com/v1.0"

  @doc """
  Syncs calendar events from Microsoft Graph for a specific connection.
  Returns {:ok, count} on success or {:error, reason} on failure.
  """
  def sync_calendar_events(%ServiceConnection{} = connection) do
    with {:ok, access_token} <- ensure_valid_token(connection),
         {:ok, calendar_list} <- get_calendar_list(access_token),
         {:ok, events} <- fetch_all_events(access_token, calendar_list),
         {:ok, count} <- import_events(connection, events) do
      # Update last sync timestamp
      Connections.update_service_connection(connection, %{
        last_sync_at: DateTime.utc_now(),
        connection_status: :active
      })

      {:ok, count}
    else
      {:error, reason} ->
        Logger.error(
          "Microsoft Calendar sync failed for connection #{connection.id}: #{inspect(reason)}"
        )

        Connections.update_service_connection(connection, %{
          connection_status: :error
        })

        {:error, reason}
    end
  end

  @doc """
  Fetches calendar events for a date range (used for one-time sync or refresh).
  """
  def fetch_events_for_range(%ServiceConnection{} = connection, start_date, end_date) do
    with {:ok, access_token} <- ensure_valid_token(connection),
         {:ok, calendar_list} <- get_calendar_list(access_token) do
      time_min = DateTime.to_iso8601(start_date)
      time_max = DateTime.to_iso8601(end_date)

      events =
        calendar_list
        |> Enum.flat_map(fn calendar ->
          case get_calendar_events(access_token, calendar["id"], time_min, time_max) do
            {:ok, events} -> events
            {:error, _} -> []
          end
        end)
        |> Enum.filter(&valid_event?/1)
        |> Enum.sort_by(&(&1["start"]["dateTime"] || &1["start"]["date"]))

      {:ok, events}
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

  defp get_calendar_list(access_token) do
    url = "#{@microsoft_graph_api_base}/me/calendars"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: response}} ->
        calendars = response["value"] || []
        # Include primary and important calendars
        relevant_calendars =
          Enum.filter(calendars, fn cal ->
            cal["isDefaultCalendar"] == true or cal["canEdit"] == true
          end)

        {:ok, relevant_calendars}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Microsoft Calendar list fetch failed: #{status} - #{inspect(body)}")
        {:error, "Failed to fetch calendar list"}

      {:error, reason} ->
        Logger.error("Microsoft Graph API request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp fetch_all_events(access_token, calendar_list) do
    # Fetch events from the last 30 days and next 90 days for comprehensive sync
    time_min = DateTime.utc_now() |> DateTime.add(-30, :day) |> DateTime.to_iso8601()
    time_max = DateTime.utc_now() |> DateTime.add(90, :day) |> DateTime.to_iso8601()

    all_events =
      calendar_list
      |> Enum.flat_map(fn calendar ->
        case get_calendar_events(access_token, calendar["id"], time_min, time_max) do
          {:ok, events} ->
            # Add calendar info to each event
            Enum.map(events, fn event ->
              Map.put(event, "_calendar", calendar)
            end)

          {:error, _} ->
            []
        end
      end)
      |> Enum.filter(&valid_event?/1)
      |> Enum.uniq_by(& &1["id"])

    {:ok, all_events}
  end

  defp get_calendar_events(access_token, calendar_id, time_min, time_max) do
    url = "#{@microsoft_graph_api_base}/me/calendars/#{calendar_id}/events"
    headers = [{"Authorization", "Bearer #{access_token}"}]

    params = %{
      startDateTime: time_min,
      endDateTime: time_max,
      orderBy: "start/dateTime",
      top: 250
    }

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: response}} ->
        events = response["value"] || []
        {:ok, events}

      {:ok, %{status: status, body: body}} ->
        Logger.error(
          "Microsoft Calendar events fetch failed for #{calendar_id}: #{status} - #{inspect(body)}"
        )

        {:error, "Failed to fetch events"}

      {:error, reason} ->
        Logger.error("Microsoft Calendar events API request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp valid_event?(event) do
    # Filter out cancelled events and events without proper time info
    event["isCancelled"] != true and
      (event["start"]["dateTime"] != nil or event["start"]["date"] != nil)
  end

  defp import_events(connection, events) do
    imported_count =
      events
      |> Enum.map(fn event -> {transform_to_meeting(connection, event), event} end)
      |> Enum.filter(fn {meeting_attrs, _event} -> meeting_attrs != nil end)
      |> Enum.reduce(0, fn {meeting_attrs, event}, acc ->
        case Calendar.upsert_meeting_by_external_id(
               connection.user_id,
               connection.id,
               meeting_attrs[:external_id],
               meeting_attrs
             ) do
          {:ok, _meeting} ->
            acc + 1

          {:error, reason} ->
            Logger.warning("Failed to import event #{event["id"]}: #{inspect(reason)}")
            acc
        end
      end)

    {:ok, imported_count}
  end

  defp transform_to_meeting(_connection, event) do
    start_time = parse_event_time(event["start"])
    end_time = parse_event_time(event["end"])

    if start_time == nil do
      nil
    else
      duration_minutes =
        if end_time do
          DateTime.diff(end_time, start_time, :minute)
        else
          # Default to 1 hour for all-day events
          60
        end

      # Apply cosmic productivity analysis
      meeting_type = determine_cosmic_meeting_type(event)
      productivity_score = calculate_cosmic_productivity_score(event, duration_minutes)
      could_be_email = assess_email_potential(event)

      %{
        external_id: event_to_external_id(event),
        title: event["subject"] || "Untitled Cosmic Gathering",
        description: event["bodyPreview"] || event["body"]["content"],
        scheduled_at: start_time,
        duration_minutes: duration_minutes,
        meeting_type: meeting_type,
        attendee_count: count_attendees(event),
        productivity_score: productivity_score,
        could_have_been_email: could_be_email,
        location: get_event_location(event),
        meeting_link: extract_meeting_link(event),
        calendar_name: get_calendar_name(event),
        recurring: event["recurrence"] != nil,
        external_created_at: parse_iso8601(event["createdDateTime"]),
        external_updated_at: parse_iso8601(event["lastModifiedDateTime"]),
        synced_at: DateTime.utc_now()
      }
    end
  end

  defp parse_event_time(%{"dateTime" => date_time}) when is_binary(date_time) do
    case DateTime.from_iso8601(date_time) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_event_time(%{"date" => date}) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> DateTime.new!(d, ~T[09:00:00], "Etc/UTC")
      _ -> nil
    end
  end

  defp parse_event_time(_), do: nil

  defp determine_cosmic_meeting_type(event) do
    title = String.downcase(event["subject"] || "")
    attendees = event["attendees"] || []

    cond do
      String.contains?(title, ["1:1", "one-on-one", "check in", "sync"]) ->
        :one_on_one

      String.contains?(title, ["standup", "daily", "scrum", "retrospective"]) ->
        :standup

      String.contains?(title, ["all hands", "town hall", "company", "team meeting"]) ->
        :all_hands

      String.contains?(title, ["interview", "screening", "candidate"]) ->
        :interview

      String.contains?(title, ["demo", "presentation", "review", "showcase"]) ->
        :presentation

      String.contains?(title, ["workshop", "training", "learning", "session"]) ->
        :workshop

      length(attendees) >= 8 ->
        :large_group

      length(attendees) >= 3 ->
        :small_group

      true ->
        :other
    end
  end

  defp calculate_cosmic_productivity_score(event, duration_minutes) do
    title = String.downcase(event["subject"] || "")
    attendees = event["attendees"] || []
    has_agenda = String.length(event["bodyPreview"] || "") > 50

    base_score = 50

    # Duration-based adjustments (cosmic time theory)
    duration_adjustment =
      cond do
        # Quick syncs are efficient
        duration_minutes <= 15 -> 20
        # Sweet spot
        duration_minutes <= 30 -> 15
        # Standard but okay
        duration_minutes <= 60 -> 0
        # Getting long
        duration_minutes <= 90 -> -10
        # Approaching the event horizon of productivity
        true -> -20
      end

    # Attendee-based adjustments (cosmic social dynamics)
    attendee_adjustment =
      cond do
        # Intimate cosmic alignment
        length(attendees) <= 2 -> 15
        # Small galaxy formation
        length(attendees) <= 4 -> 10
        # Moderate stellar cluster
        length(attendees) <= 8 -> 0
        # Approaching black hole of productivity
        true -> -15
      end

    # Content-based adjustments
    content_adjustment =
      cond do
        has_agenda -> 10
        String.contains?(title, ["brainstorm", "ideation", "creative"]) -> 5
        String.contains?(title, ["status", "update", "report"]) -> -5
        String.contains?(title, ["meeting about meeting", "sync about sync"]) -> -20
        true -> 0
      end

    # Existential reality check
    existential_bonus =
      if String.contains?(title, ["purpose", "meaning", "why", "vision"]) do
        # Meetings about the meaning of work get cosmic bonus points
        25
      else
        0
      end

    total_score =
      base_score + duration_adjustment + attendee_adjustment + content_adjustment +
        existential_bonus

    max(0, min(100, total_score))
  end

  defp assess_email_potential(event) do
    title = String.downcase(event["subject"] || "")
    attendees = event["attendees"] || []
    duration = parse_duration_from_event(event)

    # Cosmic email assessment algorithm
    email_score = 0

    email_score = email_score + if length(attendees) <= 3, do: 20, else: 0
    email_score = email_score + if duration <= 30, do: 25, else: 0

    email_score =
      email_score +
        if String.contains?(title, ["update", "status", "report", "quick", "brief"]),
          do: 30,
          else: 0

    email_score =
      email_score +
        if String.contains?(title, ["fyi", "heads up", "notification"]), do: 40, else: 0

    # Meetings that definitely need to be meetings get negative email score
    email_score =
      email_score -
        if String.contains?(title, ["brainstorm", "workshop", "planning", "creative"]),
          do: 30,
          else: 0

    email_score =
      email_score -
        if String.contains?(title, ["decision", "discuss", "debate", "alignment"]),
          do: 20,
          else: 0

    email_score >= 50
  end

  defp count_attendees(event) do
    (event["attendees"] || [])
    |> Enum.count(fn attendee ->
      attendee["status"]["response"] != "declined"
    end)
  end

  defp extract_meeting_link(event) do
    body_content = get_in(event, ["body", "content"]) || ""
    location = get_event_location(event) || ""

    # Look for common video conferencing links
    patterns = [
      ~r/https:\/\/[^.\s]+\.zoom\.us\/[^\s]*/,
      ~r/https:\/\/teams\.microsoft\.com\/[^\s]*/,
      ~r/https:\/\/meet\.google\.com\/[^\s]*/,
      ~r/https:\/\/[^.\s]+\.webex\.com\/[^\s]*/
    ]

    text_to_search = "#{body_content} #{location}"

    Enum.find_value(patterns, fn pattern ->
      case Regex.run(pattern, text_to_search) do
        [link | _] -> link
        nil -> nil
      end
    end)
  end

  defp get_event_location(event) do
    cond do
      event["location"]["displayName"] -> event["location"]["displayName"]
      event["location"]["address"] -> format_address(event["location"]["address"])
      event["onlineMeeting"] -> "Microsoft Teams Meeting"
      true -> nil
    end
  end

  defp format_address(address) when is_map(address) do
    parts =
      [
        address["street"],
        address["city"],
        address["state"],
        address["postalCode"]
      ]
      |> Enum.filter(&(&1 != nil and &1 != ""))

    if length(parts) > 0 do
      Enum.join(parts, ", ")
    else
      nil
    end
  end

  defp get_calendar_name(event) do
    case event["_calendar"] do
      %{"name" => name} -> name
      _ -> "Primary Calendar"
    end
  end

  defp event_to_external_id(event) do
    "microsoft_calendar_#{event["id"]}"
  end

  defp parse_duration_from_event(event) do
    start_time = parse_event_time(event["start"])
    end_time = parse_event_time(event["end"])

    if start_time && end_time do
      DateTime.diff(end_time, start_time, :minute)
    else
      # Default assumption
      60
    end
  end

  defp parse_iso8601(nil), do: nil

  defp parse_iso8601(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end
