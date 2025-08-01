defmodule Neptuner.Repo.Migrations.AddDueDateToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :due_date, :date
    end

    create index(:tasks, [:due_date])
  end
end
