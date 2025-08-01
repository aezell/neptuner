defmodule Neptuner.Achievements.UserAchievementTest do
  use Neptuner.DataCase

  alias Neptuner.Achievements.UserAchievement

  describe "changeset/2" do
    test "valid changeset with minimal fields" do
      changeset = UserAchievement.changeset(%UserAchievement{}, %{})
      assert changeset.valid?
    end

    test "valid changeset with all fields" do
      attrs = %{
        progress_value: 10,
        completed_at: DateTime.utc_now(),
        notified_at: DateTime.utc_now()
      }

      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :progress_value) == 10
    end

    test "validates progress_value is non-negative" do
      attrs = %{progress_value: -5}
      
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).progress_value
    end

    test "accepts zero progress_value" do
      attrs = %{progress_value: 0}
      
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      assert changeset.valid?
    end

    test "unique constraint on user_id and achievement_id" do
      user = insert(:user)
      achievement = insert(:achievement)
      
      insert(:user_achievement, user: user, achievement: achievement)
      
      attrs = %{progress_value: 5}
      changeset = UserAchievement.changeset(
        %UserAchievement{user_id: user.id, achievement_id: achievement.id}, 
        attrs
      )
      
      assert changeset.valid?
      {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).user_id
    end

    test "sets default progress_value to 0" do
      user_achievement = %UserAchievement{}
      assert user_achievement.progress_value == 0
    end
  end

  describe "completed?/1" do
    test "returns false when completed_at is nil" do
      user_achievement = build(:user_achievement, completed_at: nil)
      refute UserAchievement.completed?(user_achievement)
    end

    test "returns true when completed_at has a datetime" do
      completed_at = DateTime.utc_now()
      user_achievement = build(:user_achievement, completed_at: completed_at)
      assert UserAchievement.completed?(user_achievement)
    end
  end

  describe "notified?/1" do
    test "returns false when notified_at is nil" do  
      user_achievement = build(:user_achievement, notified_at: nil)
      refute UserAchievement.notified?(user_achievement)
    end

    test "returns true when notified_at has a datetime" do
      notified_at = DateTime.utc_now()
      user_achievement = build(:user_achievement, notified_at: notified_at)
      assert UserAchievement.notified?(user_achievement)
    end
  end

  describe "progress_percentage/2" do
    test "calculates percentage when achievement has threshold_value" do
      achievement = build(:achievement, threshold_value: 20)
      user_achievement = build(:user_achievement, progress_value: 10)
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 50
    end

    test "caps percentage at 100 when progress exceeds threshold" do
      achievement = build(:achievement, threshold_value: 10)
      user_achievement = build(:user_achievement, progress_value: 25)
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 100
    end

    test "returns 0 when achievement has no threshold_value and not completed" do
      achievement = build(:achievement, threshold_value: nil)
      user_achievement = build(:user_achievement, progress_value: 10, completed_at: nil)
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 0
    end

    test "returns 100 when achievement has no threshold_value but is completed" do
      achievement = build(:achievement, threshold_value: nil)
      user_achievement = build(:user_achievement, 
        progress_value: 10, 
        completed_at: DateTime.utc_now()
      )
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 100
    end

    test "returns 0 when achievement threshold_value is 0 and not completed" do
      achievement = build(:achievement, threshold_value: 0)
      user_achievement = build(:user_achievement, progress_value: 10, completed_at: nil)
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 0
    end

    test "returns 100 when achievement threshold_value is 0 but is completed" do
      achievement = build(:achievement, threshold_value: 0)
      user_achievement = build(:user_achievement,
        progress_value: 10,
        completed_at: DateTime.utc_now()
      )
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 100
    end

    test "handles edge case with zero progress" do
      achievement = build(:achievement, threshold_value: 10)
      user_achievement = build(:user_achievement, progress_value: 0)
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 0
    end

    test "properly rounds percentage" do
      achievement = build(:achievement, threshold_value: 3)
      user_achievement = build(:user_achievement, progress_value: 1)
      
      percentage = UserAchievement.progress_percentage(user_achievement, achievement)
      assert percentage == 33  # 1/3 * 100 = 33.33... rounded to 33
    end
  end

  describe "database constraints and relationships" do
    test "belongs to user" do
      user = insert(:user)
      achievement = insert(:achievement)
      user_achievement = insert(:user_achievement, user: user, achievement: achievement)
      
      loaded_user_achievement = Repo.get!(UserAchievement, user_achievement.id) |> Repo.preload(:user)
      assert loaded_user_achievement.user.id == user.id
    end

    test "belongs to achievement" do
      user = insert(:user)
      achievement = insert(:achievement)
      user_achievement = insert(:user_achievement, user: user, achievement: achievement)
      
      loaded_user_achievement = Repo.get!(UserAchievement, user_achievement.id) |> Repo.preload(:achievement)
      assert loaded_user_achievement.achievement.id == achievement.id
    end

    test "cascades delete when achievement is deleted" do
      user = insert(:user)
      achievement = insert(:achievement)
      user_achievement = insert(:user_achievement, user: user, achievement: achievement)
      
      Repo.delete!(achievement)
      
      refute Repo.get(UserAchievement, user_achievement.id)
    end
  end
end