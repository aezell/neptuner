defmodule Neptuner.Communications do
  @moduledoc """
  The Communications context for email and communication analysis.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo

  alias Neptuner.Communications.EmailSummary
  alias Neptuner.Connections

  def list_email_summaries(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    classification = Keyword.get(opts, :classification)

    base_query =
      EmailSummary
      |> where([es], es.user_id == ^user_id)
      |> order_by([es], desc: es.received_at)
      |> limit(^limit)

    query =
      if classification && classification != "all" do
        base_query |> where([es], es.classification == ^classification)
      else
        base_query
      end

    Repo.all(query)
  end

  def list_email_summaries_for_date_range(user_id, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

    EmailSummary
    |> where([es], es.user_id == ^user_id)
    |> where([es], es.received_at >= ^start_datetime and es.received_at <= ^end_datetime)
    |> order_by([es], desc: es.received_at)
    |> Repo.all()
  end

  def get_email_summary!(id), do: Repo.get!(EmailSummary, id)

  def get_user_email_summary!(user_id, id) do
    EmailSummary
    |> where([es], es.user_id == ^user_id and es.id == ^id)
    |> Repo.one!()
  end

  def create_email_summary(user_id, attrs \\ %{}) do
    %EmailSummary{}
    |> EmailSummary.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Repo.insert()
  end

  def update_email_summary(%EmailSummary{} = email_summary, attrs) do
    email_summary
    |> EmailSummary.changeset(attrs)
    |> Repo.update()
  end

  def delete_email_summary(%EmailSummary{} = email_summary) do
    Repo.delete(email_summary)
  end

  def change_email_summary(%EmailSummary{} = email_summary, attrs \\ %{}) do
    EmailSummary.changeset(email_summary, attrs)
  end

  @doc """
  Creates or updates an email summary based on external_id from synced services.
  Used for Gmail, Outlook, etc. integration.
  """
  def upsert_email_summary_by_external_id(user_id, external_id, attrs) do
    case get_email_summary_by_external_id(user_id, external_id) do
      nil ->
        # Create new email summary
        attrs_with_external_id = Map.put(attrs, :external_id, external_id)
        create_email_summary(user_id, attrs_with_external_id)

      email_summary ->
        # Update existing email summary
        update_email_summary(email_summary, attrs)
    end
  end

  @doc """
  Gets an email summary by its external_id (from synced services).
  """
  def get_email_summary_by_external_id(user_id, external_id) do
    EmailSummary
    |> where([es], es.user_id == ^user_id and es.external_id == ^external_id)
    |> Repo.one()
  end

  def classify_email_importance(subject, body \\ "") do
    subject_lower = String.downcase(subject)
    body_lower = String.downcase(body)
    content = subject_lower <> " " <> body_lower

    cond do
      urgent_and_important?(content) -> :urgent_important
      urgent_but_unimportant?(content) -> :urgent_unimportant
      important_but_not_urgent?(content) -> :not_urgent_important
      true -> :digital_noise
    end
  end

  defp urgent_and_important?(content) do
    urgent_keywords = ["urgent", "asap", "emergency", "critical", "deadline", "due today"]
    important_keywords = ["contract", "legal", "security", "breach", "medical", "family"]

    has_urgent = Enum.any?(urgent_keywords, &String.contains?(content, &1))
    has_important = Enum.any?(important_keywords, &String.contains?(content, &1))

    has_urgent && has_important
  end

  defp urgent_but_unimportant?(content) do
    urgent_keywords = ["urgent", "asap", "emergency", "critical", "deadline", "due today"]

    unimportant_indicators = [
      "newsletter",
      "unsubscribe",
      "marketing",
      "sale",
      "offer",
      "promotion"
    ]

    has_urgent = Enum.any?(urgent_keywords, &String.contains?(content, &1))
    is_marketing = Enum.any?(unimportant_indicators, &String.contains?(content, &1))

    has_urgent || is_marketing
  end

  defp important_but_not_urgent?(content) do
    important_keywords = ["project", "meeting", "review", "feedback", "proposal", "contract"]
    Enum.any?(important_keywords, &String.contains?(content, &1))
  end

  def get_communication_statistics(user_id) do
    base_query = EmailSummary |> where([es], es.user_id == ^user_id)

    total_emails = Repo.aggregate(base_query, :count)

    urgent_important =
      base_query
      |> where([es], es.classification == :urgent_important)
      |> Repo.aggregate(:count)

    urgent_unimportant =
      base_query
      |> where([es], es.classification == :urgent_unimportant)
      |> Repo.aggregate(:count)

    not_urgent_important =
      base_query
      |> where([es], es.classification == :not_urgent_important)
      |> Repo.aggregate(:count)

    digital_noise =
      base_query
      |> where([es], es.classification == :digital_noise)
      |> Repo.aggregate(:count)

    avg_response_time =
      base_query
      |> where([es], not is_nil(es.response_time_hours))
      |> Repo.aggregate(:avg, :response_time_hours)

    total_hours_lost =
      base_query
      |> where([es], es.classification in [:urgent_unimportant, :digital_noise])
      |> Repo.aggregate(:sum, :time_spent_minutes)

    %{
      total_emails: total_emails,
      urgent_important: urgent_important,
      urgent_unimportant: urgent_unimportant,
      not_urgent_important: not_urgent_important,
      digital_noise: digital_noise,
      average_response_time_hours:
        if(avg_response_time, do: Float.round(avg_response_time, 1), else: nil),
      total_hours_lost_to_noise: if(total_hours_lost, do: div(total_hours_lost, 60), else: 0),
      noise_percentage:
        if(total_emails > 0,
          do: round((urgent_unimportant + digital_noise) / total_emails * 100),
          else: 0
        )
    }
  end

  def get_email_pattern_insights(user_id) do
    stats = get_communication_statistics(user_id)

    insights = []

    insights =
      if stats.noise_percentage > 60 do
        [
          "Your inbox is #{stats.noise_percentage}% existential noise. Consider email minimalism."
          | insights
        ]
      else
        insights
      end

    insights =
      if stats.total_hours_lost_to_noise > 10 do
        [
          "You've lost #{stats.total_hours_lost_to_noise} hours to digital noise this week. Time is finite."
          | insights
        ]
      else
        insights
      end

    insights =
      if stats.average_response_time_hours && stats.average_response_time_hours > 24 do
        [
          "Your #{Float.round(stats.average_response_time_hours, 1)} hour response time suggests healthy email boundaries."
          | insights
        ]
      else
        insights
      end

    insights =
      if stats.urgent_important > 0 && stats.urgent_unimportant > stats.urgent_important * 3 do
        [
          "#{stats.urgent_unimportant} fake urgencies vs #{stats.urgent_important} real ones. The digital world cries wolf."
          | insights
        ]
      else
        insights
      end

    if insights == [] do
      [
        "Your communication patterns suggest either zen-like inbox mastery or insufficient data for cosmic judgment."
      ]
    else
      insights
    end
  end

  def sync_emails_from_connections(user_id) do
    email_connections = Connections.get_email_connections(user_id)

    if email_connections == [] do
      {:error, "No email connections found"}
    else
      results =
        email_connections
        |> Enum.map(fn connection ->
          case connection.provider do
            :google -> sync_gmail_emails(connection)
            :microsoft -> sync_outlook_emails(connection)
            _ -> {:error, "Unsupported provider: #{connection.provider}"}
          end
        end)

      successful_syncs =
        Enum.count(results, fn
          {:ok, _} -> true
          _ -> false
        end)

      if successful_syncs > 0 do
        {:ok, "Synced emails from #{successful_syncs}/#{length(email_connections)} connections"}
      else
        {:error, "Failed to sync emails from any connections"}
      end
    end
  end

  defp sync_gmail_emails(connection) do
    generate_sample_emails(connection.user_id, :google)
  end

  defp sync_outlook_emails(connection) do
    generate_sample_emails(connection.user_id, :microsoft)
  end

  @doc """
  Gets recent email summaries for analysis.
  """
  def get_recent_email_summaries(user_id, days_back \\ 30) do
    start_date = Date.utc_today() |> Date.add(-days_back)
    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")

    EmailSummary
    |> where([es], es.user_id == ^user_id)
    |> where([es], es.received_at >= ^start_datetime)
    |> order_by([es], desc: es.received_at)
    |> Repo.all()
  end

  defp generate_sample_emails(user_id, _provider) do
    sample_emails = [
      %{
        subject: "URGENT: Q4 Marketing Campaign Review",
        sender_email: "marketing@company.com",
        sender_name: "Marketing Team",
        body_preview: "We need your feedback on the Q4 campaign materials by end of day...",
        received_at: DateTime.add(DateTime.utc_now(), -Enum.random(1..72), :hour),
        is_read: Enum.random([true, false]),
        response_time_hours: if(Enum.random([true, false]), do: Enum.random(1..48), else: nil),
        time_spent_minutes: Enum.random(2..30),
        importance_score: Enum.random(1..10)
      },
      %{
        subject: "Weekly Newsletter: Productivity Tips",
        sender_email: "newsletter@productivityguru.com",
        sender_name: "Productivity Guru",
        body_preview: "This week's top productivity hacks that will change your life...",
        received_at: DateTime.add(DateTime.utc_now(), -Enum.random(1..168), :hour),
        is_read: Enum.random([true, false]),
        response_time_hours: nil,
        time_spent_minutes: Enum.random(1..5),
        importance_score: Enum.random(1..3)
      },
      %{
        subject: "Meeting Reminder: Strategic Planning Session",
        sender_email: "calendar@company.com",
        sender_name: "Calendar System",
        body_preview: "Reminder: Strategic Planning Session tomorrow at 2 PM...",
        received_at: DateTime.add(DateTime.utc_now(), -Enum.random(12..36), :hour),
        is_read: true,
        response_time_hours: Enum.random(1..8),
        time_spent_minutes: Enum.random(1..10),
        importance_score: Enum.random(6..9)
      },
      %{
        subject: "Limited Time Offer: 50% Off Everything!",
        sender_email: "sales@retailstore.com",
        sender_name: "Retail Store",
        body_preview: "Don't miss out on our biggest sale of the year! 50% off everything...",
        received_at: DateTime.add(DateTime.utc_now(), -Enum.random(1..48), :hour),
        is_read: Enum.random([true, false]),
        response_time_hours: nil,
        time_spent_minutes: Enum.random(1..3),
        importance_score: Enum.random(1..2)
      },
      %{
        subject: "Project Proposal: New Feature Development",
        sender_email: "pm@company.com",
        sender_name: "Product Manager",
        body_preview: "I've attached the proposal for the new feature we discussed...",
        received_at: DateTime.add(DateTime.utc_now(), -Enum.random(24..96), :hour),
        is_read: true,
        response_time_hours: Enum.random(12..72),
        time_spent_minutes: Enum.random(15..45),
        importance_score: Enum.random(7..9)
      }
    ]

    Enum.each(sample_emails, fn email_attrs ->
      classification = classify_email_importance(email_attrs.subject, email_attrs.body_preview)

      attrs = Map.put(email_attrs, :classification, classification)
      create_email_summary(user_id, attrs)
    end)

    {:ok, "Generated #{length(sample_emails)} sample emails"}
  end

  # Additional functions for comprehensive testing

  @doc """
  Lists all email summaries (admin function).
  """
  def list_email_summaries do
    Repo.all(EmailSummary)
  end

  @doc """
  Lists email summaries for a specific user.
  """
  def list_email_summaries_for_user(user) do
    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> order_by([es], desc: es.received_at)
    |> Repo.all()
  end

  @doc """
  Lists email summaries by classification for a user.
  """
  def list_email_summaries_by_classification(user, classification) do
    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> where([es], es.classification == ^classification)
    |> order_by([es], desc: es.received_at)
    |> Repo.all()
  end

  @doc """
  Counts email summaries by classification for a user.
  """
  def count_email_summaries_by_classification(user, classification) do
    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> where([es], es.classification == ^classification)
    |> Repo.aggregate(:count)
  end

  @doc """
  Lists emails with high task potential above the given threshold.
  """
  def list_high_task_potential_emails(user, threshold \\ 0.7) do
    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> where([es], es.task_potential >= ^threshold)
    |> order_by([es], desc: es.task_potential)
    |> Repo.all()
  end

  @doc """
  Lists emails recommended for automatic task creation.
  """
  def list_auto_create_recommended_emails(user) do
    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> where([es], es.auto_create_recommended == true)
    |> order_by([es], desc: es.received_at)
    |> Repo.all()
  end

  @doc """
  Lists emails with high productivity theater scores above the given threshold.
  """
  def list_high_productivity_theater_emails(user, threshold \\ 0.7) do
    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> where([es], es.productivity_theater_score >= ^threshold)
    |> order_by([es], desc: es.productivity_theater_score)
    |> Repo.all()
  end

  @doc """
  Lists recent email summaries within the specified number of days.
  """
  def list_recent_email_summaries(user, days_back) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days_back, :day)

    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> where([es], es.received_at >= ^cutoff_date)
    |> order_by([es], desc: es.received_at)
    |> Repo.all()
  end

  @doc """
  Lists unread email summaries for a user.
  """
  def list_unread_email_summaries(user) do
    EmailSummary
    |> where([es], es.user_id == ^user.id)
    |> where([es], es.is_read == false)
    |> order_by([es], desc: es.received_at)
    |> Repo.all()
  end

  @doc """
  Calculates average response time for a user's read emails.
  """
  def calculate_average_response_time(user) do
    result =
      EmailSummary
      |> where([es], es.user_id == ^user.id)
      |> where([es], es.is_read == true)
      |> where([es], not is_nil(es.response_time_hours))
      |> Repo.aggregate(:avg, :response_time_hours)

    case result do
      %Decimal{} = decimal -> Decimal.to_float(decimal)
      nil -> nil
      float when is_float(float) -> float
    end
  end

  @doc """
  Calculates comprehensive productivity statistics for a user's emails.
  """
  def calculate_email_productivity_stats(user) do
    base_query = EmailSummary |> where([es], es.user_id == ^user.id)

    total_emails = Repo.aggregate(base_query, :count)

    urgent_important_count =
      base_query
      |> where([es], es.classification == :urgent_important)
      |> Repo.aggregate(:count)

    digital_noise_count =
      base_query
      |> where([es], es.classification == :digital_noise)
      |> Repo.aggregate(:count)

    average_importance_score =
      base_query
      |> where([es], not is_nil(es.importance_score))
      |> Repo.aggregate(:avg, :importance_score)

    high_task_potential_count =
      base_query
      |> where([es], es.task_potential >= 0.7)
      |> Repo.aggregate(:count)

    average_task_potential =
      base_query
      |> where([es], not is_nil(es.task_potential))
      |> Repo.aggregate(:avg, :task_potential)

    # Helper function to convert Decimal to Float
    to_float = fn
      %Decimal{} = decimal -> Decimal.to_float(decimal)
      nil -> nil
      float when is_float(float) -> float
    end

    %{
      total_emails: total_emails,
      urgent_important_count: urgent_important_count,
      digital_noise_count: digital_noise_count,
      average_importance_score:
        case to_float.(average_importance_score) do
          nil -> nil
          float -> Float.round(float, 1)
        end,
      high_task_potential_count: high_task_potential_count,
      average_task_potential:
        case to_float.(average_task_potential) do
          nil -> nil
          float -> Float.round(float, 1)
        end
    }
  end
end
