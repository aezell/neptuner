defmodule Neptuner.Achievements.Achievement do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Achievements.UserAchievement

  schema "achievements" do
    field :key, :string
    field :title, :string
    field :description, :string
    field :ironic_description, :string
    field :category, :string
    field :icon, :string, default: "hero-trophy"
    field :color, :string, default: "yellow"
    field :threshold_value, :integer
    field :threshold_type, :string
    field :is_active, :boolean, default: true

    has_many :user_achievements, UserAchievement, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def changeset(achievement, attrs) do
    achievement
    |> cast(attrs, [
      :key,
      :title,
      :description,
      :ironic_description,
      :category,
      :icon,
      :color,
      :threshold_value,
      :threshold_type,
      :is_active
    ])
    |> validate_required([:key, :title, :description, :category])
    |> unique_constraint(:key)
    |> validate_inclusion(:category, [
      "tasks",
      "habits",
      "meetings",
      "emails",
      "connections",
      "productivity_theater"
    ])
    |> validate_inclusion(
      :threshold_type,
      [
        "count",
        "streak",
        "percentage",
        "hours",
        "ratio"
      ],
      message: "must be a valid threshold type"
    )
  end

  def category_display_name("tasks"), do: "Task Management"
  def category_display_name("habits"), do: "Habit Tracking"
  def category_display_name("meetings"), do: "Meeting Survival"
  def category_display_name("emails"), do: "Email Archaeology"
  def category_display_name("connections"), do: "Digital Integration"
  def category_display_name("productivity_theater"), do: "Productivity Theater"
  def category_display_name(_), do: "General"

  def color_class("red"), do: "text-error"
  def color_class("yellow"), do: "text-warning"
  def color_class("green"), do: "text-success"
  def color_class("blue"), do: "text-info"
  def color_class("purple"), do: "text-secondary"
  def color_class(_), do: "text-primary"

  def badge_class("red"), do: "badge-error"
  def badge_class("yellow"), do: "badge-warning"
  def badge_class("green"), do: "badge-success"
  def badge_class("blue"), do: "badge-info"
  def badge_class("purple"), do: "badge-secondary"
  def badge_class(_), do: "badge-primary"
end
