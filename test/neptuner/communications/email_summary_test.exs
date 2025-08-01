defmodule Neptuner.Communications.EmailSummaryTest do
  use Neptuner.DataCase, async: true

  alias Neptuner.Communications.EmailSummary
  import Neptuner.Factory

  describe "changeset/2" do
    test "valid changeset with required fields" do
      received_time = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        subject: "Test email subject",
        sender_email: "sender@example.com",
        received_at: received_time
      }

      changeset = EmailSummary.changeset(%EmailSummary{}, attrs)

      assert changeset.valid?
      assert changeset.changes.subject == "Test email subject"
      assert changeset.changes.sender_email == "sender@example.com"
      assert changeset.changes.received_at == received_time
    end

    test "valid changeset with all fields" do
      user = insert(:user)
      received_time = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        subject: "Complete project review",
        sender_email: "project@company.com",
        sender_name: "Project Manager",
        body_preview: "Please review the project deliverables by Friday.",
        received_at: received_time,
        is_read: false,
        response_time_hours: 24,
        time_spent_minutes: 15,
        importance_score: 8,
        classification: :urgent_important,

        # Gmail API specific fields
        external_id: "gmail_12345",
        from_emails: ["project@company.com"],
        to_emails: ["user@company.com"],
        cc_emails: ["manager@company.com"],
        from_domain: "company.com",
        thread_position: "first",
        is_sent: false,
        word_count: 150,
        has_attachments: true,
        labels: ["inbox", "important"],
        external_thread_id: "thread_567",
        synced_at: received_time,

        # Advanced analysis fields
        sentiment_analysis: %{"positive" => 0.7, "negative" => 0.1, "neutral" => 0.2},
        email_intent: "request",
        urgency_analysis: %{"urgency_score" => 0.8, "keywords" => ["deadline", "urgent"]},
        meeting_potential: %{"score" => 0.3, "indicators" => []},
        action_items: %{"items" => ["Review document", "Provide feedback"], "count" => 2},
        productivity_impact: %{"impact_score" => 0.8, "time_saved_minutes" => 30},
        cosmic_insights: %{
          "wisdom" => "This email actually contains useful information",
          "level" => 8
        },

        # Email-to-task extraction fields
        task_potential: 0.9,
        suggested_tasks: %{
          "tasks" => [
            %{"title" => "Review project deliverables", "priority" => "high"},
            %{"title" => "Schedule feedback meeting", "priority" => "medium"}
          ]
        },
        productivity_theater_score: 0.1,
        cosmic_action_wisdom: "Act swiftly, for this email demands real action",
        auto_create_recommended: true,
        tasks_created_count: 2,
        last_task_extraction_at: received_time,
        user_id: user.id
      }

      changeset = EmailSummary.changeset(%EmailSummary{}, attrs)

      assert changeset.valid?
      assert changeset.changes.classification == :urgent_important
      assert changeset.changes.task_potential == 0.9
      assert changeset.changes.auto_create_recommended == true
    end

    test "requires subject, sender_email, and received_at" do
      changeset = EmailSummary.changeset(%EmailSummary{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).subject
      assert "can't be blank" in errors_on(changeset).sender_email
      assert "can't be blank" in errors_on(changeset).received_at
    end

    test "validates subject length" do
      long_subject = String.duplicate("a", 501)

      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: long_subject,
          sender_email: "test@example.com",
          received_at: DateTime.utc_now()
        })

      refute changeset.valid?
      assert "should be at most 500 character(s)" in errors_on(changeset).subject
    end

    test "validates sender_email length" do
      long_email = String.duplicate("a", 250) <> "@example.com"

      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: long_email,
          received_at: DateTime.utc_now()
        })

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).sender_email
    end

    test "validates sender_name length" do
      long_name = String.duplicate("a", 256)

      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          sender_name: long_name,
          received_at: DateTime.utc_now()
        })

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).sender_name
    end

    test "validates body_preview length" do
      long_preview = String.duplicate("a", 1001)

      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          body_preview: long_preview,
          received_at: DateTime.utc_now()
        })

      refute changeset.valid?
      assert "should be at most 1000 character(s)" in errors_on(changeset).body_preview
    end

    test "validates sender_email format" do
      invalid_emails = [
        "invalid-email",
        "@example.com",
        "test@",
        "test@.com",
        "test@domain",
        "test test@example.com"
      ]

      for invalid_email <- invalid_emails do
        changeset =
          EmailSummary.changeset(%EmailSummary{}, %{
            subject: "Test",
            sender_email: invalid_email,
            received_at: DateTime.utc_now()
          })

        refute changeset.valid?
        assert "must be a valid email" in errors_on(changeset).sender_email
      end
    end

    test "accepts valid email formats" do
      valid_emails = [
        "test@example.com",
        "user.name@domain.com",
        "user+tag@example.org",
        "user123@test-domain.co.uk"
      ]

      for valid_email <- valid_emails do
        changeset =
          EmailSummary.changeset(%EmailSummary{}, %{
            subject: "Test",
            sender_email: valid_email,
            received_at: DateTime.utc_now()
          })

        assert changeset.valid?
      end
    end

    test "validates response_time_hours is positive" do
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          response_time_hours: 0
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).response_time_hours
    end

    test "validates time_spent_minutes is positive" do
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          time_spent_minutes: -5
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).time_spent_minutes
    end

    test "validates importance_score range (1-10)" do
      # Test below range
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          importance_score: 0
        })

      refute changeset.valid?
      assert "must be greater than or equal to 1" in errors_on(changeset).importance_score

      # Test above range
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          importance_score: 11
        })

      refute changeset.valid?
      assert "must be less than or equal to 10" in errors_on(changeset).importance_score

      # Test valid range
      for score <- 1..10 do
        changeset =
          EmailSummary.changeset(%EmailSummary{}, %{
            subject: "Test",
            sender_email: "test@example.com",
            received_at: DateTime.utc_now(),
            importance_score: score
          })

        assert changeset.valid?
      end
    end

    test "validates task_potential range (0.0-1.0)" do
      # Test below range
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          task_potential: -0.1
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0.0" in errors_on(changeset).task_potential

      # Test above range
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          task_potential: 1.1
        })

      refute changeset.valid?
      assert "must be less than or equal to 1.0" in errors_on(changeset).task_potential

      # Test valid range
      valid_scores = [0.0, 0.5, 1.0]

      for score <- valid_scores do
        changeset =
          EmailSummary.changeset(%EmailSummary{}, %{
            subject: "Test",
            sender_email: "test@example.com",
            received_at: DateTime.utc_now(),
            task_potential: score
          })

        assert changeset.valid?
      end
    end

    test "validates productivity_theater_score range (0.0-1.0)" do
      # Test below range
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          productivity_theater_score: -0.1
        })

      refute changeset.valid?

      assert "must be greater than or equal to 0.0" in errors_on(changeset).productivity_theater_score

      # Test above range
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          productivity_theater_score: 1.1
        })

      refute changeset.valid?

      assert "must be less than or equal to 1.0" in errors_on(changeset).productivity_theater_score
    end

    test "validates tasks_created_count is non-negative" do
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now(),
          tasks_created_count: -1
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).tasks_created_count
    end

    test "validates classification enum values" do
      valid_classifications = [
        :urgent_important,
        :urgent_unimportant,
        :not_urgent_important,
        :digital_noise
      ]

      for classification <- valid_classifications do
        changeset =
          EmailSummary.changeset(%EmailSummary{}, %{
            subject: "Test",
            sender_email: "test@example.com",
            received_at: DateTime.utc_now(),
            classification: classification
          })

        assert changeset.valid?
      end
    end

    test "sets default values correctly" do
      changeset =
        EmailSummary.changeset(%EmailSummary{}, %{
          subject: "Test",
          sender_email: "test@example.com",
          received_at: DateTime.utc_now()
        })

      email_summary = apply_changes(changeset)

      assert email_summary.is_read == false
      assert email_summary.classification == :digital_noise
      assert email_summary.from_emails == []
      assert email_summary.to_emails == []
      assert email_summary.cc_emails == []
      assert email_summary.is_sent == false
      assert email_summary.has_attachments == false
      assert email_summary.labels == []
      assert email_summary.auto_create_recommended == false
      assert email_summary.tasks_created_count == 0
    end
  end

  describe "classification_display_name/1" do
    test "returns correct display names for all classifications" do
      assert EmailSummary.classification_display_name(:urgent_important) == "Urgent & Important"

      assert EmailSummary.classification_display_name(:urgent_unimportant) ==
               "Urgent but Unimportant"

      assert EmailSummary.classification_display_name(:not_urgent_important) ==
               "Important but Not Urgent"

      assert EmailSummary.classification_display_name(:digital_noise) == "Digital Noise"
    end
  end

  describe "classification_description/1" do
    test "returns correct descriptions for all classifications" do
      assert EmailSummary.classification_description(:urgent_important) ==
               "Actually requires immediate attention and has real consequences"

      assert EmailSummary.classification_description(:urgent_unimportant) ==
               "Screams for attention but ultimately meaningless in the grand scheme"

      assert EmailSummary.classification_description(:not_urgent_important) ==
               "Significant but can be thoughtfully addressed when ready"

      assert EmailSummary.classification_description(:digital_noise) ==
               "The endless digital chatter that fills our inboxes and souls with existential dread"
    end
  end

  describe "classification_color/1" do
    test "returns correct colors for all classifications" do
      assert EmailSummary.classification_color(:urgent_important) == "red"
      assert EmailSummary.classification_color(:urgent_unimportant) == "orange"
      assert EmailSummary.classification_color(:not_urgent_important) == "blue"
      assert EmailSummary.classification_color(:digital_noise) == "gray"
    end
  end

  describe "productivity_score_description/1" do
    test "returns correct descriptions for all scores 1-10" do
      assert EmailSummary.productivity_score_description(1) ==
               "Cosmic waste of time - pure digital noise"

      assert EmailSummary.productivity_score_description(2) ==
               "Slightly above meaningless chatter"

      assert EmailSummary.productivity_score_description(3) == "Mildly relevant to your existence"

      assert EmailSummary.productivity_score_description(4) ==
               "Has some merit in the vast emptiness"

      assert EmailSummary.productivity_score_description(5) ==
               "Moderately useful for your daily grind"

      assert EmailSummary.productivity_score_description(6) ==
               "Actually contains actionable information"

      assert EmailSummary.productivity_score_description(7) == "Genuinely important for your work"

      assert EmailSummary.productivity_score_description(8) ==
               "High-value communication worth your time"

      assert EmailSummary.productivity_score_description(9) ==
               "Critical information that moves things forward"

      assert EmailSummary.productivity_score_description(10) ==
               "Pure productivity gold - rare as enlightenment"
    end

    test "returns default description for unscored emails" do
      assert EmailSummary.productivity_score_description(0) ==
               "Unscored - awaiting cosmic judgment"

      assert EmailSummary.productivity_score_description(11) ==
               "Unscored - awaiting cosmic judgment"

      assert EmailSummary.productivity_score_description(nil) ==
               "Unscored - awaiting cosmic judgment"
    end
  end

  describe "database integration" do
    test "can insert and retrieve email summary with all fields" do
      user = insert(:user)

      email_summary =
        insert(:email_summary,
          user: user,
          subject: "Database integration test",
          classification: :urgent_important,
          task_potential: 0.8,
          productivity_theater_score: 0.2
        )

      retrieved = Repo.get!(EmailSummary, email_summary.id) |> Repo.preload(:user)

      assert retrieved.subject == "Database integration test"
      assert retrieved.classification == :urgent_important
      assert retrieved.task_potential == 0.8
      assert retrieved.productivity_theater_score == 0.2
      assert retrieved.user.id == user.id
    end

    test "belongs_to user association works correctly" do
      user = insert(:user)
      email_summary = insert(:email_summary, user: user)

      retrieved = Repo.get!(EmailSummary, email_summary.id) |> Repo.preload(:user)

      assert retrieved.user.id == user.id
      assert retrieved.user.email == user.email
    end

    test "deleting user cascades to email summaries" do
      user = insert(:user)
      email_summary = insert(:email_summary, user: user)

      assert Repo.get(EmailSummary, email_summary.id)

      Repo.delete!(user)

      refute Repo.get(EmailSummary, email_summary.id)
    end

    test "can handle complex map fields" do
      complex_analysis = %{
        "sentiment" => %{
          "positive" => 0.7,
          "negative" => 0.1,
          "neutral" => 0.2,
          "keywords" => ["great", "excellent", "amazing"]
        },
        "entities" => [
          %{"type" => "person", "name" => "John Doe"},
          %{"type" => "organization", "name" => "Acme Corp"}
        ]
      }

      email_summary = insert(:email_summary, sentiment_analysis: complex_analysis)
      retrieved = Repo.get!(EmailSummary, email_summary.id)

      assert retrieved.sentiment_analysis == complex_analysis
    end

    test "can handle array fields" do
      labels = ["inbox", "important", "work", "project-alpha"]
      from_emails = ["sender1@example.com", "sender2@example.com"]
      cc_emails = ["cc1@example.com", "cc2@example.com", "cc3@example.com"]

      email_summary =
        insert(:email_summary,
          labels: labels,
          from_emails: from_emails,
          cc_emails: cc_emails
        )

      retrieved = Repo.get!(EmailSummary, email_summary.id)

      assert retrieved.labels == labels
      assert retrieved.from_emails == from_emails
      assert retrieved.cc_emails == cc_emails
    end
  end

  describe "factory variants" do
    test "urgent_important_email factory creates correct classification" do
      email = build(:urgent_important_email)

      assert email.classification == :urgent_important
      assert email.importance_score >= 8
      assert email.importance_score <= 10
    end

    test "digital_noise_email factory creates correct classification" do
      email = build(:digital_noise_email)

      assert email.classification == :digital_noise
      assert email.importance_score >= 1
      assert email.importance_score <= 3
    end

    test "high_task_potential_email factory creates actionable email" do
      email = build(:high_task_potential_email)

      assert email.task_potential >= 0.7
      assert email.auto_create_recommended == true
      assert length(email.suggested_tasks["tasks"]) > 0
    end

    test "low_task_potential_email factory creates non-actionable email" do
      email = build(:low_task_potential_email)

      assert email.task_potential <= 0.3
      assert email.auto_create_recommended == false
      assert email.suggested_tasks["tasks"] == []
    end

    test "meeting_potential_email factory suggests meetings" do
      email = build(:meeting_potential_email)

      assert email.meeting_potential["score"] >= 0.7
      assert email.email_intent == "meeting"
      assert length(email.meeting_potential["indicators"]) > 0
    end

    test "gmail_email factory has correct Gmail-specific fields" do
      email = build(:gmail_email)

      assert String.starts_with?(email.external_id, "gmail_")
      assert email.has_attachments == true
      assert "inbox" in email.labels
      assert email.thread_position == "first"
    end

    test "unread_email factory creates unread email" do
      email = build(:unread_email)

      assert email.is_read == false
    end

    test "read_email factory creates read email with response data" do
      email = build(:read_email)

      assert email.is_read == true
      assert email.response_time_hours > 0
      assert email.time_spent_minutes > 0
    end
  end
end
