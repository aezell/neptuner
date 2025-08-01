# Achievement Deflation Engine Seeds

alias Neptuner.{Repo, Achievements}

# Delete existing achievements to avoid conflicts on re-run
Repo.delete_all(Achievements.Achievement)

# Task Management Achievements
achievements = [
  # Task Achievements
  %{
    key: "task_beginner",
    title: "Digital Rectangle Beginner",
    description: "Complete your first task",
    ironic_description: "Congratulations! You've successfully moved your first digital rectangle from one imaginary pile to another. The universe remains unchanged, but your productivity app is pleased.",
    category: "tasks",
    icon: "hero-check-circle",
    color: "green",
    threshold_value: 1,
    threshold_type: "count"
  },
  %{
    key: "task_digital_rectangle_mover",
    title: "Digital Rectangle Mover",
    description: "Complete 25 tasks",
    ironic_description: "Twenty-five digital rectangles successfully relocated! Your mouse has traveled dozens of pixels. Somewhere, a productivity guru sheds a single tear of pride.",
    category: "tasks",
    icon: "hero-squares-2x2",
    color: "blue",
    threshold_value: 25,
    threshold_type: "count"
  },
  %{
    key: "task_existential_warrior",
    title: "Existential Task Warrior",
    description: "Complete 100 tasks",
    ironic_description: "One hundred tasks completed! You've achieved the digital equivalent of digging holes and filling them back up. The ancient Greeks would call this Sisyphean, but at least you have badges.",
    category: "tasks",
    icon: "hero-trophy",
    color: "yellow",
    threshold_value: 100,
    threshold_type: "count"
  },

  # Habit Achievements
  %{
    key: "habit_basic_human",
    title: "Basic Human Function",
    description: "Create your first habit",
    ironic_description: "You've created a digital reminder to do something humans have done naturally for millennia. Technology: solving problems we didn't know we had.",
    category: "habits",
    icon: "hero-arrow-path",
    color: "purple",
    threshold_value: 1,
    threshold_type: "count"
  },
  %{
    key: "habit_streak_survivor",
    title: "Streak Survivor",
    description: "Maintain a 30-day habit streak",
    ironic_description: "Thirty consecutive days of remembering to check a box! Your ancestors survived ice ages, but you've mastered the art of daily box-checking. Progress is relative.",
    category: "habits",
    icon: "hero-fire",
    color: "red",
    threshold_value: 30,
    threshold_type: "streak"
  },
  %{
    key: "habit_zen_master",
    title: "Habit Zen Master",
    description: "Maintain a 100-day habit streak",
    ironic_description: "One hundred days of digital discipline! You've achieved what monks call mindfulness and what Silicon Valley calls 'engagement metrics.' Inner peace through outer notifications.",
    category: "habits",
    icon: "hero-sparkles",
    color: "yellow",
    threshold_value: 100,
    threshold_type: "streak"
  },

  # Meeting Achievements
  %{
    key: "meeting_survivor",
    title: "Meeting Survivor",
    description: "Attend 10 meetings",
    ironic_description: "Ten meetings survived! You've mastered the art of looking engaged while your consciousness slowly dissolves into the digital ether. Your camera is on, but is anyone home?",
    category: "meetings",
    icon: "hero-video-camera",
    color: "blue",
    threshold_value: 10,
    threshold_type: "count"
  },
  %{
    key: "meeting_archaeologist",
    title: "Meeting Archaeologist",
    description: "Attend 25 'could have been email' meetings",
    ironic_description: "Twenty-five meetings that could have been emails! You've excavated exactly zero actionable insights from hours of collective human time. Future anthropologists will study your calendar in wonder.",
    category: "meetings",
    icon: "hero-magnifying-glass",
    color: "yellow",
    threshold_value: 25,
    threshold_type: "count"
  },
  %{
    key: "meeting_time_alchemist",
    title: "Time Alchemist",
    description: "Attend 50 meetings",
    ironic_description: "Fifty meetings completed! You've successfully transformed hours of human potential into... well, other hours. Like alchemy, but with less gold and more Zoom fatigue.",
    category: "meetings",
    icon: "hero-clock",
    color: "red",
    threshold_value: 50,
    threshold_type: "count"
  },

  # Email Achievements  
  %{
    key: "email_warrior",
    title: "Email Warrior",
    description: "Process 50 emails",
    ironic_description: "Fifty emails processed! You've battled the hydra of digital communication—for every email you vanquish, three more shall take its place. Your inbox is now 2% less full.",
    category: "emails",
    icon: "hero-envelope",
    color: "blue",
    threshold_value: 50,
    threshold_type: "count"
  },
  %{
    key: "email_noise_detector",
    title: "Digital Noise Detector",
    description: "Identify 100 emails as digital noise",
    ironic_description: "One hundred pieces of digital noise classified! You've become a connoisseur of meaningless communication. Your ability to detect digital chatter rivals that of dolphins detecting sonar.",
    category: "emails",
    icon: "hero-speaker-x-mark",
    color: "red",
    threshold_value: 100,
    threshold_type: "count"
  },

  # Connection Achievements
  %{
    key: "connection_integrator",
    title: "Digital Life Integrator",
    description: "Connect 3 services",
    ironic_description: "Three services connected! You've successfully linked your digital existence across multiple platforms. Your data now flows freely through the cloud, like a river of ones and zeros.",
    category: "connections",
    icon: "hero-link",
    color: "green",
    threshold_value: 3,
    threshold_type: "count"
  },
  %{
    key: "connection_ecosystem_builder",
    title: "Digital Ecosystem Builder", 
    description: "Connect 5 services",
    ironic_description: "Five services in perfect harmony! You've created a digital ecosystem more complex than most natural ones. Darwin would be proud, or possibly horrified.",
    category: "connections",
    icon: "hero-globe-alt",
    color: "purple",
    threshold_value: 5,
    threshold_type: "count"
  },

  # Productivity Theater
  %{
    key: "productivity_theater_novice",
    title: "Productivity Theater Novice",
    description: "Complete 50 low-importance tasks",
    ironic_description: "Fifty tasks that matter to nobody, completed with dedication! You've mastered the art of looking busy while accomplishing remarkably little. Shakespeare would applaud this performance.",
    category: "productivity_theater",
    icon: "hero-face-smile",
    color: "yellow",
    threshold_value: 50,
    threshold_type: "count"
  },
  %{
    key: "cosmic_perspective_seeker",
    title: "Cosmic Perspective Seeker",
    description: "Achieve enlightened cosmic perspective",
    ironic_description: "You've reached enlightened cosmic perspective! You now understand that most of what we call 'productivity' is elaborate procrastination. This achievement is also meaningless, but at least you know it.",
    category: "productivity_theater",
    icon: "hero-eye",
    color: "purple",
    threshold_value: 1,
    threshold_type: "count"
  }
]

Enum.each(achievements, fn achievement_attrs ->
  case Achievements.create_achievement(achievement_attrs) do
    {:ok, achievement} -> 
      IO.puts("Created achievement: #{achievement.title}")
    {:error, changeset} -> 
      IO.inspect(changeset, label: "Error creating achievement: #{achievement_attrs.title}")
  end
end)

IO.puts("Achievement Deflation Engine loaded with #{length(achievements)} achievements!")