defmodule Neptuner.Repo.Migrations.AddUserOnboardingFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :onboarding_completed, :boolean, default: false
      add :onboarding_step, :string, default: "welcome"
      add :demo_data_generated, :boolean, default: false
      add :first_task_created, :boolean, default: false
      add :first_connection_made, :boolean, default: false
      add :dashboard_tour_completed, :boolean, default: false
      add :onboarding_started_at, :utc_datetime
      add :onboarding_completed_at, :utc_datetime
      add :activation_score, :integer, default: 0
    end

    create constraint(:users, :onboarding_step_check,
             check:
               "onboarding_step IN ('welcome', 'cosmic_setup', 'demo_data', 'first_connection', 'first_task', 'dashboard_tour', 'completed')"
           )
  end
end
