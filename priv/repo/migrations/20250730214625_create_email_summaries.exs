defmodule Neptuner.Repo.Migrations.CreateEmailSummaries do
  use Ecto.Migration

  def change do
    create table(:email_summaries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string, null: false, size: 500
      add :sender_email, :string, null: false
      add :sender_name, :string
      add :body_preview, :text
      add :received_at, :utc_datetime, null: false
      add :is_read, :boolean, default: false, null: false
      add :response_time_hours, :integer
      add :time_spent_minutes, :integer
      add :importance_score, :integer
      add :classification, :string, null: false, default: "digital_noise"
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:email_summaries, [:user_id])
    create index(:email_summaries, [:user_id, :classification])
    create index(:email_summaries, [:user_id, :received_at])
    create index(:email_summaries, [:sender_email])
  end
end
