defmodule Neptuner.Integrations.EmailToTaskExtractor do
  @moduledoc """
  Extracts actionable tasks from emails with cosmic wisdom about the nature of digital work.
  Transforms email chaos into organized task enlightenment.
  """

  require Logger
  alias Neptuner.{Tasks, Communications}
  alias Neptuner.Integrations.AdvancedEmailAnalysis

  @doc """
  Analyzes an email summary and extracts potential tasks.
  Returns a list of suggested tasks with cosmic priority assessment.
  """
  def extract_tasks_from_email(email_summary) do
    analysis = AdvancedEmailAnalysis.analyze_email_advanced(%{
      subject: email_summary.subject,
      body_preview: email_summary.body_preview || "",
      from_email: email_summary.sender_email,
      from_domain: email_summary.from_domain,
      classification: email_summary.classification,
      importance_score: email_summary.importance_score,
      word_count: email_summary.word_count,
      has_attachments: email_summary.has_attachments
    })

    potential_tasks = []
    
    # Extract from action items analysis
    potential_tasks = potential_tasks ++ extract_from_action_items(analysis.action_items, email_summary)
    
    # Extract from meeting potential
    potential_tasks = potential_tasks ++ extract_from_meeting_potential(analysis.meeting_potential, email_summary)
    
    # Extract from email intent
    potential_tasks = potential_tasks ++ extract_from_intent(analysis.intent, email_summary)
    
    # Extract from subject line patterns
    potential_tasks = potential_tasks ++ extract_from_subject_patterns(email_summary)
    
    # Add cosmic task analysis
    potential_tasks
    |> Enum.map(&add_cosmic_analysis(&1, email_summary, analysis))
    |> Enum.filter(&(&1.confidence_score > 30))
    |> Enum.sort_by(&(&1.confidence_score), :desc)
  end

  @doc """
  Converts an email into tasks based on user preferences and automatically creates them.
  """
  def auto_convert_email_to_tasks(user_id, email_summary, opts \\ []) do
    potential_tasks = extract_tasks_from_email(email_summary)
    
    # Filter based on user preferences (if provided)
    auto_create_threshold = opts[:auto_create_threshold] || 70
    
    tasks_to_create = 
      potential_tasks
      |> Enum.filter(&(&1.confidence_score >= auto_create_threshold))
      |> Enum.take(opts[:max_auto_tasks] || 3)  # Limit to prevent task explosion
    
    created_tasks = 
      tasks_to_create
      |> Enum.map(&create_task_from_email(&1, user_id, email_summary))
      |> Enum.filter(fn
        {:ok, _task} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, task} -> task end)
    
    # Mark email as processed for task extraction
    Communications.update_email_summary(email_summary, %{
      tasks_created_count: length(created_tasks),
      last_task_extraction_at: DateTime.utc_now()
    })
    
    {:ok, %{
      potential_tasks: potential_tasks,
      created_tasks: created_tasks,
      cosmic_wisdom: generate_conversion_wisdom(potential_tasks, created_tasks)
    }}
  end

  @doc """
  Analyzes email patterns to suggest task extraction settings.
  """
  def suggest_extraction_settings(user_id, days_back \\ 30) do
    recent_emails = Communications.get_recent_email_summaries(user_id, days_back)
    
    # Analyze patterns
    high_action_senders = analyze_high_action_senders(recent_emails)
    common_task_patterns = analyze_common_task_patterns(recent_emails)
    optimal_threshold = calculate_optimal_threshold(recent_emails)
    
    %{
      recommended_threshold: optimal_threshold,
      high_action_senders: high_action_senders,
      common_patterns: common_task_patterns,
      suggested_filters: suggest_filters(recent_emails),
      cosmic_insights: generate_pattern_insights(recent_emails)
    }
  end

  # Private functions

  defp extract_from_action_items(action_items, email_summary) do
    action_items.action_items
    |> Enum.map(fn action_text ->
      %{
        title: clean_action_text(action_text),
        description: "From email: #{email_summary.subject}",
        source: :action_item,
        confidence_score: calculate_action_confidence(action_text, action_items),
        cosmic_priority: determine_cosmic_priority_from_action(action_text),
        estimated_importance: estimate_action_importance(action_text, email_summary),
        extracted_from: "Action item analysis"
      }
    end)
  end

  defp extract_from_meeting_potential(meeting_potential, email_summary) do
    if meeting_potential.confidence_score > 60 do
      meeting_tasks = []
      
      # Create task for scheduling/attending meeting
      meeting_task = %{
        title: generate_meeting_task_title(email_summary.subject, meeting_potential),
        description: "Meeting coordination from email: #{email_summary.subject}",
        source: :meeting_coordination,
        confidence_score: meeting_potential.confidence_score,
        cosmic_priority: :matters_10_days,  # Meetings often have deadlines
        estimated_importance: min(70, email_summary.importance_score + 20),
        extracted_from: "Meeting potential analysis"
      }
      
      meeting_tasks = [meeting_task | meeting_tasks]
      
      # Add preparation task if it's a presentation or demo
      meeting_tasks = if meeting_potential.meeting_type in [:presentation, :demo] do
        prep_task = %{
          title: "Prepare for #{String.downcase(to_string(meeting_potential.meeting_type))}",
          description: "Preparation for meeting from email: #{email_summary.subject}",
          source: :meeting_preparation,
          confidence_score: meeting_potential.confidence_score - 10,
          cosmic_priority: :matters_10_days,
          estimated_importance: email_summary.importance_score,
          extracted_from: "Meeting preparation analysis"
        }
        
        [prep_task | meeting_tasks]
      else
        meeting_tasks
      end
      
      meeting_tasks
    else
      []
    end
  end

  defp extract_from_intent(intent, email_summary) do
    case intent do
      :request_action ->
        [%{
          title: generate_intent_task_title(email_summary.subject, intent),
          description: "Action requested in email: #{email_summary.subject}",
          source: :intent_analysis,
          confidence_score: 65,
          cosmic_priority: determine_cosmic_priority_from_intent(intent, email_summary),
          estimated_importance: email_summary.importance_score,
          extracted_from: "Email intent analysis"
        }]
      
      :decision_required ->
        [%{
          title: "Make decision: #{extract_decision_context(email_summary.subject)}",
          description: "Decision needed from email: #{email_summary.subject}",
          source: :decision_required,
          confidence_score: 70,
          cosmic_priority: :matters_10_days,
          estimated_importance: min(80, email_summary.importance_score + 15),
          extracted_from: "Decision requirement analysis"
        }]
      
      :seeking_information ->
        [%{
          title: "Provide information: #{extract_information_context(email_summary.subject)}",
          description: "Information requested in email: #{email_summary.subject}",
          source: :information_request,
          confidence_score: 55,
          cosmic_priority: determine_cosmic_priority_from_intent(intent, email_summary),
          estimated_importance: email_summary.importance_score,
          extracted_from: "Information request analysis"
        }]
      
      _ ->
        []
    end
  end

  defp extract_from_subject_patterns(email_summary) do
    subject = email_summary.subject
    
    patterns = [
      {~r/action\s+required:?\s*(.+)/i, "Complete action", 75},
      {~r/please\s+(.+)/i, "Handle request", 65},
      {~r/need\s+(.+)/i, "Address need", 60},
      {~r/follow\s+up\s+on\s+(.+)/i, "Follow up on", 70},
      {~r/review\s+(.+)/i, "Review", 55},
      {~r/approve\s+(.+)/i, "Approve", 80},
      {~r/feedback\s+on\s+(.+)/i, "Provide feedback on", 50},
      {~r/update\s+on\s+(.+)/i, "Get update on", 45}
    ]
    
    patterns
    |> Enum.flat_map(fn {pattern, task_prefix, confidence} ->
      case Regex.run(pattern, subject) do
        [_, context] ->
          [%{
            title: "#{task_prefix}: #{String.trim(context)}",
            description: "From email subject: #{subject}",
            source: :subject_pattern,
            confidence_score: confidence,
            cosmic_priority: determine_cosmic_priority_from_urgency(email_summary),
            estimated_importance: email_summary.importance_score,
            extracted_from: "Subject line pattern matching"
          }]
        
        nil ->
          []
      end
    end)
  end

  defp add_cosmic_analysis(task, email_summary, analysis) do
    # Add cosmic insights and philosophical perspective
    cosmic_analysis = %{
      existential_weight: calculate_existential_weight(task, email_summary),
      productivity_dharma: generate_task_dharma(task),
      cosmic_urgency: interpret_cosmic_urgency(analysis.urgency),
      universal_relevance: calculate_universal_relevance(task, email_summary)
    }
    
    Map.put(task, :cosmic_analysis, cosmic_analysis)
  end

  defp create_task_from_email(task_data, user_id, email_summary) do
    attrs = %{
      title: task_data.title,
      description: build_task_description(task_data, email_summary),
      cosmic_priority: task_data.cosmic_priority,
      estimated_actual_importance: task_data.estimated_importance,
      status: :pending,
      source_email_id: email_summary.id,
      extracted_confidence: task_data.confidence_score,
      extraction_method: task_data.extracted_from
    }
    
    Tasks.create_task(user_id, attrs)
  end

  defp clean_action_text(text) do
    text
    |> String.trim()
    |> String.replace(~r/^(please\s+|need\s+to\s+)/i, "")
    |> String.capitalize()
    |> String.slice(0, 100)  # Limit length
  end

  defp calculate_action_confidence(action_text, action_items) do
    base_confidence = 60
    
    # Boost confidence for clear action verbs
    verb_boost = if String.match?(action_text, ~r/\b(send|create|update|review|approve|complete|finish|call|email|schedule|book|cancel|confirm)\b/i) do
      15
    else
      0
    end
    
    # Boost if priority indicators present
    priority_boost = if action_items.priority_indicators > 0 do
      10
    else
      0
    end
    
    # Boost if deadlines present
    deadline_boost = if action_items.has_deadlines do
      10
    else
      0
    end
    
    min(95, base_confidence + verb_boost + priority_boost + deadline_boost)
  end

  defp determine_cosmic_priority_from_action(action_text) do
    action_lower = String.downcase(action_text)
    
    cond do
      String.contains?(action_lower, ["approve", "sign", "authorize", "decision"]) ->
        :matters_10_days
      
      String.contains?(action_lower, ["review", "feedback", "comment", "check"]) ->
        :matters_10_days
      
      String.contains?(action_lower, ["meeting", "call", "schedule", "book"]) ->
        :matters_10_days
      
      String.contains?(action_lower, ["send", "email", "reply", "respond"]) ->
        :matters_to_nobody
      
      true ->
        :matters_10_days
    end
  end

  defp estimate_action_importance(action_text, email_summary) do
    base_importance = email_summary.importance_score
    
    # Boost for action verbs that imply decisions
    decision_boost = if String.match?(action_text, ~r/\b(approve|decide|choose|authorize|sign|confirm)\b/i) do
      15
    else
      0
    end
    
    # Boost for creation/completion actions
    creation_boost = if String.match?(action_text, ~r/\b(create|build|develop|complete|finish|deliver)\b/i) do
      10
    else
      0
    end
    
    min(100, base_importance + decision_boost + creation_boost)
  end

  defp generate_meeting_task_title(subject, meeting_potential) do
    if meeting_potential.meeting_type != :general do
      "Attend #{String.downcase(to_string(meeting_potential.meeting_type))}: #{extract_meeting_context(subject)}"
    else
      "Attend meeting: #{extract_meeting_context(subject)}"
    end
  end

  defp extract_meeting_context(subject) do
    # Remove common email prefixes and extract meaningful context
    subject
    |> String.replace(~r/^(re:|fwd?:|fw:)\s*/i, "")
    |> String.replace(~r/\s*(meeting|call|sync|standup|discussion)\s*/i, "")
    |> String.trim()
    |> case do
      "" -> "meeting discussion"
      context -> context
    end
    |> String.slice(0, 50)
  end

  defp generate_intent_task_title(subject, _intent) do
    context = extract_action_context(subject)
    "Handle request: #{context}"
  end

  defp extract_decision_context(subject) do
    subject
    |> String.replace(~r/^(re:|fwd?:|fw:)\s*/i, "")
    |> String.replace(~r/\s*(decision|decide|choose|approve)\s*/i, "")
    |> String.trim()
    |> String.slice(0, 50)
  end

  defp extract_information_context(subject) do
    subject
    |> String.replace(~r/^(re:|fwd?:|fw:)\s*/i, "")
    |> String.replace(~r/\s*(question|help|support|information|clarification)\s*/i, "")
    |> String.trim()
    |> String.slice(0, 50)
  end

  defp extract_action_context(subject) do
    subject
    |> String.replace(~r/^(re:|fwd?:|fw:)\s*/i, "")
    |> String.replace(~r/\s*(please|action required|need|request)\s*/i, "")
    |> String.trim()
    |> String.slice(0, 50)
  end

  defp determine_cosmic_priority_from_intent(intent, email_summary) do
    base_priority = case intent do
      :urgent_notification -> :matters_10_days
      :decision_required -> :matters_10_days
      :request_action -> :matters_10_days
      :meeting_coordination -> :matters_10_days
      :seeking_information -> :matters_to_nobody
      :reminder -> :matters_to_nobody
      _ -> :matters_to_nobody
    end
    
    # Upgrade priority if email importance is high
    if email_summary.importance_score > 75 and base_priority == :matters_to_nobody do
      :matters_10_days
    else
      base_priority
    end
  end

  defp determine_cosmic_priority_from_urgency(email_summary) do
    case email_summary.classification do
      :urgent_void -> :matters_10_days
      :meeting_coordination -> :matters_10_days
      :help_seeking -> :matters_10_days
      :status_ritual -> :matters_to_nobody
      :information_broadcast -> :matters_to_nobody
      :social_lubrication -> :matters_to_nobody
      _ -> :matters_to_nobody
    end
  end

  defp calculate_existential_weight(task, email_summary) do
    # Cosmic calculation of whether this task matters in the universe
    base_weight = 50
    
    # Boost for tasks that create or decide things
    creation_boost = if String.contains?(String.downcase(task.title), ["create", "build", "decide", "approve"]) do
      20
    else
      0
    end
    
    # Diminish for routine communications
    routine_penalty = if String.contains?(String.downcase(task.title), ["send", "reply", "forward", "update"]) do
      -15
    else
      0
    end
    
    # Factor in email importance
    importance_factor = (email_summary.importance_score - 50) * 0.3
    
    round(base_weight + creation_boost + routine_penalty + importance_factor)
  end

  defp generate_task_dharma(_task) do
    dharmas = [
      "This task exists, therefore it seeks completion.",
      "In doing, we become. In completing, we transcend.",
      "Even digital rectangles contain the spark of cosmic purpose.",
      "The task that brings clarity is worth the electrons it consumes.",
      "Not all that is urgent is important, not all that is important appears urgent."
    ]
    
    Enum.random(dharmas)
  end

  defp interpret_cosmic_urgency(urgency_analysis) do
    case urgency_analysis.urgency_level do
      :critical -> "This task burns with the intensity of a dying star"
      :high -> "Temporal forces accelerate around this task"
      :medium -> "Time flows normally through this task's space"
      :low -> "This task rests in the peaceful void of eventual completion"
    end
  end

  defp calculate_universal_relevance(task, email_summary) do
    # Will this matter in the cosmic scale?
    relevance_factors = [
      String.contains?(String.downcase(task.title), ["strategy", "vision", "future", "growth"]),
      email_summary.importance_score > 70,
      task.confidence_score > 75,
      String.contains?(String.downcase(task.title), ["decision", "approve", "create"])
    ]
    
    true_count = Enum.count(relevance_factors, & &1)
    true_count * 25
  end

  defp build_task_description(task_data, email_summary) do
    base_description = task_data.description
    
    metadata = [
      "📧 From: #{email_summary.sender_email}",
      "🎯 Confidence: #{task_data.confidence_score}%",
      "🌌 Cosmic Priority: #{task_data.cosmic_priority}",
      "🔍 Extracted via: #{task_data.extracted_from}"
    ]
    
    metadata = if task_data[:cosmic_analysis] do
      metadata ++ [
        "⚖️ Existential Weight: #{task_data.cosmic_analysis.existential_weight}%",
        "🧘 Dharma: #{task_data.cosmic_analysis.productivity_dharma}"
      ]
    else
      metadata
    end
    
    """
    #{base_description}

    #{Enum.join(metadata, "\n")}
    """
  end

  defp generate_conversion_wisdom(potential_tasks, created_tasks) do
    potential_count = length(potential_tasks)
    created_count = length(created_tasks)
    
    wisdom = cond do
      created_count == 0 ->
        "In the vast cosmos of digital communication, sometimes the most productive action is thoughtful inaction."
      
      created_count >= potential_count ->
        "Maximum task extraction achieved. Your email has been fully transformed into actionable cosmic energy."
      
      created_count > 0 ->
        "#{created_count} tasks emerged from the digital void, while #{potential_count - created_count} remained as potentialities in the quantum email field."
      
      true ->
        "The email spoke, but the cosmos chose silence."
    end
    
    %{
      main_wisdom: wisdom,
      task_stats: %{
        potential: potential_count,
        created: created_count,
        conversion_rate: if(potential_count > 0, do: created_count / potential_count * 100, else: 0)
      }
    }
  end

  defp analyze_high_action_senders(emails) do
    emails
    |> Enum.filter(&(&1.classification in [:urgent_important, :not_urgent_important]))
    |> Enum.group_by(& &1.sender_email)
    |> Enum.map(fn {sender, sender_emails} -> 
      {sender, length(sender_emails)}
    end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.take(10)
  end

  defp analyze_common_task_patterns(emails) do
    # Analyze common patterns in high-importance emails
    high_importance_emails = Enum.filter(emails, &(&1.importance_score > 60))
    
    common_subjects = 
      high_importance_emails
      |> Enum.map(& &1.subject)
      |> Enum.flat_map(&extract_keywords/1)
      |> Enum.frequencies()
      |> Enum.sort_by(&elem(&1, 1), :desc)
      |> Enum.take(15)
    
    %{
      high_importance_keywords: common_subjects,
      action_classifications: Enum.frequencies(Enum.map(high_importance_emails, & &1.classification))
    }
  end

  defp extract_keywords(subject) do
    subject
    |> String.downcase()
    |> String.replace(~r/[^\w\s]/, "")
    |> String.split()
    |> Enum.filter(&(String.length(&1) > 3))
    |> Enum.reject(&(&1 in ["with", "from", "this", "that", "will", "have", "been", "were", "they", "them"]))
  end

  defp calculate_optimal_threshold(emails) do
    # Calculate optimal threshold based on email importance distribution
    importance_scores = Enum.map(emails, & &1.importance_score)
    
    if length(importance_scores) > 0 do
      average = Enum.sum(importance_scores) / length(importance_scores)
      std_dev = calculate_std_dev(importance_scores, average)
      
      # Set threshold at average + 0.5 standard deviations
      round(average + std_dev * 0.5)
    else
      65  # Default threshold
    end
  end

  defp calculate_std_dev(values, mean) do
    variance = 
      values
      |> Enum.map(&(:math.pow(&1 - mean, 2)))
      |> Enum.sum()
      |> Kernel./(length(values))
    
    :math.sqrt(variance)
  end

  defp suggest_filters(emails) do
    # Suggest filters based on email patterns
    sender_domains = 
      emails
      |> Enum.map(& &1.from_domain)
      |> Enum.frequencies()
      |> Enum.sort_by(&elem(&1, 1), :desc)
    
    %{
      high_volume_domains: Enum.take(sender_domains, 5),
      suggested_auto_create_senders: suggest_auto_create_senders(emails),
      suggested_ignore_patterns: suggest_ignore_patterns(emails)
    }
  end

  defp suggest_auto_create_senders(emails) do
    # Suggest senders whose emails often result in tasks
    emails
    |> Enum.filter(&(&1.classification in [:urgent_important, :not_urgent_important]))
    |> Enum.group_by(& &1.sender_email)
    |> Enum.filter(fn {_sender, sender_emails} -> length(sender_emails) >= 3 end)
    |> Enum.map(&elem(&1, 0))
  end

  defp suggest_ignore_patterns(emails) do
    # Suggest patterns that rarely result in actionable items
    low_action_emails = 
      emails
      |> Enum.filter(&(&1.classification in [:urgent_unimportant, :digital_noise]))
    
    common_subjects = 
      low_action_emails
      |> Enum.map(& &1.subject)
      |> Enum.flat_map(&extract_keywords/1)
      |> Enum.frequencies()
      |> Enum.filter(fn {_word, count} -> count >= 3 end)
      |> Enum.map(&elem(&1, 0))
    
    %{
      low_action_keywords: common_subjects,
      newsletter_indicators: ["newsletter", "digest", "update", "notification"]
    }
  end

  defp generate_pattern_insights(emails) do
    total_emails = length(emails)
    actionable_emails = Enum.count(emails, &(&1.classification in [:urgent_important, :not_urgent_important]))
    
    actionable_percentage = if total_emails > 0 do
      actionable_emails / total_emails * 100
    else
      0
    end
    
    insights = [
      "#{Float.round(actionable_percentage, 1)}% of your emails contain actionable items worth transforming into tasks.",
      "The cosmic email-to-task conversion rate suggests #{cond do
        actionable_percentage > 30 -> "high digital productivity demands"
        actionable_percentage > 15 -> "moderate task generation patterns"
        true -> "mostly informational communication flow"
      end}.",
      "In the grand scheme of inbox enlightenment, you receive #{Float.round(actionable_emails / 7, 1)} actionable emails per day on average."
    ]
    
    %{
      insights: insights,
      actionable_percentage: actionable_percentage,
      daily_actionable_average: if(total_emails > 0, do: actionable_emails / 30, else: 0)
    }
  end
end