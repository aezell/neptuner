defmodule Neptuner.Repo.Migrations.AddEmailToTaskFieldsToEmailSummaries do
  use Ecto.Migration

  def change do
    alter table(:email_summaries) do
      # Gmail API specific fields
      add :external_id, :string
      add :from_emails, {:array, :string}, default: []
      add :to_emails, {:array, :string}, default: []
      add :cc_emails, {:array, :string}, default: []
      add :from_domain, :string
      add :thread_position, :string
      add :is_sent, :boolean, default: false
      add :word_count, :integer
      add :has_attachments, :boolean, default: false
      add :labels, {:array, :string}, default: []
      add :external_thread_id, :string
      add :synced_at, :utc_datetime

      # Advanced analysis fields
      add :sentiment_analysis, :map
      add :email_intent, :string
      add :urgency_analysis, :map
      add :meeting_potential, :map
      add :action_items, :map
      add :productivity_impact, :map
      add :cosmic_insights, :map

      # Email-to-task extraction fields
      add :task_potential, :float
      add :suggested_tasks, :map
      add :productivity_theater_score, :float
      add :cosmic_action_wisdom, :text
      add :auto_create_recommended, :boolean, default: false
      add :tasks_created_count, :integer, default: 0
      add :last_task_extraction_at, :utc_datetime
    end

    create index(:email_summaries, [:external_id])
    create index(:email_summaries, [:user_id, :task_potential])
    create index(:email_summaries, [:user_id, :productivity_theater_score])
    create index(:email_summaries, [:user_id, :auto_create_recommended])
  end
end
