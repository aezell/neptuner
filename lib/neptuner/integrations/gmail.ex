defmodule Neptuner.Integrations.Gmail do
  @moduledoc """
  Gmail API integration for analyzing real email patterns and productivity insights.
  Transforms email data into cosmic communication intelligence.
  """

  require Logger
  alias Neptuner.{Communications, Connections}
  alias Neptuner.Connections.ServiceConnection

  @gmail_api_base "https://gmail.googleapis.com/gmail/v1"

  @doc """
  Syncs email summaries from Gmail for a specific connection.
  Returns {:ok, count} on success or {:error, reason} on failure.
  """
  def sync_email_summaries(%ServiceConnection{} = connection) do
    with {:ok, access_token} <- ensure_valid_token(connection),
         {:ok, emails} <- fetch_recent_emails(access_token),
         {:ok, count} <- import_email_summaries(connection, emails) do
      # Update last sync timestamp
      Connections.update_service_connection(connection, %{
        last_sync_at: DateTime.utc_now(),
        connection_status: :active
      })

      {:ok, count}
    else
      {:error, reason} ->
        Logger.error("Gmail sync failed for connection #{connection.id}: #{inspect(reason)}")

        Connections.update_service_connection(connection, %{
          connection_status: :error
        })

        {:error, reason}
    end
  end

  @doc """
  Fetches email statistics for productivity analysis.
  """
  def get_email_statistics(%ServiceConnection{} = connection, days_back \\ 7) do
    with {:ok, access_token} <- ensure_valid_token(connection) do
      query = build_date_query(days_back)

      # Get counts for different types of emails
      sent_count = count_emails(access_token, "in:sent #{query}")
      received_count = count_emails(access_token, "in:inbox #{query}")
      unread_count = count_emails(access_token, "is:unread #{query}")

      {:ok,
       %{
         sent_emails: sent_count,
         received_emails: received_count,
         unread_emails: unread_count,
         email_velocity: calculate_email_velocity(sent_count, received_count, days_back),
         cosmic_communication_rating:
           rate_cosmic_communication(sent_count, received_count, unread_count)
       }}
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

  defp fetch_recent_emails(access_token, days_back \\ 7) do
    query = build_date_query(days_back)

    # Fetch both sent and received emails for comprehensive analysis
    with {:ok, sent_emails} <- get_email_list(access_token, "in:sent #{query}"),
         {:ok, received_emails} <- get_email_list(access_token, "in:inbox #{query}") do
      all_emails =
        (sent_emails ++ received_emails)
        |> Enum.uniq_by(& &1["id"])
        # Limit to most recent 100 for processing efficiency
        |> Enum.take(100)

      # Get detailed information for each email
      detailed_emails =
        all_emails
        |> Enum.map(fn email -> get_email_details(access_token, email["id"]) end)
        |> Enum.filter(fn
          {:ok, _} -> true
          _ -> false
        end)
        |> Enum.map(fn {:ok, email} -> email end)

      {:ok, detailed_emails}
    end
  end

  defp get_email_list(access_token, query) do
    url = "#{@gmail_api_base}/users/me/messages"
    headers = [{"Authorization", "Bearer #{access_token}"}]
    params = %{q: query, maxResults: 50}

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: response}} ->
        messages = response["messages"] || []
        {:ok, messages}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Gmail messages fetch failed: #{status} - #{inspect(body)}")
        {:error, "Failed to fetch messages"}

      {:error, reason} ->
        Logger.error("Gmail API request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp get_email_details(access_token, message_id) do
    url = "#{@gmail_api_base}/users/me/messages/#{message_id}"
    headers = [{"Authorization", "Bearer #{access_token}"}]
    params = %{format: "metadata", metadataHeaders: ["Subject", "From", "To", "Cc", "Date"]}

    case Req.get(url, headers: headers, params: params) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, response}

      {:ok, %{status: status, body: body}} ->
        Logger.error(
          "Gmail message details fetch failed for #{message_id}: #{status} - #{inspect(body)}"
        )

        {:error, "Failed to fetch message details"}

      {:error, reason} ->
        Logger.error("Gmail message details API request failed: #{inspect(reason)}")
        {:error, "Network error"}
    end
  end

  defp count_emails(access_token, query) do
    case get_email_list(access_token, query) do
      {:ok, messages} -> length(messages)
      {:error, _} -> 0
    end
  end

  defp import_email_summaries(connection, emails) do
    imported_count =
      emails
      |> Enum.map(fn email -> {transform_to_email_summary(connection, email), email} end)
      |> Enum.filter(fn {email_attrs, _email} -> email_attrs != nil end)
      |> Enum.reduce(0, fn {email_attrs, email}, acc ->
        case Communications.upsert_email_summary_by_external_id(
               connection.user_id,
               email_attrs[:external_id],
               email_attrs
             ) do
          {:ok, _email_summary} ->
            acc + 1

          {:error, reason} ->
            Logger.warning("Failed to import email #{email["id"]}: #{inspect(reason)}")
            acc
        end
      end)

    {:ok, imported_count}
  end

  defp transform_to_email_summary(connection, email) do
    headers = extract_headers(email)
    subject = get_header_value(headers, "Subject") || "No Subject"
    from_email = parse_email_address(get_header_value(headers, "From"))
    to_emails = parse_email_addresses(get_header_value(headers, "To"))
    cc_emails = parse_email_addresses(get_header_value(headers, "Cc"))

    received_at = parse_gmail_date(get_header_value(headers, "Date"))

    if received_at == nil do
      nil
    else
      # Determine if this is sent or received
      user_email = connection.external_account_email
      is_sent = from_email == user_email

      # Apply cosmic email analysis
      classification = classify_email_cosmically(subject, from_email, to_emails, is_sent)

      importance_score =
        calculate_cosmic_importance(subject, from_email, to_emails, cc_emails, is_sent)

      thread_position = determine_thread_position(email)
      word_count = estimate_word_count(email)

      # Advanced email analysis
      email_data = %{
        subject: subject,
        # Gmail metadata doesn't include body
        body_preview: "",
        from_email: from_email,
        from_domain: extract_domain(from_email),
        classification: classification,
        importance_score: importance_score,
        word_count: word_count,
        has_attachments: has_attachments?(email)
      }

      advanced_analysis =
        Neptuner.Integrations.AdvancedEmailAnalysis.analyze_email_advanced(email_data)

      %{
        external_id: email_to_external_id(email),
        subject: subject,
        from_email: from_email,
        to_emails: to_emails,
        cc_emails: cc_emails,
        received_at: received_at,
        classification: classification,
        importance_score: importance_score,
        thread_position: thread_position,
        is_sent: is_sent,
        word_count: word_count,
        has_attachments: has_attachments?(email),
        labels: extract_labels(email),
        external_thread_id: email["threadId"],
        synced_at: DateTime.utc_now(),
        # Advanced analysis fields
        sentiment_analysis: advanced_analysis.sentiment,
        email_intent: advanced_analysis.intent,
        urgency_analysis: advanced_analysis.urgency,
        meeting_potential: advanced_analysis.meeting_potential,
        action_items: advanced_analysis.action_items,
        productivity_impact: advanced_analysis.productivity_impact,
        cosmic_insights: advanced_analysis.cosmic_insights
      }
    end
  end

  defp extract_headers(email) do
    get_in(email, ["payload", "headers"]) || []
  end

  defp get_header_value(headers, name) do
    Enum.find_value(headers, fn header ->
      if header["name"] == name, do: header["value"]
    end)
  end

  defp parse_email_address(nil), do: nil

  defp parse_email_address(email_string) do
    # Extract email from "Name <email@domain.com>" format
    case Regex.run(~r/<([^>]+)>/, email_string) do
      [_, email] ->
        email

      nil ->
        # Try to extract just the email if no angle brackets
        case Regex.run(~r/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/, email_string) do
          [_, email] -> email
          nil -> email_string
        end
    end
  end

  defp parse_email_addresses(nil), do: []

  defp parse_email_addresses(email_string) do
    email_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&parse_email_address/1)
    |> Enum.filter(&(&1 != nil))
  end

  defp parse_gmail_date(nil), do: nil

  defp parse_gmail_date(date_string) do
    # Gmail dates come in RFC 2822 format
    case Timex.parse(date_string, "{RFC1123}") do
      {:ok, datetime} ->
        datetime

      {:error, _} ->
        # Try other common formats
        case Timex.parse(date_string, "{RFC822}") do
          {:ok, datetime} -> datetime
          {:error, _} -> nil
        end
    end
  end

  defp classify_email_cosmically(subject, _from_email, to_emails, is_sent) do
    subject_lower = String.downcase(subject)
    recipient_count = length(to_emails)

    cond do
      # Cosmic classifications based on existential email analysis
      String.contains?(subject_lower, ["re:", "fwd:", "fw:"]) ->
        :thread_continuation

      String.contains?(subject_lower, ["meeting", "calendar", "invite", "appointment"]) ->
        :meeting_coordination

      String.contains?(subject_lower, ["urgent", "asap", "immediate", "emergency"]) ->
        # The irony of digital urgency in cosmic time
        :urgent_void

      String.contains?(subject_lower, ["fyi", "heads up", "notification", "alert"]) ->
        :information_broadcast

      String.contains?(subject_lower, ["thank", "thanks", "appreciate", "great job"]) ->
        :social_lubrication

      String.contains?(subject_lower, ["question", "help", "support", "issue", "problem"]) ->
        :help_seeking

      String.contains?(subject_lower, ["update", "status", "report", "summary"]) ->
        :status_ritual

      recipient_count > 10 ->
        :mass_communication

      recipient_count > 3 ->
        :group_coordination

      is_sent and recipient_count == 1 ->
        :direct_exchange

      String.contains?(subject_lower, ["newsletter", "digest", "announcement"]) ->
        :information_consumption

      true ->
        # The default state of most digital communication
        :existential_mystery
    end
  end

  defp calculate_cosmic_importance(subject, from_email, to_emails, cc_emails, _is_sent) do
    base_score = 50

    # Domain-based importance (cosmic hierarchy recognition)
    domain_bonus =
      case extract_domain(from_email) do
        domain when domain in ["gmail.com", "yahoo.com", "hotmail.com"] -> 0
        _corporate_domain -> 10
      end

    # Subject line cosmic analysis
    subject_lower = String.downcase(subject)

    subject_score =
      cond do
        String.contains?(subject_lower, ["urgent", "important", "critical"]) -> 20
        String.contains?(subject_lower, ["meeting", "decision", "approval"]) -> 15
        String.contains?(subject_lower, ["fyi", "update", "status"]) -> -10
        String.contains?(subject_lower, ["newsletter", "digest", "notification"]) -> -20
        # Verbose subjects often lack focus
        String.length(subject) > 100 -> -5
        true -> 0
      end

    # Recipient dynamics (cosmic social theory)
    recipient_score =
      cond do
        # Direct communication
        length(to_emails) == 1 and length(cc_emails) == 0 -> 15
        # Small group
        length(to_emails) <= 3 -> 10
        # Medium group
        length(to_emails) <= 10 -> 0
        # Mass communication dilutes importance
        true -> -15
      end

    # Existential bonus for meaningful communication
    meaning_bonus =
      if String.contains?(subject_lower, ["vision", "purpose", "strategy", "future", "growth"]) do
        25
      else
        0
      end

    total_score = base_score + domain_bonus + subject_score + recipient_score + meaning_bonus
    max(0, min(100, total_score))
  end

  defp determine_thread_position(email) do
    # Analyze thread position based on subject and references
    subject = get_header_value(extract_headers(email), "Subject") || ""

    cond do
      String.starts_with?(subject, "Re:") -> :reply
      String.starts_with?(subject, ["Fwd:", "Fw:"]) -> :forward
      # Could analyze References header for more sophisticated thread detection
      true -> :initial
    end
  end

  defp estimate_word_count(email) do
    # Gmail API doesn't provide body in metadata format, so we estimate
    # based on available data or could make additional API call for full content
    subject_words =
      get_header_value(extract_headers(email), "Subject")
      |> case do
        nil -> 0
        subject -> length(String.split(subject))
      end

    # Rough estimation - actual implementation might fetch full content
    subject_words * 10 + :rand.uniform(200)
  end

  defp has_attachments?(email) do
    # Check if email has attachments based on payload structure
    parts = get_in(email, ["payload", "parts"]) || []

    Enum.any?(parts, fn part ->
      filename = get_in(part, ["filename"])
      filename != nil and filename != ""
    end)
  end

  defp extract_labels(email) do
    email["labelIds"] || []
  end

  defp extract_domain(email) when is_binary(email) do
    case String.split(email, "@") do
      [_, domain] -> domain
      _ -> "unknown"
    end
  end

  defp extract_domain(_), do: "unknown"

  defp email_to_external_id(email) do
    "gmail_#{email["id"]}"
  end

  defp build_date_query(days_back) do
    date = Date.utc_today() |> Date.add(-days_back)
    "after:#{Date.to_string(date)}"
  end

  defp calculate_email_velocity(sent_count, received_count, days) do
    total_emails = sent_count + received_count
    velocity = total_emails / days

    cond do
      # Approaching the speed of digital light
      velocity > 50 -> :hyperspace
      velocity > 20 -> :warp_speed
      velocity > 10 -> :cruising
      velocity > 5 -> :orbital
      velocity > 1 -> :atmospheric
      true -> :terrestrial
    end
  end

  defp rate_cosmic_communication(sent, received, unread) do
    # Cosmic email wellness rating
    total_active = sent + received
    unread_ratio = if total_active > 0, do: unread / total_active, else: 0
    response_balance = if received > 0, do: sent / received, else: 1

    base_rating = 50

    # Unread burden (the cosmic weight of digital neglect)
    unread_penalty = round(unread_ratio * 30)

    # Response balance (the yin-yang of digital communication)
    balance_adjustment =
      cond do
        # Sending too much
        response_balance > 2 -> -15
        # Not responding enough
        response_balance < 0.5 -> -10
        # Cosmic balance
        response_balance >= 0.8 and response_balance <= 1.2 -> 15
        true -> 0
      end

    # Volume wisdom (avoiding the black hole of email overload)
    volume_adjustment =
      cond do
        # Approaching email event horizon
        total_active > 100 -> -20
        # Heavy email gravity
        total_active > 50 -> -10
        # Blissful digital minimalism
        total_active < 10 -> 10
        true -> 0
      end

    final_rating = base_rating - unread_penalty + balance_adjustment + volume_adjustment
    max(0, min(100, final_rating))
  end
end
