defmodule Neptuner.Repo.Migrations.AddNeptunerUserFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :cosmic_perspective_level, :string, default: "skeptical"
      add :total_meaningless_tasks_completed, :integer, default: 0
    end

    create constraint(:users, :cosmic_perspective_level_check,
             check: "cosmic_perspective_level IN ('skeptical', 'resigned', 'enlightened')"
           )
  end
end
