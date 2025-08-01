defmodule Neptuner.Achievements.UserAchievement do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User
  alias Neptuner.Achievements.Achievement

  schema "user_achievements" do
    field :progress_value, :integer, default: 0
    field :completed_at, :utc_datetime
    field :notified_at, :utc_datetime

    belongs_to :user, User
    belongs_to :achievement, Achievement

    timestamps(type: :utc_datetime)
  end

  def changeset(user_achievement, attrs) do
    user_achievement
    |> cast(attrs, [:progress_value, :completed_at, :notified_at])
    |> validate_required([])
    |> validate_number(:progress_value, greater_than_or_equal_to: 0)
    |> unique_constraint([:user_id, :achievement_id])
  end

  def completed?(%__MODULE__{completed_at: nil}), do: false
  def completed?(%__MODULE__{completed_at: _datetime}), do: true

  def notified?(%__MODULE__{notified_at: nil}), do: false
  def notified?(%__MODULE__{notified_at: _datetime}), do: true

  def progress_percentage(%__MODULE__{} = user_achievement, achievement) do
    if achievement.threshold_value && achievement.threshold_value > 0 do
      min(round(user_achievement.progress_value / achievement.threshold_value * 100), 100)
    else
      if completed?(user_achievement), do: 100, else: 0
    end
  end
end
