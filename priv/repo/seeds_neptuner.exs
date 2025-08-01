# Neptuner Seeds

alias Neptuner.{Repo, Accounts, Tasks, Habits, Connections, Calendar, Communications}

# Create a test user if one doesn't exist
case Accounts.get_user_by_email("test@neptuner.dev") do
  nil ->
    {:ok, user} = Accounts.register_user(%{
      email: "test@neptuner.dev",
      password: "password123456",
      cosmic_perspective_level: :skeptical
    })
    
    # Confirm the user manually
    user
    |> Neptuner.Accounts.User.confirm_changeset()
    |> Repo.update!()
    
    IO.puts("Created test user: test@neptuner.dev")
    
    # Create some sample tasks
    {:ok, _task1} = Tasks.create_task(user.id, %{
      title: "Check email for the 47th time today",
      description: "Perform the ritual of inbox anxiety management",
      cosmic_priority: :matters_to_nobody,
      estimated_actual_importance: 2
    })
    
    {:ok, _task2} = Tasks.create_task(user.id, %{
      title: "Learn Spanish",
      description: "Actually commit to this language learning thing",
      cosmic_priority: :matters_10_years,
      estimated_actual_importance: 8
    })
    
    {:ok, _task3} = Tasks.create_task(user.id, %{
      title: "Update LinkedIn profile",
      description: "Optimize personal brand for algorithmic approval",
      cosmic_priority: :matters_10_days,
      estimated_actual_importance: 4
    })
    
    # Create some sample habits
    {:ok, habit1} = Habits.create_habit(user.id, %{
      name: "Drink water",
      description: "Remember that humans require hydration",
      habit_type: :basic_human_function
    })
    
    {:ok, habit2} = Habits.create_habit(user.id, %{
      name: "Meditate",
      description: "Sit quietly and observe the chaos of consciousness",
      habit_type: :actually_useful
    })
    
    {:ok, habit3} = Habits.create_habit(user.id, %{
      name: "Check productivity apps",
      description: "Spend time managing time management systems",
      habit_type: :self_improvement_theater
    })
    
    # Add some habit entries for the past few days
    for days_ago <- 0..6 do
      date = Date.add(Date.utc_today(), -days_ago)
      
      if rem(days_ago, 2) == 0 do
        Habits.create_habit_entry(habit1.id, %{completed_on: date})
      end
      
      if days_ago < 3 do
        Habits.create_habit_entry(habit2.id, %{completed_on: date})
      end
      
      if days_ago != 1 do
        Habits.create_habit_entry(habit3.id, %{completed_on: date})
      end
    end
    
    # Create sample email summaries
    sample_emails = [
      %{
        subject: "URGENT: Server Down - Immediate Action Required",
        sender_email: "alerts@company.com",
        sender_name: "System Alerts",
        body_preview: "Critical server failure detected. Production services affected. All hands on deck.",
        received_at: DateTime.add(DateTime.utc_now(), -3, :hour),
        is_read: true,
        response_time_hours: 1,
        time_spent_minutes: 45,
        importance_score: 10,
        classification: :urgent_important
      },
      %{
        subject: "URGENT: Flash Sale - 70% Off Everything!",
        sender_email: "deals@retailstore.com", 
        sender_name: "Retail Store",
        body_preview: "Limited time offer! Don't miss out on our biggest sale of the year! Act now!",
        received_at: DateTime.add(DateTime.utc_now(), -5, :hour),
        is_read: false,
        response_time_hours: nil,
        time_spent_minutes: 2,
        importance_score: 1,
        classification: :urgent_unimportant
      },
      %{
        subject: "Project Proposal: New Feature Development",
        sender_email: "sarah@company.com",
        sender_name: "Sarah Johnson",
        body_preview: "I've been working on a proposal for the new user dashboard feature. Would love your thoughts on the approach.",
        received_at: DateTime.add(DateTime.utc_now(), -24, :hour),
        is_read: true,
        response_time_hours: 18,
        time_spent_minutes: 25,
        importance_score: 8,
        classification: :not_urgent_important
      },
      %{
        subject: "Weekly Newsletter: 10 Productivity Hacks That Will Change Your Life",
        sender_email: "newsletter@productivityguru.com",
        sender_name: "Productivity Guru",
        body_preview: "This week we're sharing the top 10 productivity hacks that successful people use daily...",
        received_at: DateTime.add(DateTime.utc_now(), -12, :hour),
        is_read: false,
        response_time_hours: nil,
        time_spent_minutes: 1,
        importance_score: 2,
        classification: :digital_noise
      },
      %{
        subject: "Meeting Reminder: Q4 Planning Session",
        sender_email: "calendar@company.com",
        sender_name: "Calendar System",
        body_preview: "Reminder: Q4 Strategic Planning Session scheduled for tomorrow at 2:00 PM in Conference Room A.",
        received_at: DateTime.add(DateTime.utc_now(), -8, :hour),
        is_read: true,
        response_time_hours: 2,
        time_spent_minutes: 5,
        importance_score: 7,
        classification: :not_urgent_important
      },
      %{
        subject: "You have 47 new LinkedIn notifications",
        sender_email: "notifications@linkedin.com",
        sender_name: "LinkedIn",
        body_preview: "John liked your post. Sarah viewed your profile. Mike commented on your article...",
        received_at: DateTime.add(DateTime.utc_now(), -6, :hour),
        is_read: false,
        response_time_hours: nil,
        time_spent_minutes: 8,
        importance_score: 2,
        classification: :digital_noise
      },
      %{
        subject: "Code Review Required: User Authentication Fix",
        sender_email: "mike@company.com",
        sender_name: "Mike Chen",
        body_preview: "Hey, I've pushed a fix for the authentication bug we discussed. Could you review when you have a chance?",
        received_at: DateTime.add(DateTime.utc_now(), -4, :hour),
        is_read: true,
        response_time_hours: 3,
        time_spent_minutes: 15,
        importance_score: 6,
        classification: :not_urgent_important
      },
      %{
        subject: "URGENT: Action Required - Account Security Alert",
        sender_email: "security@bank.com",
        sender_name: "Bank Security",
        body_preview: "We've detected unusual activity on your account. Please verify your identity immediately.",
        received_at: DateTime.add(DateTime.utc_now(), -1, :hour),
        is_read: true,
        response_time_hours: 1,
        time_spent_minutes: 20,
        importance_score: 9,
        classification: :urgent_important
      }
    ]
    
    Enum.each(sample_emails, fn email_attrs ->
      Communications.create_email_summary(user.id, email_attrs)
    end)
    
    IO.puts("Created sample tasks, habits, and emails for test user")
    
  user ->
    IO.puts("Test user already exists: #{user.email}")
end