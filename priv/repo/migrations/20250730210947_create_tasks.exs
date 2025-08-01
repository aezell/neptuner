defmodule Neptuner.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :cosmic_priority, :string, default: "matters_to_nobody"
      add :status, :string, default: "pending"
      add :estimated_actual_importance, :integer, default: 1
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:user_id])
    create index(:tasks, [:status])
    create index(:tasks, [:cosmic_priority])

    create constraint(:tasks, :cosmic_priority_check,
             check:
               "cosmic_priority IN ('matters_10_years', 'matters_10_days', 'matters_to_nobody')"
           )

    create constraint(:tasks, :status_check,
             check: "status IN ('pending', 'completed', 'abandoned_wisely')"
           )

    create constraint(:tasks, :importance_range_check,
             check: "estimated_actual_importance >= 1 AND estimated_actual_importance <= 10"
           )
  end
end
