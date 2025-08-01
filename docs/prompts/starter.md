# Build Neptuner: The Ironically Productive Task Management App

## Project Overview
Build "Neptuner" - a full-stack web application that provides genuine productivity features while maintaining an ironic, off-kilter perspective on modern productivity culture. The app should be both genuinely useful and gently subversive.

**Tech Stack:**
- Phoenix SaaS Kit as foundation (https://www.phoenixsaaskit.com/)
- Elixir/Phoenix backend (already configured)
- PostgreSQL database (already configured)
- Tailwind CSS for styling (already configured)
- Phoenix LiveView for real-time interactions (already configured)
- Authentication & user management (already included)
- Stripe payments integration (already included)
- Admin panel (already included)
- Multi-tenancy support (already included)

## Core App Concept
Neptuner helps users manage tasks, habits, and projects while providing cosmic perspective and gentle mockery of productivity obsession. It's functional but philosophically skeptical.

## Database Schema & Models

Create these core models with appropriate relationships:

**Users** (extends existing Phoenix SaaS Kit user model)
- Add cosmic_perspective_level (enum: skeptical, resigned, enlightened)
- Add total_meaningless_tasks_completed (integer)
- Leverage existing auth, profile, subscription fields

**Tasks**
- title, description
- cosmic_priority (enum: "matters_10_years", "matters_10_days", "matters_to_nobody")
- status (enum: pending, completed, abandoned_wisely)
- estimated_actual_importance (integer 1-10)
- belongs_to user
- completed_at, created_at, updated_at

**Habits**
- name, description
- current_streak, longest_streak
- habit_type (enum: basic_human_function, self_improvement_theater, actually_useful)
- belongs_to user
- has_many habit_entries

**HabitEntries**
- completed_on (date)
- existential_commentary (text) - auto-generated
- belongs_to habit

**ServiceConnections**
- provider (enum: google, microsoft, apple, caldav)
- service_type (enum: calendar, email, tasks) - allows multiple service types per provider
- external_account_id (string)
- external_account_email (string)
- display_name (string) - e.g., "Work Gmail", "Personal Calendar"
- access_token (encrypted)
- refresh_token (encrypted)
- token_expires_at (datetime)
- last_sync_at (datetime)
- sync_enabled (boolean, default: true)
- connection_status (enum: active, expired, error, disconnected)
- scopes_granted (array) - track which permissions were granted
- belongs_to user

**Meetings** (synced from connected calendars)
- external_calendar_id (string) - from connected calendar service
- service_connection_id (references ServiceConnections)
- title, duration_minutes
- attendee_count (integer)
- could_have_been_email (boolean, default: true)
- actual_productivity_score (integer 1-10) - user-rated post-meeting
- meeting_type (enum: standup, all_hands, one_on_one, brainstorm, status_update, other)
- belongs_to user
- scheduled_at, synced_at, created_at

## Key Features to Implement

### 1. Cosmic Task Prioritization System
- Task creation form with cosmic priority selection
- Auto-suggestion engine that analyzes task descriptions and suggests most tasks "matter to nobody"
- Dashboard showing breakdown of task cosmic importance
- Weekly "Reality Check" that shows how many low-importance tasks were completed

### 2. Achievement Deflation Engine
- Custom achievement system with backhanded congratulations
- Examples of achievements to implement:
  - "Digital Rectangle Mover" (completed 10 tasks)
  - "Email Warrior" (sent 50 emails that could have been texts)
  - "Meeting Survivor" (attended 20 meetings)
- Achievement notifications should appear with gentle mockery

### 3. Habit Tracking with Existential Commentary
- Habit creation and daily check-in system
- Auto-generated commentary system (use a simple random selection from pre-written responses)
- Streak tracking with increasingly absurd celebration messages
- Habit categorization system (basic human functions vs. self-improvement theater)

### 4. Service Connections & Calendar Integration
- Unified service connection system for Google, Microsoft, Apple, CalDAV
- Support for multiple accounts per provider (work + personal Google accounts)
- Calendar sync with automatic meeting import and analysis
- Future email integration for task extraction and "email that could have been a task" analysis
- Post-meeting productivity scoring prompts
- AI-powered meeting classification (could have been email, actually useful, pure theater)
- Calculate "collective human hours lost" metric across all connected calendars
- "Could Have Been an Email" percentage tracking
- Weekly reports on meeting productivity with cosmic perspective commentary

### 5. Philosophical Dashboard
- Daily "Cosmic Perspective" widget
- Running tallies of meaningless tasks completed
- "Productivity Theater" metrics
- Random philosophical observations about modern work

## Technical Implementation Strategy

Use **subagents** approach for complex features:

### Agent 1: Database Extensions & Core Models
- Extend existing Phoenix SaaS Kit user model with Neptuner-specific fields
- Create new models (Tasks, Habits, HabitEntries, Meetings)
- Run migrations for new tables
- Implement model associations and validations
- Add seeds for testing

### Agent 2: Service Connections & OAuth Management
- Build unified service connection system (separate from auth)
- Implement OAuth flows for Google, Microsoft, Apple services
- Create connection management UI (connect, disconnect, reconnect)
- Support multiple accounts per provider (work/personal separation)
- Add connection status monitoring and token refresh logic
- Build service connection settings and permissions management
- Integrate with existing Phoenix SaaS Kit user management

### Agent 3: SaaS Features Customization
- Review and customize existing authentication flows for Neptuner branding
- Set up subscription plans for premium features (ironic achievement badges, advanced cosmic insights)
- Customize existing admin panel for Neptuner-specific metrics and connection monitoring
- Configure multi-tenancy if needed for team productivity tracking
- Integrate cosmic perspective settings into existing user preferences

### Agent 4: Task Management System
- Build task CRUD operations with LiveView
- Implement cosmic priority system
- Create task dashboard with filtering
- Add completion tracking and statistics
- Future: Integrate with email connections for automatic task extraction

### Agent 5: Habit Tracking System
- Build habit creation and management
- Implement daily check-in system
- Create streak tracking logic
- Add existential commentary generation

### Agent 6: Calendar Integration & Meeting Analytics
- Build calendar sync using established service connections
- Implement automatic meeting import and classification system
- Create post-meeting rating prompts (could have been email, productivity score)
- Implement achievement engine with custom messages
- Build "Meeting Reality Check" analytics dashboard
- Add background jobs for regular calendar syncing across all connected accounts
- Create notification system for achievements and weekly meeting reports
- Support multiple calendar accounts per user (work/personal separation)

### Agent 7: UI/UX & Styling Integration
- Customize existing Phoenix SaaS Kit Tailwind theme for Neptuner brand
- Extend existing component library with ironic elements
- Build service connection management UI (connect/disconnect interfaces)
- Implement responsive design building on existing patterns
- Add micro-interactions and animations
- Ensure ironic tone comes through in copy and design
- Create custom components for achievements, cosmic priority indicators, connection status
- Integrate seamlessly with existing SaaS Kit navigation and layout

## Design Guidelines

**Visual Style:**
- Clean, modern interface with subtle subversive elements
- Muted color palette with occasional bright accent for ironic emphasis
- Typography that's professional but includes playful elements
- Use space and whitespace to create zen-like feel despite the chaos being organized

**Tone of Voice in UI:**
- Helpful instructions with gentle philosophical asides
- Error messages that acknowledge the cosmic insignificance of the error
- Success messages that celebrate achievements while deflating them
- Button text that's functional but occasionally wry ("Add Another Meaningless Task", "Complete This Digital Rectangle", etc.)

## Sample Copy/Content to Include

**Task Priority Descriptions:**
- "Matters in 10 years": "Genuinely important life decisions, relationships, health choices"
- "Matters in 10 days": "Legitimate short-term concerns with real consequences"  
- "Matters to nobody": "Digital busy work that exists because we forgot how to be idle"

**Achievement Examples:**
- "Email Archaeologist": "Successfully excavated meaning from 25 thread chains"
- "Notification Ninja": "Achieved inbox zero while 47 other apps demanded attention"
- "Digital Rectangle Mover": "Completed 100 tasks of questionable cosmic importance"

**Calendar Integration Examples:**
- "Meeting Archaeologist": "Successfully extracted 0% actionable insights from 25 status meetings"
- "Time Alchemist": "Transformed 8 hours of meetings into 0.5 hours of actual decisions"
- "Zoom Warrior": "Survived 50 video calls where you could have just read the agenda"
- "Calendar Tetris Grandmaster": "Scheduled meetings in every 15-minute gap, achieving 0% focus time"

**Meeting Classification Commentary:**
- Status Update meetings: "Today's episode of 'People Reading Lists at Each Other'"
- All-hands meetings: "Company-wide sharing of information that will be immediately forgotten"
- Brainstorming sessions: "Collective generation of ideas that will die in Slack threads"
- One-on-ones: "Bilateral confirmation that everything is 'fine' and 'on track'"

**Existential Commentary Samples:**
- "Day 12 of drinking water—amazing that bipedal meat requires manual hydration reminders"
- "Another day of meditation completed. The thoughts are still there, but now you're aware that you're aware of them being there."
- "Exercise streak: 5 days of convincing your body that predators are chasing you on a machine going nowhere"

## Premium Features Strategy

Leverage the built-in Stripe integration for tiered pricing:

**Free Tier:**
- Basic task management with cosmic priority
- Simple habit tracking (up to 5 habits)
- Standard deflating achievements
- Basic cosmic perspective insights
- One Google Calendar connection

**Premium Tier ("Cosmic Enlightenment"):**
- Unlimited habits and advanced streak analytics
- Premium achievement badges with custom ironic messages
- Multiple service connections per provider (work + personal Google, Microsoft, etc.)
- Cross-account calendar analytics and meeting insights
- Future email integration for task extraction and "email productivity theater" analysis
- Personalized existential commentary
- "Productivity Theater" detailed analytics with meeting insights across all accounts
- Custom cosmic perspective settings
- Export capabilities for "meaningless accomplishments"
- Advanced calendar analytics (time spent by meeting type, productivity trends across accounts)

## Technical Requirements

- Build on existing Phoenix SaaS Kit foundation
- Use Phoenix LiveView for real-time updates (already configured)
- Extend existing error handling and validation patterns
- Add test coverage for new Neptuner-specific functionality
- Leverage existing responsive design system
- Use existing security measures and extend as needed
- Integrate with existing Stripe payment flows
- Utilize existing admin panel for Neptuner-specific metrics

## Success Criteria

The app should:
1. Actually function as a useful productivity tool
2. Make users smile while using it
3. Provide genuine insights about task priority and time management
4. Feel polished and professional despite the irreverent tone
5. Load quickly and handle basic user workflows smoothly

## Getting Started Instructions

1. Clone/download Phoenix SaaS Kit and follow its setup instructions
2. Customize branding and configuration for Neptuner
3. Begin with Agent 1 (Database Extensions) to add Neptuner-specific models
4. Work through each agent sequentially, building on existing SaaS Kit features
5. Configure subscription plans in Stripe dashboard for Neptuner tiers
6. Test each major feature as it's built
7. Use existing deployment pipeline to deploy to staging/production

**Phoenix SaaS Kit Integration Notes:**
- Keep authentication separate from service connections - users log in with email/password or Phoenix SaaS Kit's existing auth
- Build service connections as a separate OAuth system for connecting external accounts
- Extend existing admin panel with connection monitoring, sync status, and Neptuner analytics
- Use existing email system for achievement notifications, weekly reports, and post-meeting rating prompts
- Build on existing component library and design system
- Integrate cosmic perspective features with existing user settings
- Use existing subscription management for premium tier features (connection limits, advanced analytics)
- Leverage existing OAuth implementation patterns but build separate connection flows
- Use existing background job infrastructure (Oban) for calendar syncing across multiple accounts
- Extend existing API patterns for calendar webhook handling and connection management

Remember: The goal is to build something genuinely useful that happens to have a sense of humor about itself. The irony should enhance, not hinder, the user experience.

### Agent 8: Dashboard & Analytics
- Build main dashboard combining all systems
- Implement "Cosmic Perspective" widgets with data from all connected services
- Create weekly/monthly summary reports across calendars and productivity metrics
- Add data visualization for productivity metrics
- Show service connection status and sync health
- Create unified analytics across multiple connected accounts