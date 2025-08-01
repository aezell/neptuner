defmodule Neptuner.Communications.EmailSummary do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User

  schema "email_summaries" do
    field :subject, :string
    field :sender_email, :string
    field :sender_name, :string
    field :body_preview, :string
    field :received_at, :utc_datetime
    field :is_read, :boolean, default: false
    field :response_time_hours, :integer
    field :time_spent_minutes, :integer
    field :importance_score, :integer

    field :classification, Ecto.Enum,
      values: [:urgent_important, :urgent_unimportant, :not_urgent_important, :digital_noise],
      default: :digital_noise

    # Gmail API specific fields
    field :external_id, :string
    field :from_emails, {:array, :string}, default: []
    field :to_emails, {:array, :string}, default: []
    field :cc_emails, {:array, :string}, default: []
    field :from_domain, :string
    field :thread_position, :string
    field :is_sent, :boolean, default: false
    field :word_count, :integer
    field :has_attachments, :boolean, default: false
    field :labels, {:array, :string}, default: []
    field :external_thread_id, :string
    field :synced_at, :utc_datetime

    # Advanced analysis fields
    field :sentiment_analysis, :map
    field :email_intent, :string
    field :urgency_analysis, :map
    field :meeting_potential, :map
    field :action_items, :map
    field :productivity_impact, :map
    field :cosmic_insights, :map

    # Email-to-task extraction fields
    field :task_potential, :float
    field :suggested_tasks, :map
    field :productivity_theater_score, :float
    field :cosmic_action_wisdom, :string
    field :auto_create_recommended, :boolean, default: false
    field :tasks_created_count, :integer, default: 0
    field :last_task_extraction_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(email_summary, attrs) do
    email_summary
    |> cast(attrs, [
      :subject,
      :sender_email,
      :sender_name,
      :body_preview,
      :received_at,
      :is_read,
      :response_time_hours,
      :time_spent_minutes,
      :importance_score,
      :classification,
      # Gmail API specific fields
      :external_id,
      :from_emails,
      :to_emails,
      :cc_emails,
      :from_domain,
      :thread_position,
      :is_sent,
      :word_count,
      :has_attachments,
      :labels,
      :external_thread_id,
      :synced_at,
      # Advanced analysis fields
      :sentiment_analysis,
      :email_intent,
      :urgency_analysis,
      :meeting_potential,
      :action_items,
      :productivity_impact,
      :cosmic_insights,
      # Email-to-task extraction fields
      :task_potential,
      :suggested_tasks,
      :productivity_theater_score,
      :cosmic_action_wisdom,
      :auto_create_recommended,
      :tasks_created_count,
      :last_task_extraction_at
    ])
    |> validate_required([:subject, :sender_email, :received_at])
    |> validate_length(:subject, max: 500)
    |> validate_length(:sender_email, max: 255)
    |> validate_length(:sender_name, max: 255)
    |> validate_length(:body_preview, max: 1000)
    |> validate_format(:sender_email, ~r/^[^@\s]+@[^@\s]+\.[^@\s]+$/,
      message: "must be a valid email"
    )
    |> validate_number(:response_time_hours, greater_than: 0)
    |> validate_number(:time_spent_minutes, greater_than: 0)
    |> validate_number(:importance_score, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> validate_number(:task_potential, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_number(:productivity_theater_score,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 1.0
    )
    |> validate_number(:tasks_created_count, greater_than_or_equal_to: 0)
  end

  def classification_display_name(:urgent_important), do: "Urgent & Important"
  def classification_display_name(:urgent_unimportant), do: "Urgent but Unimportant"
  def classification_display_name(:not_urgent_important), do: "Important but Not Urgent"
  def classification_display_name(:digital_noise), do: "Digital Noise"

  def classification_description(:urgent_important) do
    "Actually requires immediate attention and has real consequences"
  end

  def classification_description(:urgent_unimportant) do
    "Screams for attention but ultimately meaningless in the grand scheme"
  end

  def classification_description(:not_urgent_important) do
    "Significant but can be thoughtfully addressed when ready"
  end

  def classification_description(:digital_noise) do
    "The endless digital chatter that fills our inboxes and souls with existential dread"
  end

  def classification_color(:urgent_important), do: "red"
  def classification_color(:urgent_unimportant), do: "orange"
  def classification_color(:not_urgent_important), do: "blue"
  def classification_color(:digital_noise), do: "gray"

  def productivity_score_description(score) do
    case score do
      1 -> "Cosmic waste of time - pure digital noise"
      2 -> "Slightly above meaningless chatter"
      3 -> "Mildly relevant to your existence"
      4 -> "Has some merit in the vast emptiness"
      5 -> "Moderately useful for your daily grind"
      6 -> "Actually contains actionable information"
      7 -> "Genuinely important for your work"
      8 -> "High-value communication worth your time"
      9 -> "Critical information that moves things forward"
      10 -> "Pure productivity gold - rare as enlightenment"
      _ -> "Unscored - awaiting cosmic judgment"
    end
  end
end
