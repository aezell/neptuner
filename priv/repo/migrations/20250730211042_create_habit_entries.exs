defmodule Neptuner.Repo.Migrations.CreateHabitEntries do
  use Ecto.Migration

  def change do
    create table(:habit_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :completed_on, :date, null: false
      add :existential_commentary, :text
      add :habit_id, references(:habits, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:habit_entries, [:habit_id])
    create index(:habit_entries, [:completed_on])
    create unique_index(:habit_entries, [:habit_id, :completed_on])
  end
end
