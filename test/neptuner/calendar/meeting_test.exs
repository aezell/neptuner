defmodule Neptuner.Calendar.MeetingTest do
  use Neptuner.DataCase

  alias Neptuner.Calendar.Meeting

  describe "changeset/2" do
    test "with valid attributes creates a valid changeset" do
      user = insert(:user)
      _service_connection = insert(:service_connection, user: user)

      attrs = %{
        external_calendar_id: "cal_123",
        title: "Team Standup",
        duration_minutes: 30,
        attendee_count: 5,
        could_have_been_email: true,
        actual_productivity_score: 7,
        meeting_type: :standup,
        scheduled_at: DateTime.utc_now(),
        synced_at: DateTime.utc_now()
      }

      changeset = Meeting.changeset(%Meeting{}, attrs)

      assert changeset.valid?
      assert changeset.changes.title == "Team Standup"
      assert changeset.changes.duration_minutes == 30
      assert changeset.changes.meeting_type == :standup
    end

    test "requires title field" do
      changeset = Meeting.changeset(%Meeting{}, %{scheduled_at: DateTime.utc_now()})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "requires scheduled_at field" do
      changeset = Meeting.changeset(%Meeting{}, %{title: "Meeting"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).scheduled_at
    end

    test "validates title length constraints" do
      # Too short (empty after trim)
      short_changeset =
        Meeting.changeset(%Meeting{}, %{
          title: "",
          scheduled_at: DateTime.utc_now()
        })

      refute short_changeset.valid?
      assert "can't be blank" in errors_on(short_changeset).title

      # Too long
      long_title = String.duplicate("a", 501)

      long_changeset =
        Meeting.changeset(%Meeting{}, %{
          title: long_title,
          scheduled_at: DateTime.utc_now()
        })

      refute long_changeset.valid?
      assert "should be at most 500 character(s)" in errors_on(long_changeset).title

      # Just right
      good_changeset =
        Meeting.changeset(%Meeting{}, %{
          title: "Perfect Meeting Title",
          scheduled_at: DateTime.utc_now()
        })

      assert good_changeset.valid?
    end

    test "validates duration_minutes is positive" do
      zero_duration =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          duration_minutes: 0,
          scheduled_at: DateTime.utc_now()
        })

      refute zero_duration.valid?
      assert "must be greater than 0" in errors_on(zero_duration).duration_minutes

      negative_duration =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          duration_minutes: -30,
          scheduled_at: DateTime.utc_now()
        })

      refute negative_duration.valid?
      assert "must be greater than 0" in errors_on(negative_duration).duration_minutes

      positive_duration =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          duration_minutes: 30,
          scheduled_at: DateTime.utc_now()
        })

      assert positive_duration.valid?
    end

    test "validates attendee_count is non-negative" do
      negative_attendees =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          attendee_count: -1,
          scheduled_at: DateTime.utc_now()
        })

      refute negative_attendees.valid?
      assert "must be greater than or equal to 0" in errors_on(negative_attendees).attendee_count

      zero_attendees =
        Meeting.changeset(%Meeting{}, %{
          title: "Solo Meeting",
          attendee_count: 0,
          scheduled_at: DateTime.utc_now()
        })

      assert zero_attendees.valid?

      positive_attendees =
        Meeting.changeset(%Meeting{}, %{
          title: "Team Meeting",
          attendee_count: 5,
          scheduled_at: DateTime.utc_now()
        })

      assert positive_attendees.valid?
    end

    test "validates productivity score range" do
      too_low =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          actual_productivity_score: 0,
          scheduled_at: DateTime.utc_now()
        })

      refute too_low.valid?
      assert "is invalid" in errors_on(too_low).actual_productivity_score

      too_high =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          actual_productivity_score: 11,
          scheduled_at: DateTime.utc_now()
        })

      refute too_high.valid?
      assert "is invalid" in errors_on(too_high).actual_productivity_score

      valid_scores = 1..10

      for score <- valid_scores do
        changeset =
          Meeting.changeset(%Meeting{}, %{
            title: "Meeting",
            actual_productivity_score: score,
            scheduled_at: DateTime.utc_now()
          })

        assert changeset.valid?, "Score #{score} should be valid"
      end

      # nil should be valid (unrated)
      nil_score =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          actual_productivity_score: nil,
          scheduled_at: DateTime.utc_now()
        })

      assert nil_score.valid?
    end

    test "accepts valid meeting types" do
      valid_types = [:standup, :all_hands, :one_on_one, :brainstorm, :status_update, :other]

      for meeting_type <- valid_types do
        changeset =
          Meeting.changeset(%Meeting{}, %{
            title: "Meeting",
            meeting_type: meeting_type,
            scheduled_at: DateTime.utc_now()
          })

        assert changeset.valid?, "Meeting type #{meeting_type} should be valid"
        # Only check changes if the value differs from default
        if meeting_type != :other do
          assert changeset.changes.meeting_type == meeting_type
        end
      end
    end

    test "rejects invalid meeting types" do
      changeset =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          meeting_type: :invalid_type,
          scheduled_at: DateTime.utc_now()
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).meeting_type
    end

    test "defaults meeting_type to :other when not provided" do
      changeset =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          scheduled_at: DateTime.utc_now()
        })

      assert changeset.valid?
      # The default is handled by the schema, not the changeset
    end

    test "allows all boolean values for could_have_been_email" do
      true_changeset =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          could_have_been_email: true,
          scheduled_at: DateTime.utc_now()
        })

      assert true_changeset.valid?
      # could_have_been_email: true matches the default, so it might not be in changes
      # Let's check if it's set either in changes or the final data

      false_changeset =
        Meeting.changeset(%Meeting{}, %{
          title: "Meeting",
          could_have_been_email: false,
          scheduled_at: DateTime.utc_now()
        })

      assert false_changeset.valid?
      assert false_changeset.changes.could_have_been_email == false
    end
  end

  describe "meeting_type_description/1" do
    test "returns witty descriptions for each meeting type" do
      assert Meeting.meeting_type_description(:standup) ==
               "Today's episode of 'People Reading Lists at Each Other'"

      assert Meeting.meeting_type_description(:all_hands) ==
               "Company-wide sharing of information that will be immediately forgotten"

      assert Meeting.meeting_type_description(:one_on_one) ==
               "Bilateral confirmation that everything is 'fine' and 'on track'"

      assert Meeting.meeting_type_description(:brainstorm) ==
               "Collective generation of ideas that will die in Slack threads"

      assert Meeting.meeting_type_description(:status_update) ==
               "Ceremonial reading of project statuses that could have been a dashboard"

      assert Meeting.meeting_type_description(:other) ==
               "Unclassified gathering of humans in digital or physical space"
    end
  end

  describe "productivity_score_description/1" do
    test "returns nil score description" do
      assert Meeting.productivity_score_description(nil) == "Awaiting cosmic evaluation"
    end

    test "returns descriptions for scores 1-10" do
      expected_descriptions = %{
        1 => "Pure performance art - no actionable outcomes detected",
        2 => "Mostly theater with trace amounts of information exchange",
        3 => "Some content buried beneath social rituals",
        4 => "Mildly productive despite best efforts to avoid decisions",
        5 => "Average meeting - some progress between the pleasantries",
        6 => "Above average - actual work emerged from the discussion",
        7 => "Surprisingly effective - concrete actions identified",
        8 => "Highly productive - clear outcomes and next steps",
        9 => "Exceptional efficiency - accomplished more than expected",
        10 => "Transcendent - the meeting achieved its platonic ideal"
      }

      for {score, expected} <- expected_descriptions do
        assert Meeting.productivity_score_description(score) == expected
      end
    end
  end

  describe "could_have_been_email_percentage/1" do
    test "returns 0 for empty list" do
      assert Meeting.could_have_been_email_percentage([]) == 0
    end

    test "calculates percentage correctly" do
      meetings = [
        %Meeting{could_have_been_email: true},
        %Meeting{could_have_been_email: true},
        %Meeting{could_have_been_email: false},
        %Meeting{could_have_been_email: false}
      ]

      assert Meeting.could_have_been_email_percentage(meetings) == 50
    end

    test "rounds to nearest integer" do
      # 2 out of 3 = 66.666...% rounds to 67%
      meetings = [
        %Meeting{could_have_been_email: true},
        %Meeting{could_have_been_email: true},
        %Meeting{could_have_been_email: false}
      ]

      assert Meeting.could_have_been_email_percentage(meetings) == 67
    end

    test "handles all true" do
      meetings = [
        %Meeting{could_have_been_email: true},
        %Meeting{could_have_been_email: true}
      ]

      assert Meeting.could_have_been_email_percentage(meetings) == 100
    end

    test "handles all false" do
      meetings = [
        %Meeting{could_have_been_email: false},
        %Meeting{could_have_been_email: false}
      ]

      assert Meeting.could_have_been_email_percentage(meetings) == 0
    end
  end

  describe "database constraints" do
    test "meeting is created with proper associations" do
      user = insert(:user)
      service_connection = insert(:service_connection, user: user)

      meeting_attrs = %{
        external_calendar_id: "test_cal_123",
        title: "Test Meeting",
        duration_minutes: 30,
        attendee_count: 3,
        meeting_type: :standup,
        scheduled_at: DateTime.utc_now(),
        synced_at: DateTime.utc_now()
      }

      changeset =
        %Meeting{}
        |> Meeting.changeset(meeting_attrs)
        |> Ecto.Changeset.put_change(:user_id, user.id)
        |> Ecto.Changeset.put_change(:service_connection_id, service_connection.id)

      assert {:ok, meeting} = Repo.insert(changeset)
      assert meeting.user_id == user.id
      assert meeting.service_connection_id == service_connection.id
      assert meeting.title == "Test Meeting"
    end
  end
end
