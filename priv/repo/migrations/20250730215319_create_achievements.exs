defmodule Neptuner.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :title, :string, null: false
      add :description, :text, null: false
      add :ironic_description, :text
      add :category, :string, null: false
      add :icon, :string, default: "hero-trophy"
      add :color, :string, default: "yellow"
      add :threshold_value, :integer
      add :threshold_type, :string
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:achievements, [:key])
    create index(:achievements, [:category])
    create index(:achievements, [:is_active])

    create table(:user_achievements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      add :achievement_id, references(:achievements, on_delete: :delete_all, type: :binary_id),
        null: false

      add :progress_value, :integer, default: 0
      add :completed_at, :utc_datetime
      add :notified_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:user_achievements, [:user_id])
    create index(:user_achievements, [:achievement_id])
    create index(:user_achievements, [:user_id, :completed_at])
    create unique_index(:user_achievements, [:user_id, :achievement_id])
  end
end
