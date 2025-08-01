defmodule Neptuner.Integrations.AdvancedEmailAnalysis do
  @moduledoc """
  Advanced email analysis capabilities including sentiment analysis,
  meeting extraction, and AI-powered insights with cosmic humor.
  """

  require Logger

  @doc """
  Analyzes email content for sentiment, intent, and productivity patterns.
  """
  def analyze_email_advanced(email_data) do
    %{
      sentiment: analyze_sentiment(email_data),
      intent: classify_email_intent(email_data),
      urgency: analyze_time_sensitivity(email_data),
      meeting_potential: extract_meeting_references(email_data),
      action_items: extract_action_items(email_data),
      time_sensitivity: analyze_time_sensitivity(email_data),
      productivity_impact: calculate_productivity_impact(email_data),
      cosmic_insights: generate_cosmic_insights(email_data)
    }
  end

  @doc """
  Extracts potential meeting information from email content.
  """
  def extract_meeting_references(email_data) do
    subject = email_data[:subject] || ""
    body = email_data[:body_preview] || ""
    content = "#{subject} #{body}"

    %{
      has_meeting_keywords: detect_meeting_keywords(content),
      time_references: extract_time_references(content),
      location_references: extract_location_references(content),
      attendee_references: extract_attendee_references(content),
      calendar_attachments: detect_calendar_attachments(email_data),
      meeting_type: classify_meeting_type(content),
      confidence_score: calculate_meeting_confidence(content)
    }
  end

  @doc """
  Classifies the primary intent of the email.
  """
  def classify_email_intent(email_data) do
    subject = String.downcase(email_data[:subject] || "")
    body = String.downcase(email_data[:body_preview] || "")
    content = "#{subject} #{body}"

    cond do
      String.contains?(content, ["meeting", "call", "conference", "schedule"]) ->
        :meeting_coordination

      String.contains?(content, ["please", "need", "request", "ask", "help"]) ->
        :request_action

      String.contains?(content, ["fyi", "update", "status", "report", "information"]) ->
        :information_sharing

      String.contains?(content, ["thank", "thanks", "appreciate", "congratulations"]) ->
        :social_courtesy

      String.contains?(content, ["decision", "approve", "reject", "choose", "confirm"]) ->
        :decision_required

      String.contains?(content, ["urgent", "asap", "emergency", "immediate"]) ->
        :urgent_notification

      String.contains?(content, ["reminder", "don't forget", "follow up"]) ->
        :reminder

      String.contains?(content, ["question", "clarification", "explain", "how", "what", "why"]) ->
        :seeking_information

      true ->
        :general_communication
    end
  end

  @doc """
  Analyzes email sentiment with cosmic perspective.
  """
  def analyze_sentiment(email_data) do
    subject = String.downcase(email_data[:subject] || "")
    body = String.downcase(email_data[:body_preview] || "")
    content = "#{subject} #{body}"

    # Basic sentiment indicators
    positive_indicators = [
      "thank",
      "thanks",
      "appreciate",
      "great",
      "excellent",
      "amazing",
      "love",
      "perfect",
      "awesome",
      "fantastic",
      "wonderful",
      "brilliant",
      "congratulations",
      "success",
      "achievement",
      "well done"
    ]

    negative_indicators = [
      "problem",
      "issue",
      "error",
      "bug",
      "fail",
      "broken",
      "wrong",
      "terrible",
      "awful",
      "disaster",
      "crisis",
      "urgent",
      "critical",
      "disappointed",
      "frustrated",
      "angry",
      "unacceptable",
      "worst"
    ]

    neutral_indicators = [
      "update",
      "status",
      "report",
      "meeting",
      "schedule",
      "reminder",
      "information",
      "data",
      "analysis",
      "summary",
      "overview"
    ]

    positive_count = count_indicators(content, positive_indicators)
    negative_count = count_indicators(content, negative_indicators)
    neutral_count = count_indicators(content, neutral_indicators)

    # Calculate sentiment with cosmic wisdom
    total_indicators = positive_count + negative_count + neutral_count

    sentiment_score =
      if total_indicators > 0 do
        (positive_count - negative_count) / total_indicators
      else
        0.0
      end

    %{
      score: sentiment_score,
      classification: classify_sentiment(sentiment_score),
      confidence: calculate_sentiment_confidence(total_indicators),
      cosmic_interpretation: interpret_sentiment_cosmically(sentiment_score),
      emotional_velocity: calculate_emotional_velocity(positive_count, negative_count)
    }
  end

  @doc """
  Extracts action items and tasks from email content.
  """
  def extract_action_items(email_data) do
    subject = email_data[:subject] || ""
    body = email_data[:body_preview] || ""
    content = "#{subject} #{body}"

    action_patterns = [
      ~r/please\s+(\w+(?:\s+\w+)*)/i,
      ~r/need\s+to\s+(\w+(?:\s+\w+)*)/i,
      ~r/action\s+required:?\s*(\w+(?:\s+\w+)*)/i,
      ~r/todo:?\s*(\w+(?:\s+\w+)*)/i,
      ~r/follow\s+up\s+on\s+(\w+(?:\s+\w+)*)/i,
      ~r/remember\s+to\s+(\w+(?:\s+\w+)*)/i,
      ~r/don't\s+forget\s+to\s+(\w+(?:\s+\w+)*)/i,
      ~r/(\w+(?:\s+\w+)*)\s+by\s+\w+day/i
    ]

    extracted_actions =
      action_patterns
      |> Enum.flat_map(fn pattern ->
        Regex.scan(pattern, content, capture: :all_but_first)
        |> Enum.map(&List.first/1)
      end)
      |> Enum.filter(&(&1 != nil))
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(String.length(&1) > 3))
      |> Enum.uniq()

    %{
      action_items: extracted_actions,
      action_count: length(extracted_actions),
      has_deadlines: detect_deadlines(content),
      priority_indicators: detect_priority_indicators(content),
      cosmic_action_score: calculate_cosmic_action_score(extracted_actions)
    }
  end

  @doc """
  Analyzes time sensitivity and urgency patterns.
  """
  def analyze_time_sensitivity(email_data) do
    subject = String.downcase(email_data[:subject] || "")
    body = String.downcase(email_data[:body_preview] || "")
    content = "#{subject} #{body}"

    urgency_keywords = [
      "urgent",
      "asap",
      "immediately",
      "emergency",
      "critical",
      "rush",
      "deadline",
      "due",
      "expires",
      "time sensitive",
      "right away",
      "now",
      "today",
      "tomorrow",
      "this morning",
      "this afternoon"
    ]

    time_references = [
      ~r/\b\d{1,2}:\d{2}\s?(am|pm)\b/i,
      ~r/\b\d{1,2}\/\d{1,2}\/\d{2,4}\b/,
      ~r/\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/i,
      ~r/\b(january|february|march|april|may|june|july|august|september|october|november|december)\b/i,
      ~r/\bin\s+\d+\s+(minutes?|hours?|days?|weeks?)\b/i,
      ~r/\bby\s+(end\s+of\s+)?(today|tomorrow|this\s+week|next\s+week)\b/i
    ]

    urgency_count = count_indicators(content, urgency_keywords)

    time_matches =
      time_references |> Enum.map(&Regex.scan(&1, content)) |> List.flatten() |> length()

    urgency_score = calculate_urgency_score(urgency_count, time_matches, subject)

    %{
      urgency_score: urgency_score,
      urgency_level: classify_urgency_level(urgency_score),
      time_references_count: time_matches,
      urgency_keywords_found: urgency_count,
      cosmic_time_wisdom: interpret_urgency_cosmically(urgency_score),
      temporal_anxiety_index: calculate_temporal_anxiety(content)
    }
  end

  @doc """
  Calculates the productivity impact of processing this email.
  """
  def calculate_productivity_impact(email_data) do
    # Factors that influence productivity impact
    factors = %{
      sender_importance: assess_sender_importance(email_data),
      content_complexity: assess_content_complexity(email_data),
      action_requirements: assess_action_requirements(email_data),
      time_investment: estimate_time_investment(email_data),
      interruption_cost: calculate_interruption_cost(email_data),
      decision_requirements: assess_decision_requirements(email_data)
    }

    impact_score = calculate_weighted_impact_score(factors)

    %{
      impact_score: impact_score,
      impact_level: classify_impact_level(impact_score),
      factors: factors,
      time_cost_estimate: estimate_total_time_cost(factors),
      cognitive_load: calculate_cognitive_load(factors),
      cosmic_productivity_wisdom: generate_productivity_wisdom(impact_score)
    }
  end

  @doc """
  Generates cosmic insights and philosophical observations about the email.
  """
  def generate_cosmic_insights(email_data) do
    subject = email_data[:subject] || ""
    classification = email_data[:classification] || :existential_mystery
    importance = email_data[:importance_score] || 50

    base_insights = [
      "In the vast expanse of digital communication, this message represents #{format_cosmic_significance(importance)}.",
      "Like a photon traveling through the cosmic microwave background, this email carries information across the void of human attention.",
      "The entropy of this communication suggests #{interpret_information_entropy(subject)}.",
      "From a productivity perspective, this falls into the #{classification} category of digital existence."
    ]

    philosophical_observations = generate_philosophical_observations(email_data)
    existential_questions = generate_existential_questions(email_data)
    cosmic_ratings = calculate_cosmic_ratings(email_data)

    %{
      base_insights: base_insights,
      philosophical_observations: philosophical_observations,
      existential_questions: existential_questions,
      cosmic_ratings: cosmic_ratings,
      universal_truth: generate_universal_truth(email_data),
      productivity_dharma: generate_productivity_dharma(email_data)
    }
  end

  # Private helper functions

  defp detect_meeting_keywords(content) do
    meeting_keywords = [
      "meeting",
      "call",
      "conference",
      "discussion",
      "sync",
      "standup",
      "interview",
      "presentation",
      "demo",
      "workshop",
      "training",
      "lunch",
      "coffee",
      "chat",
      "catch up",
      "check in",
      "one-on-one"
    ]

    found_keywords =
      meeting_keywords
      |> Enum.filter(&String.contains?(String.downcase(content), &1))

    length(found_keywords) > 0
  end

  defp extract_time_references(content) do
    time_patterns = [
      ~r/\b\d{1,2}:\d{2}\s?(am|pm)\b/i,
      ~r/\bat\s+\d{1,2}(?::\d{2})?\s?(am|pm)?\b/i,
      ~r/\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/i,
      ~r/\b(today|tomorrow|next\s+week|this\s+week)\b/i
    ]

    time_patterns
    |> Enum.flat_map(&Regex.scan(&1, content))
    |> Enum.map(&List.first/1)
    |> Enum.uniq()
  end

  defp extract_location_references(content) do
    location_patterns = [
      ~r/\bat\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/,
      ~r/\bin\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/,
      ~r/\broom\s+(\d+[A-Z]?|\w+)/i,
      ~r/\bconference\s+room\s+(\w+)/i,
      ~r/\bzoom\s+link/i,
      ~r/\bteams\s+meeting/i
    ]

    location_patterns
    |> Enum.flat_map(&Regex.scan(&1, content))
    |> Enum.map(&List.first/1)
    |> Enum.uniq()
  end

  defp extract_attendee_references(content) do
    # Look for patterns that suggest other attendees
    attendee_patterns = [
      ~r/\bwith\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/,
      ~r/\band\s+([A-Z][a-z]+)\s+will\s+join/i,
      ~r/\binviting\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/i
    ]

    attendee_patterns
    |> Enum.flat_map(&Regex.scan(&1, content))
    |> Enum.map(&List.first/1)
    |> Enum.uniq()
  end

  defp detect_calendar_attachments(email_data) do
    # Check if email has calendar attachments (would need actual email data)
    email_data[:has_attachments] == true &&
      String.contains?(String.downcase(email_data[:subject] || ""), [
        "invite",
        "meeting",
        "calendar"
      ])
  end

  defp classify_meeting_type(content) do
    content_lower = String.downcase(content)

    cond do
      String.contains?(content_lower, ["1:1", "one-on-one", "check in"]) -> :one_on_one
      String.contains?(content_lower, ["standup", "daily", "scrum"]) -> :standup
      String.contains?(content_lower, ["interview", "screening"]) -> :interview
      String.contains?(content_lower, ["demo", "presentation"]) -> :presentation
      String.contains?(content_lower, ["workshop", "training"]) -> :workshop
      String.contains?(content_lower, ["lunch", "coffee"]) -> :social
      true -> :general
    end
  end

  defp calculate_meeting_confidence(content) do
    # Calculate confidence based on multiple meeting indicators
    indicators = [
      detect_meeting_keywords(content),
      length(extract_time_references(content)) > 0,
      length(extract_location_references(content)) > 0,
      String.contains?(String.downcase(content), ["calendar", "invite", "schedule"])
    ]

    true_count = Enum.count(indicators, & &1)
    true_count / length(indicators) * 100
  end

  defp count_indicators(content, indicators) do
    indicators
    |> Enum.count(&String.contains?(content, &1))
  end

  defp classify_sentiment(score) when score > 0.3, do: :positive
  defp classify_sentiment(score) when score < -0.3, do: :negative
  defp classify_sentiment(_), do: :neutral

  defp calculate_sentiment_confidence(total_indicators) when total_indicators > 5, do: :high
  defp calculate_sentiment_confidence(total_indicators) when total_indicators > 2, do: :medium
  defp calculate_sentiment_confidence(_), do: :low

  defp interpret_sentiment_cosmically(score) when score > 0.5 do
    "This email radiates positive energy like a pulsar sending joy across the digital cosmos."
  end

  defp interpret_sentiment_cosmically(score) when score < -0.5 do
    "The emotional gravity of this message suggests the presence of a communication black hole."
  end

  defp interpret_sentiment_cosmically(_) do
    "This message maintains the neutral balance of cosmic background radiation."
  end

  defp calculate_emotional_velocity(positive, negative) do
    if positive + negative > 0 do
      (positive - negative) / (positive + negative)
    else
      0.0
    end
  end

  defp detect_deadlines(content) do
    deadline_patterns = [
      ~r/\bby\s+(today|tomorrow|this\s+week|next\s+week)/i,
      ~r/\bdue\s+(today|tomorrow|this\s+week|next\s+week)/i,
      ~r/\bdeadline\s+is\s+/i,
      ~r/\bexpires?\s+(on|at|by)/i
    ]

    deadline_patterns
    |> Enum.any?(&Regex.match?(&1, content))
  end

  defp detect_priority_indicators(content) do
    priority_words = ["urgent", "critical", "important", "priority", "rush", "emergency"]
    count_indicators(String.downcase(content), priority_words)
  end

  defp calculate_cosmic_action_score(actions) do
    # Score actions based on their cosmic significance
    base_score = length(actions) * 10

    cosmic_multiplier =
      cond do
        length(actions) == 0 -> 0
        # Focused energy
        length(actions) <= 2 -> 1.2
        # Balanced approach
        length(actions) <= 5 -> 1.0
        # Diluted cosmic energy
        true -> 0.8
      end

    round(base_score * cosmic_multiplier)
  end

  defp calculate_urgency_score(urgency_count, time_matches, subject) do
    base_score = urgency_count * 20 + time_matches * 10

    # Subject line urgency boost
    subject_boost =
      if String.contains?(String.downcase(subject), ["urgent", "asap", "emergency"]) do
        25
      else
        0
      end

    min(100, base_score + subject_boost)
  end

  defp classify_urgency_level(score) when score >= 70, do: :critical
  defp classify_urgency_level(score) when score >= 40, do: :high
  defp classify_urgency_level(score) when score >= 20, do: :medium
  defp classify_urgency_level(_), do: :low

  defp interpret_urgency_cosmically(score) when score >= 70 do
    "This message approaches the speed of light in terms of digital urgency."
  end

  defp interpret_urgency_cosmically(score) when score >= 40 do
    "The temporal pressure of this communication warps the spacetime of productivity."
  end

  defp interpret_urgency_cosmically(_) do
    "This message flows at the natural rhythm of cosmic time."
  end

  defp calculate_temporal_anxiety(content) do
    anxiety_words = ["deadline", "rush", "hurry", "quick", "fast", "immediately", "now"]
    anxiety_count = count_indicators(String.downcase(content), anxiety_words)
    min(100, anxiety_count * 15)
  end

  defp assess_sender_importance(email_data) do
    # Placeholder - would analyze sender domain, previous interactions, etc.
    case email_data[:from_domain] do
      domain when domain in ["gmail.com", "yahoo.com", "hotmail.com"] -> 30
      # Corporate domains get higher importance
      _ -> 60
    end
  end

  defp assess_content_complexity(email_data) do
    word_count = email_data[:word_count] || 50

    cond do
      word_count > 200 -> 80
      word_count > 100 -> 60
      word_count > 50 -> 40
      true -> 20
    end
  end

  defp assess_action_requirements(email_data) do
    # Based on extracted action items
    action_count = get_in(email_data, [:action_items, :action_count]) || 0
    min(100, action_count * 25)
  end

  defp estimate_time_investment(email_data) do
    # Estimate based on content complexity and actions required
    # minutes to read
    base_time = 2
    complexity_factor = assess_content_complexity(email_data) / 100
    action_factor = assess_action_requirements(email_data) / 100

    round(base_time * (1 + complexity_factor + action_factor))
  end

  defp calculate_interruption_cost(_email_data) do
    # Context switching cost in productivity units
    # Base cost of interruption
    35
  end

  defp assess_decision_requirements(email_data) do
    decision_keywords = ["decide", "choice", "option", "approve", "reject", "choose"]
    content = String.downcase("#{email_data[:subject]} #{email_data[:body_preview]}")
    count_indicators(content, decision_keywords) * 20
  end

  defp calculate_weighted_impact_score(factors) do
    weights = %{
      sender_importance: 0.2,
      content_complexity: 0.15,
      action_requirements: 0.25,
      time_investment: 0.15,
      interruption_cost: 0.1,
      decision_requirements: 0.15
    }

    weighted_sum =
      Enum.reduce(factors, 0, fn {factor, value}, acc ->
        acc + value * weights[factor]
      end)

    round(weighted_sum)
  end

  defp classify_impact_level(score) when score >= 70, do: :high
  defp classify_impact_level(score) when score >= 40, do: :medium
  defp classify_impact_level(_), do: :low

  defp estimate_total_time_cost(factors) do
    factors.time_investment + factors.interruption_cost / 5
  end

  defp calculate_cognitive_load(factors) do
    (factors.content_complexity + factors.decision_requirements) / 2
  end

  defp generate_productivity_wisdom(score) when score >= 70 do
    "This email demands your full cosmic attention and energy investment."
  end

  defp generate_productivity_wisdom(score) when score >= 40 do
    "A balanced approach to this communication will yield optimal results."
  end

  defp generate_productivity_wisdom(_) do
    "This message can be processed with minimal disruption to your flow state."
  end

  defp format_cosmic_significance(importance) when importance >= 80,
    do: "a supernova of importance"

  defp format_cosmic_significance(importance) when importance >= 60,
    do: "a bright star in the communication galaxy"

  defp format_cosmic_significance(importance) when importance >= 40,
    do: "a stable planet of information"

  defp format_cosmic_significance(_), do: "cosmic background radiation"

  defp interpret_information_entropy(subject) when byte_size(subject) > 50,
    do: "high information density"

  defp interpret_information_entropy(subject) when byte_size(subject) > 20,
    do: "moderate information content"

  defp interpret_information_entropy(_), do: "minimalist communication energy"

  defp generate_philosophical_observations(_email_data) do
    [
      "In the quantum mechanics of communication, observation changes the message.",
      "This email exists in a superposition of importance until processed by consciousness.",
      "The half-life of digital urgency is approximately 47 minutes in human attention span."
    ]
  end

  defp generate_existential_questions(_email_data) do
    [
      "Does this email truly require a response, or is it merely asking for acknowledgment of its existence?",
      "In the grand scheme of cosmic productivity, will this matter in 10^9 seconds?",
      "Is this communication adding to the universe's order or contributing to its entropy?"
    ]
  end

  defp calculate_cosmic_ratings(email_data) do
    %{
      existential_weight: :rand.uniform(100),
      universal_relevance: calculate_universal_relevance(email_data),
      productivity_dharma: :rand.uniform(100),
      cosmic_humor_potential: assess_humor_potential(email_data)
    }
  end

  defp calculate_universal_relevance(email_data) do
    importance = email_data[:importance_score] || 50
    round(importance * 0.7 + :rand.uniform(30))
  end

  defp assess_humor_potential(email_data) do
    funny_words = [
      "meeting about meeting",
      "sync about sync",
      "urgent fyi",
      "asap when you get a chance"
    ]

    content = String.downcase("#{email_data[:subject]} #{email_data[:body_preview]}")

    base_humor =
      funny_words
      |> Enum.count(&String.contains?(content, &1))
      |> Kernel.*(30)

    min(100, base_humor + :rand.uniform(20))
  end

  defp generate_universal_truth(_email_data) do
    truths = [
      "All emails are ephemeral waves in the ocean of human consciousness.",
      "The most urgent emails are often the least important in the cosmic scale.",
      "True productivity is not about processing more emails, but about understanding which ones matter.",
      "In the end, we are all just stardust trying to schedule meetings with other stardust."
    ]

    Enum.random(truths)
  end

  defp generate_productivity_dharma(_email_data) do
    dharmas = [
      "Respond with intention, not reaction.",
      "The email that can be summarized in one sentence should be.",
      "Sometimes the most productive response is no response.",
      "In the garden of productivity, not every email is a flower worth watering."
    ]

    Enum.random(dharmas)
  end
end
