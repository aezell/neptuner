defmodule Neptuner.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :external_calendar_id, :string
      add :title, :string, null: false
      add :duration_minutes, :integer
      add :attendee_count, :integer, default: 0
      add :could_have_been_email, :boolean, default: true
      add :actual_productivity_score, :integer
      add :meeting_type, :string, default: "other"
      add :scheduled_at, :utc_datetime, null: false
      add :synced_at, :utc_datetime

      add :service_connection_id,
          references(:service_connections, on_delete: :delete_all, type: :binary_id),
          null: false

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:meetings, [:user_id])
    create index(:meetings, [:service_connection_id])
    create index(:meetings, [:scheduled_at])
    create index(:meetings, [:meeting_type])
    create index(:meetings, [:external_calendar_id])

    create constraint(:meetings, :meeting_type_check,
             check:
               "meeting_type IN ('standup', 'all_hands', 'one_on_one', 'brainstorm', 'status_update', 'other')"
           )

    create constraint(:meetings, :productivity_score_range,
             check:
               "actual_productivity_score IS NULL OR (actual_productivity_score >= 1 AND actual_productivity_score <= 10)"
           )

    create constraint(:meetings, :duration_positive,
             check: "duration_minutes IS NULL OR duration_minutes > 0"
           )

    create constraint(:meetings, :attendee_count_non_negative, check: "attendee_count >= 0")
  end
end
