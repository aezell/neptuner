defmodule Neptuner.Calendar.Meeting do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Accounts.User
  alias Neptuner.Connections.ServiceConnection

  schema "meetings" do
    field :external_calendar_id, :string
    field :title, :string
    field :duration_minutes, :integer
    field :attendee_count, :integer, default: 0
    field :could_have_been_email, :boolean, default: true
    field :actual_productivity_score, :integer

    field :meeting_type, Ecto.Enum,
      values: [:standup, :all_hands, :one_on_one, :brainstorm, :status_update, :other],
      default: :other

    field :scheduled_at, :utc_datetime
    field :synced_at, :utc_datetime

    belongs_to :user, User
    belongs_to :service_connection, ServiceConnection

    timestamps(type: :utc_datetime)
  end

  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [
      :external_calendar_id,
      :title,
      :duration_minutes,
      :attendee_count,
      :could_have_been_email,
      :actual_productivity_score,
      :meeting_type,
      :scheduled_at,
      :synced_at
    ])
    |> validate_required([:title, :scheduled_at])
    |> validate_length(:title, min: 1, max: 500)
    |> validate_number(:duration_minutes, greater_than: 0)
    |> validate_number(:attendee_count, greater_than_or_equal_to: 0)
    |> validate_inclusion(:actual_productivity_score, 1..10)
  end

  def meeting_type_description(:standup),
    do: "Today's episode of 'People Reading Lists at Each Other'"

  def meeting_type_description(:all_hands),
    do: "Company-wide sharing of information that will be immediately forgotten"

  def meeting_type_description(:one_on_one),
    do: "Bilateral confirmation that everything is 'fine' and 'on track'"

  def meeting_type_description(:brainstorm),
    do: "Collective generation of ideas that will die in Slack threads"

  def meeting_type_description(:status_update),
    do: "Ceremonial reading of project statuses that could have been a dashboard"

  def meeting_type_description(:other),
    do: "Unclassified gathering of humans in digital or physical space"

  def productivity_score_description(nil), do: "Awaiting cosmic evaluation"

  def productivity_score_description(1),
    do: "Pure performance art - no actionable outcomes detected"

  def productivity_score_description(2),
    do: "Mostly theater with trace amounts of information exchange"

  def productivity_score_description(3), do: "Some content buried beneath social rituals"

  def productivity_score_description(4),
    do: "Mildly productive despite best efforts to avoid decisions"

  def productivity_score_description(5),
    do: "Average meeting - some progress between the pleasantries"

  def productivity_score_description(6),
    do: "Above average - actual work emerged from the discussion"

  def productivity_score_description(7),
    do: "Surprisingly effective - concrete actions identified"

  def productivity_score_description(8), do: "Highly productive - clear outcomes and next steps"

  def productivity_score_description(9),
    do: "Exceptional efficiency - accomplished more than expected"

  def productivity_score_description(10),
    do: "Transcendent - the meeting achieved its platonic ideal"

  def could_have_been_email_percentage(meetings) when is_list(meetings) do
    if length(meetings) == 0 do
      0
    else
      email_meetings = Enum.count(meetings, & &1.could_have_been_email)
      round(email_meetings / length(meetings) * 100)
    end
  end
end
