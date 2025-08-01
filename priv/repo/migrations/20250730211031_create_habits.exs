defmodule Neptuner.Repo.Migrations.CreateHabits do
  use Ecto.Migration

  def change do
    create table(:habits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :current_streak, :integer, default: 0
      add :longest_streak, :integer, default: 0
      add :habit_type, :string, default: "self_improvement_theater"
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:habits, [:user_id])
    create index(:habits, [:habit_type])

    create constraint(:habits, :habit_type_check,
             check:
               "habit_type IN ('basic_human_function', 'self_improvement_theater', 'actually_useful')"
           )

    create constraint(:habits, :streaks_non_negative,
             check: "current_streak >= 0 AND longest_streak >= 0"
           )
  end
end
