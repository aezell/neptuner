defmodule Neptuner.Repo.Migrations.AddFrequencyToHabits do
  use Ecto.Migration

  def change do
    alter table(:habits) do
      add :frequency, :string, default: "daily"
    end

    create constraint(:habits, :frequency_check,
             check: "frequency IN ('daily', 'weekly', 'monthly')"
           )
  end
end
