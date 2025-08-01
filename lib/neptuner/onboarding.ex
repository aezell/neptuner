defmodule Neptuner.Onboarding do
  @moduledoc """
  The Onboarding context manages user onboarding flow and demo data generation.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo
  alias Neptuner.Accounts.User
  alias Neptuner.{Tasks, Habits, Achievements, Analytics}

  @doc """
  Starts the onboarding process for a user.
  """
  def start_onboarding(user) do
    result =
      user
      |> User.onboarding_changeset(%{
        onboarding_step: :welcome,
        onboarding_started_at: DateTime.utc_now()
      })
      |> Repo.update()

    case result do
      {:ok, updated_user} ->
        Analytics.track_activation_event(updated_user, :onboarding_started)
        {:ok, updated_user}

      error ->
        error
    end
  end

  @doc """
  Advances user to the next onboarding step.
  """
  def advance_step(user, next_step)
      when next_step in [
             :cosmic_setup,
             :demo_data,
             :first_connection,
             :first_task,
             :dashboard_tour,
             :completed
           ] do
    attrs = %{onboarding_step: next_step}

    attrs =
      if next_step == :completed do
        Map.merge(attrs, %{
          onboarding_completed: true,
          onboarding_completed_at: DateTime.utc_now()
        })
      else
        attrs
      end

    user
    |> User.onboarding_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates user's cosmic perspective level during onboarding.
  """
  def set_cosmic_perspective(user, level) when level in [:skeptical, :resigned, :enlightened] do
    result =
      user
      |> User.onboarding_changeset(%{cosmic_perspective_level: level})
      |> Repo.update()

    case result do
      {:ok, updated_user} ->
        Analytics.track_activation_event(updated_user, :cosmic_perspective_set, %{level: level})
        {:ok, updated_user}

      error ->
        error
    end
  end

  @doc """
  Marks specific onboarding milestones as completed.
  """
  def mark_milestone_completed(user, milestone)
      when milestone in [
             :demo_data_generated,
             :first_task_created,
             :first_connection_made,
             :dashboard_tour_completed
           ] do
    attrs = %{milestone => true}

    # Calculate activation score based on completed milestones
    updated_user = Map.put(user, milestone, true)
    activation_score = calculate_activation_score(updated_user)
    attrs = Map.put(attrs, :activation_score, activation_score)

    user
    |> User.onboarding_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Generates demo data for a new user to provide a better onboarding experience.
  """
  def generate_demo_data(user) do
    Repo.transaction(fn ->
      # Create sample tasks with different cosmic priorities
      demo_tasks = [
        %{
          title: "Check email for the 47th time today",
          description: "Because surely something earth-shattering happened in the last 3 minutes",
          cosmic_priority: :matters_to_nobody,
          estimated_actual_importance: 2,
          status: :completed,
          completed_at: DateTime.add(DateTime.utc_now(), -3600, :second)
        },
        %{
          title: "Call mom",
          description:
            "Actually important human connection that keeps getting pushed to tomorrow",
          cosmic_priority: :matters_10_years,
          estimated_actual_importance: 9,
          status: :pending
        },
        %{
          title: "Organize digital photos from 2019",
          description:
            "Because future archaeologists will thank us for our systematic jpeg cataloging",
          cosmic_priority: :matters_to_nobody,
          estimated_actual_importance: 1,
          status: :pending
        },
        %{
          title: "Exercise for 30 minutes",
          description: "Reminding this meat suit that movement exists",
          cosmic_priority: :matters_10_days,
          estimated_actual_importance: 7,
          status: :pending
        },
        %{
          title: "Update LinkedIn profile",
          description: "Perform career optimization theater for the algorithm",
          cosmic_priority: :matters_to_nobody,
          estimated_actual_importance: 3,
          status: :completed,
          completed_at: DateTime.add(DateTime.utc_now(), -86400, :second)
        }
      ]

      # Create tasks
      Enum.each(demo_tasks, fn task_attrs ->
        Tasks.create_task(user.id, task_attrs)
      end)

      # Create sample habits
      demo_habits = [
        %{
          name: "Drink water",
          description: "Manual hydration reminders for bipedal meat suit maintenance",
          habit_type: :basic_human_function,
          current_streak: 3,
          longest_streak: 12
        },
        %{
          name: "Morning meditation",
          description: "Daily practice of being aware that thoughts exist",
          habit_type: :actually_useful,
          current_streak: 0,
          longest_streak: 7
        },
        %{
          name: "Check productivity apps",
          description:
            "Meta-productivity: using apps to organize the apps that organize your life",
          habit_type: :self_improvement_theater,
          current_streak: 45,
          longest_streak: 45
        }
      ]

      # Create habits and some entries
      Enum.each(demo_habits, fn habit_attrs ->
        case Habits.create_habit(user.id, habit_attrs) do
          {:ok, habit} ->
            # Create some habit entries for streaks
            if habit_attrs.current_streak > 0 do
              create_habit_entries(habit, habit_attrs.current_streak)
            end

          {:error, _} ->
            :ok
        end
      end)

      # Grant some initial achievements
      grant_demo_achievements(user)

      # Mark demo data as generated
      user
      |> User.onboarding_changeset(%{demo_data_generated: true})
      |> Repo.update!()
    end)
  end

  defp create_habit_entries(habit, streak_days) do
    today = Date.utc_today()

    Enum.each(0..(streak_days - 1), fn days_ago ->
      entry_date = Date.add(today, -days_ago)
      commentary = generate_existential_commentary(habit.name, days_ago)

      Habits.create_habit_entry(habit.id, %{
        completed_on: entry_date,
        existential_commentary: commentary
      })
    end)
  end

  defp generate_existential_commentary(habit_name, days_ago) do
    base_comments = %{
      "Drink water" => [
        "Day #{days_ago + 1} of manually reminding a 70% water organism to consume water",
        "Successfully converted H₂O molecules into the illusion of hydrated productivity",
        "Another triumph in the eternal struggle against dehydration-induced mortality"
      ],
      "Morning meditation" => [
        "Achieved brief awareness of the infinite void between thoughts",
        "Sat quietly while the brain performed its daily chaos inventory",
        "Successfully observed the mind's impressive capacity for creative procrastination"
      ],
      "Check productivity apps" => [
        "Meta-productivity achievement unlocked: organizing the tools that organize the tasks",
        "Performed daily ritual of optimizing optimization systems",
        "Checked 12 apps designed to reduce the need to check apps"
      ]
    }

    comments =
      base_comments[habit_name] || ["Another day, another habit checkbox dutifully filled"]

    Enum.random(comments)
  end

  defp grant_demo_achievements(user) do
    # Grant some basic achievements to show the system works
    achievements_to_grant = [
      # For completing demo tasks (5 tasks)
      {"task_digital_rectangle_mover", 5},
      # For basic setup (0 connections initially)
      {"connection_integrator", 0}
    ]

    Enum.each(achievements_to_grant, fn {achievement_key, progress_value} ->
      try do
        case Achievements.create_or_update_user_achievement(
               user.id,
               achievement_key,
               progress_value
             ) do
          {:ok, _user_achievement} -> :ok
          # Ignore errors for demo achievements
          {:error, _} -> :ok
        end
      rescue
        # Handle case where achievement doesn't exist yet
        Ecto.NoResultsError -> :ok
      end
    end)
  end

  @doc """
  Calculates user activation score based on completed onboarding milestones.
  """
  def calculate_activation_score(user) do
    score = 0
    score = if user.demo_data_generated, do: score + 10, else: score
    score = if user.first_task_created, do: score + 20, else: score
    score = if user.first_connection_made, do: score + 30, else: score
    score = if user.dashboard_tour_completed, do: score + 15, else: score
    score = if user.onboarding_completed, do: score + 25, else: score

    score
  end

  @doc """
  Checks if user needs onboarding.
  """
  def needs_onboarding?(user) do
    not user.onboarding_completed
  end

  @doc """
  Gets onboarding progress for a user.
  """
  def get_onboarding_progress(user) do
    %{
      current_step: user.onboarding_step,
      completed: user.onboarding_completed,
      demo_data_generated: user.demo_data_generated,
      first_task_created: user.first_task_created,
      first_connection_made: user.first_connection_made,
      dashboard_tour_completed: user.dashboard_tour_completed,
      activation_score: user.activation_score,
      cosmic_perspective_level: user.cosmic_perspective_level,
      started_at: user.onboarding_started_at,
      completed_at: user.onboarding_completed_at
    }
  end

  @doc """
  Gets cosmic perspective options with descriptions.
  """
  def cosmic_perspective_options do
    [
      %{
        key: :skeptical,
        title: "Cosmic Skeptic",
        description:
          "You see through the productivity theater but play along anyway. Perfect for those who understand that most urgent tasks are actually just noise wearing an important hat.",
        quote: "\"I'll do this task, but we both know the universe won't notice.\""
      },
      %{
        key: :resigned,
        title: "Productively Resigned",
        description:
          "You've accepted that life is an endless series of digital rectangles to be moved around, and you're surprisingly okay with that.",
        quote: "\"Another day, another checkbox. At least the checkboxes are consistent.\""
      },
      %{
        key: :enlightened,
        title: "Cosmically Enlightened",
        description:
          "You've achieved peak meta-awareness about productivity culture while still getting things done. You can optimize your optimization systems with a smile.",
        quote:
          "\"I organize my life with apps that help me organize my life. And I find this amusing.\""
      }
    ]
  end
end
