defmodule Neptuner.Repo.Migrations.AddPremiumFieldToAchievements do
  use Ecto.Migration

  def change do
    alter table(:achievements) do
      add :is_premium, :boolean, default: false, null: false
      add :premium_commentary, :text
    end

    # Premium achievements will be added via seeds.exs

    create index(:achievements, [:is_premium])
  end
end
