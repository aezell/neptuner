defmodule Neptuner.CommunicationsTest do
  use Neptuner.DataCase, async: true

  alias Neptuner.Communications
  alias Neptuner.Communications.EmailSummary
  import Neptuner.Factory

  describe "email_summaries" do
    test "list_email_summaries/0 returns all email summaries" do
      user = insert(:user)
      email1 = insert(:email_summary, user: user)
      email2 = insert(:email_summary, user: user)

      email_summaries = Communications.list_email_summaries()

      assert length(email_summaries) == 2
      assert Enum.any?(email_summaries, &(&1.id == email1.id))
      assert Enum.any?(email_summaries, &(&1.id == email2.id))
    end

    test "list_email_summaries_for_user/1 returns only user's email summaries" do
      user1 = insert(:user)
      user2 = insert(:user)

      email1 = insert(:email_summary, user: user1, subject: "User 1 Email")
      email2 = insert(:email_summary, user: user2, subject: "User 2 Email")
      _email3 = insert(:email_summary, user: user1, subject: "Another User 1 Email")

      user1_emails = Communications.list_email_summaries_for_user(user1)
      user2_emails = Communications.list_email_summaries_for_user(user2)

      assert length(user1_emails) == 2
      assert length(user2_emails) == 1

      assert Enum.any?(user1_emails, &(&1.id == email1.id))
      refute Enum.any?(user1_emails, &(&1.id == email2.id))
      assert Enum.any?(user2_emails, &(&1.id == email2.id))
    end

    test "get_email_summary!/1 returns the email summary with given id" do
      user = insert(:user)
      email = insert(:email_summary, user: user, subject: "Test Email")

      retrieved = Communications.get_email_summary!(email.id)

      assert retrieved.id == email.id
      assert retrieved.subject == "Test Email"
    end

    test "get_email_summary!/1 raises Ecto.NoResultsError when email summary not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Communications.get_email_summary!(Ecto.UUID.generate())
      end
    end

    test "create_email_summary/2 with valid data creates an email summary" do
      user = insert(:user)

      attrs = %{
        subject: "New Email",
        sender_email: "sender@example.com",
        received_at: DateTime.utc_now()
      }

      assert {:ok, %EmailSummary{} = email_summary} =
               Communications.create_email_summary(user.id, attrs)

      assert email_summary.subject == "New Email"
      assert email_summary.sender_email == "sender@example.com"
      assert email_summary.user_id == user.id
    end

    test "create_email_summary/2 with invalid data returns error changeset" do
      user = insert(:user)
      attrs = %{subject: nil, sender_email: "invalid-email"}

      assert {:error, %Ecto.Changeset{}} = Communications.create_email_summary(user.id, attrs)
    end

    test "update_email_summary/2 with valid data updates the email summary" do
      user = insert(:user)
      email_summary = insert(:email_summary, user: user, subject: "Original Subject")

      update_attrs = %{
        subject: "Updated Subject",
        importance_score: 9,
        classification: :urgent_important
      }

      assert {:ok, %EmailSummary{} = updated_email} =
               Communications.update_email_summary(email_summary, update_attrs)

      assert updated_email.subject == "Updated Subject"
      assert updated_email.importance_score == 9
      assert updated_email.classification == :urgent_important
    end

    test "update_email_summary/2 with invalid data returns error changeset" do
      user = insert(:user)
      email_summary = insert(:email_summary, user: user)

      update_attrs = %{sender_email: "invalid-email", importance_score: 15}

      assert {:error, %Ecto.Changeset{}} =
               Communications.update_email_summary(email_summary, update_attrs)

      # Ensure original data is unchanged
      unchanged = Communications.get_email_summary!(email_summary.id)
      assert unchanged.sender_email == email_summary.sender_email
      assert unchanged.importance_score == email_summary.importance_score
    end

    test "delete_email_summary/1 deletes the email summary" do
      user = insert(:user)
      email_summary = insert(:email_summary, user: user)

      assert {:ok, %EmailSummary{}} = Communications.delete_email_summary(email_summary)

      assert_raise Ecto.NoResultsError, fn ->
        Communications.get_email_summary!(email_summary.id)
      end
    end

    test "change_email_summary/1 returns an email summary changeset" do
      user = insert(:user)
      email_summary = insert(:email_summary, user: user)

      assert %Ecto.Changeset{} = Communications.change_email_summary(email_summary)
    end
  end

  describe "email classification filtering" do
    test "list_email_summaries_by_classification/2 filters by classification" do
      user = insert(:user)

      urgent_email = insert(:urgent_important_email, user: user)
      noise_email = insert(:digital_noise_email, user: user)
      important_email = insert(:not_urgent_important_email, user: user)

      urgent_results =
        Communications.list_email_summaries_by_classification(user, :urgent_important)

      noise_results = Communications.list_email_summaries_by_classification(user, :digital_noise)

      important_results =
        Communications.list_email_summaries_by_classification(user, :not_urgent_important)

      assert length(urgent_results) == 1
      assert List.first(urgent_results).id == urgent_email.id

      assert length(noise_results) == 1
      assert List.first(noise_results).id == noise_email.id

      assert length(important_results) == 1
      assert List.first(important_results).id == important_email.id
    end

    test "count_email_summaries_by_classification/2 returns correct counts" do
      user = insert(:user)

      insert_list(3, :urgent_important_email, user: user)
      insert_list(5, :digital_noise_email, user: user)
      insert_list(2, :not_urgent_important_email, user: user)

      urgent_count =
        Communications.count_email_summaries_by_classification(user, :urgent_important)

      noise_count = Communications.count_email_summaries_by_classification(user, :digital_noise)

      important_count =
        Communications.count_email_summaries_by_classification(user, :not_urgent_important)

      assert urgent_count == 3
      assert noise_count == 5
      assert important_count == 2
    end
  end

  describe "email task potential analysis" do
    test "list_high_task_potential_emails/2 returns emails with high task potential" do
      user = insert(:user)

      high_potential = insert(:high_task_potential_email, user: user, task_potential: 0.9)
      low_potential = insert(:low_task_potential_email, user: user, task_potential: 0.2)
      medium_potential = insert(:email_summary, user: user, task_potential: 0.6)

      # Test with threshold 0.7
      results = Communications.list_high_task_potential_emails(user, 0.7)

      assert length(results) == 1
      assert List.first(results).id == high_potential.id

      # Test with lower threshold 0.5
      results_lower = Communications.list_high_task_potential_emails(user, 0.5)

      assert length(results_lower) == 2
      email_ids = Enum.map(results_lower, & &1.id)
      assert high_potential.id in email_ids
      assert medium_potential.id in email_ids
      refute low_potential.id in email_ids
    end

    test "list_auto_create_recommended_emails/1 returns emails recommended for auto task creation" do
      user = insert(:user)

      recommended1 = insert(:email_summary, user: user, auto_create_recommended: true)
      # Factory sets auto_create_recommended: true
      recommended2 = insert(:high_task_potential_email, user: user)
      # Factory sets auto_create_recommended: false
      _not_recommended = insert(:low_task_potential_email, user: user)

      results = Communications.list_auto_create_recommended_emails(user)

      assert length(results) == 2
      email_ids = Enum.map(results, & &1.id)
      assert recommended1.id in email_ids
      assert recommended2.id in email_ids
    end
  end

  describe "productivity theater analysis" do
    test "list_high_productivity_theater_emails/2 returns emails with high theater scores" do
      user = insert(:user)

      high_theater = insert(:high_productivity_theater_email, user: user)
      low_theater = insert(:email_summary, user: user, productivity_theater_score: 0.1)
      medium_theater = insert(:email_summary, user: user, productivity_theater_score: 0.6)

      # Test with threshold 0.7
      results = Communications.list_high_productivity_theater_emails(user, 0.7)

      assert length(results) == 1
      assert List.first(results).id == high_theater.id

      # Test with lower threshold 0.5
      results_lower = Communications.list_high_productivity_theater_emails(user, 0.5)

      assert length(results_lower) == 2
      email_ids = Enum.map(results_lower, & &1.id)
      assert high_theater.id in email_ids
      assert medium_theater.id in email_ids
      refute low_theater.id in email_ids
    end
  end

  describe "email time-based queries" do
    test "list_recent_email_summaries/2 returns emails within specified days" do
      user = insert(:user)

      today = DateTime.utc_now() |> DateTime.truncate(:second)
      yesterday = DateTime.add(today, -1, :day)
      week_ago = DateTime.add(today, -7, :day)
      month_ago = DateTime.add(today, -30, :day)

      recent_email = insert(:email_summary, user: user, received_at: yesterday)
      old_email = insert(:email_summary, user: user, received_at: week_ago)
      very_old_email = insert(:email_summary, user: user, received_at: month_ago)

      # Test within 3 days
      recent_results = Communications.list_recent_email_summaries(user, 3)
      assert length(recent_results) == 1
      assert List.first(recent_results).id == recent_email.id

      # Test within 10 days
      broader_results = Communications.list_recent_email_summaries(user, 10)
      assert length(broader_results) == 2
      email_ids = Enum.map(broader_results, & &1.id)
      assert recent_email.id in email_ids
      assert old_email.id in email_ids
      refute very_old_email.id in email_ids
    end

    test "list_unread_email_summaries/1 returns only unread emails" do
      user = insert(:user)

      unread1 = insert(:unread_email, user: user, subject: "Unread 1")
      unread2 = insert(:unread_email, user: user, subject: "Unread 2")
      _read = insert(:read_email, user: user, subject: "Read Email")

      results = Communications.list_unread_email_summaries(user)

      assert length(results) == 2
      email_ids = Enum.map(results, & &1.id)
      assert unread1.id in email_ids
      assert unread2.id in email_ids
    end
  end

  describe "email analytics" do
    test "calculate_average_response_time/1 returns correct average" do
      user = insert(:user)

      insert(:read_email, user: user, response_time_hours: 2)
      insert(:read_email, user: user, response_time_hours: 4)
      insert(:read_email, user: user, response_time_hours: 6)
      # Unread email should not affect average
      insert(:unread_email, user: user)

      average = Communications.calculate_average_response_time(user)
      assert average == 4.0
    end

    test "calculate_average_response_time/1 returns nil for user with no read emails" do
      user = insert(:user)
      insert(:unread_email, user: user)

      average = Communications.calculate_average_response_time(user)
      assert average == nil
    end

    test "calculate_email_productivity_stats/1 returns comprehensive stats" do
      user = insert(:user)

      # Create emails with specific values for testing  
      insert(:urgent_important_email, user: user, importance_score: 9, task_potential: 0.8)
      insert(:urgent_important_email, user: user, importance_score: 8, task_potential: 0.9)
      insert(:digital_noise_email, user: user, importance_score: 2, task_potential: 0.2)
      insert(:digital_noise_email, user: user, importance_score: 1, task_potential: 0.1)

      # Create additional emails with specific classification to avoid randomness
      insert(:email_summary,
        user: user,
        classification: :not_urgent_important,
        importance_score: 5,
        task_potential: 0.6
      )

      insert(:email_summary,
        user: user,
        classification: :urgent_unimportant,
        importance_score: 4,
        task_potential: 0.3
      )

      stats = Communications.calculate_email_productivity_stats(user)

      assert stats.total_emails == 6
      assert stats.urgent_important_count == 2
      assert stats.digital_noise_count == 2
      # (9+8+2+1+5+4)/6 = 29/6 ≈ 4.8
      assert_in_delta stats.average_importance_score, 4.8, 0.1
      # 0.8 and 0.9 are >= 0.7
      assert stats.high_task_potential_count == 2
      # (0.8+0.9+0.2+0.1+0.6+0.3)/6 = 2.9/6 ≈ 0.5
      assert_in_delta stats.average_task_potential, 0.5, 0.1
    end
  end
end
