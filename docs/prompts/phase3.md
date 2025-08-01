# Neptuner Development Continuation - Phase 3: Advanced Analytics & Intelligence

## Project Context
You are continuing development of **Neptuner** - a Phoenix SaaS productivity app that provides genuine functionality while maintaining an ironic, philosophical perspective on modern productivity culture. This is built on the Phoenix SaaS Template with Elixir/Phoenix, PostgreSQL, Tailwind CSS, and Phoenix LiveView.

## Agents Completed ✅

### Agent 1: Database Extensions & Core Models ✅
- Extended User model with `cosmic_perspective_level` and `total_meaningless_tasks_completed`
- Created full database schema with migrations for:
  - **Tasks** (cosmic priority, status, importance scoring)
  - **Habits** & **HabitEntries** (streak tracking, existential commentary)  
  - **ServiceConnections** (OAuth tokens, multiple providers/services)
  - **Meetings** (calendar sync, productivity scoring)
- All models have comprehensive context modules (`Neptuner.Tasks`, `Neptuner.Habits`, `Neptuner.Connections`, `Neptuner.Calendar`)
- Working seed data with test user and sample content

### Agent 2: Service Connections & OAuth Management ✅  
- Custom OAuth system separate from user authentication
- Google OAuth 2.0 integration (Calendar, Gmail, Tasks scopes)
- Microsoft Graph API integration (Calendar, Email, Tasks)
- `ServiceOAuthController` with connect/callback/disconnect routes
- `TokenRefreshWorker` + `TokenRefreshScheduler` for background token renewal
- `ConnectionsLive.Index` LiveView for managing connections with ironic UI
- Comprehensive OAuth setup documentation in `docs/oauth-setup.md`
- Routes: `/connections`, `/oauth/:provider/connect`, `/oauth/:provider/callback`

### Agent 4: Task Management System ✅
- **TasksLive.Index** with complete CRUD operations and cosmic priority system
- **Cosmic Priority System**: `:matters_10_years`, `:matters_10_days`, `:matters_to_nobody`
- **Auto-suggestion engine** that intelligently suggests task priorities based on content
- **Weekly Reality Check** showing breakdown of low-importance completed tasks
- **Task dashboard** with filtering by cosmic priority and status
- **Statistics tracking** with real-time metrics and philosophical insights
- Routes: `/tasks`, `/tasks/new`, `/tasks/:id/edit`

### Agent 5: Habit Tracking System ✅
- **HabitsLive.Index** with comprehensive habit management interface
- **Habit Type Classification**: `:basic_human_function`, `:self_improvement_theater`, `:actually_useful`
- **Advanced Streak Tracking** with current/longest streak calculations
- **Daily Check-ins** with duplicate prevention and existential commentary
- **Auto-generated philosophical insights** for each habit entry
- **Existential Insights Panel** with weekly habit analysis and cosmic humor
- **Statistics dashboard** showing habit distribution and performance metrics
- Routes: `/habits`, `/habits/new`, `/habits/:id/edit`

### Agent 6: Calendar Integration & Meeting Analysis ✅
- **CalendarLive.Index** with meeting analysis dashboard and dual view modes
- **Meeting Categorization**: Standup, All Hands, 1:1, Brainstorm, Status Update, Other
- **Productivity Scoring System** (1-10 scale) with existential descriptions
- **"Could Have Been Email" tracking** with collective human hours lost calculations
- **Weekly Meeting Reports** with efficiency analysis and philosophical insights
- **Calendar Sync Service** ready for Google/Microsoft Calendar API integration
- **Advanced Analytics** including time allocation and meeting load classification
- **Mock data generators** for demonstration and development
- Route: `/calendar`

## Current Application State

### **Fully Functional Systems:**
- ✅ **Task Management** - Complete cosmic priority system with reality checks
- ✅ **Habit Tracking** - Existential habit categories with streak tracking  
- ✅ **Meeting Analysis** - Productivity scoring with philosophical commentary
- ✅ **Service Connections** - OAuth integration for Google/Microsoft services
- ✅ **Dashboard Navigation** - Integrated navigation between all systems

### **Database Schema Complete:**
- ✅ Users, Tasks, Habits, HabitEntries, Meetings, ServiceConnections
- ✅ All relationships and constraints properly defined
- ✅ Enum types for cosmic priorities, habit types, meeting types
- ✅ Comprehensive context modules with business logic

### **Infrastructure Ready:**
- ✅ OAuth tokens stored and managed for external API calls
- ✅ Background job system for token refresh
- ✅ LiveView streaming for real-time updates
- ✅ Consistent ironic UI tone with genuine functionality
- ✅ Mobile-responsive design with Tailwind CSS + DaisyUI

## Next Phase: Advanced Analytics & Intelligence

### **Agent 7: Email/Communication Intelligence** 🎯 **RECOMMENDED NEXT**
**Leverage existing OAuth infrastructure for email analysis**

**Core Features to Build:**
- Gmail/Outlook integration via existing OAuth connections
- Email pattern analysis (volume, response times, importance classification)
- "Urgent but not important" communication detection
- Digital minimalism suggestions and inbox philosophy
- Email productivity scoring similar to meeting analysis
- Integration with task/habit/meeting data for holistic insights

**Technical Foundation:**
- Use existing `ServiceConnection` OAuth tokens
- Create `Neptuner.Communications` context
- Build `CommunicationsLive.Index` with email analytics
- Email classification: `:urgent_important`, `:urgent_unimportant`, `:not_urgent_important`, `:digital_noise`

### **Agent 8: Cross-System Analytics & Insights Dashboard**
**Unified productivity intelligence across all systems**

**Core Features to Build:**
- Combined analytics across tasks, habits, meetings, emails
- "Cosmic Productivity Score" calculations based on all data sources
- Time-based trends and pattern recognition
- Comprehensive philosophical productivity reports
- Data visualization with existential commentary
- Weekly/monthly coaching insights

**Technical Foundation:**
- Create `Neptuner.Analytics` context with cross-system queries
- Build advanced statistical analysis functions
- Create `AnalyticsLive.Dashboard` with rich visualizations
- Implement trend analysis and predictive insights

### **Agent 9: AI-Powered Productivity Coaching**
**Personalized existential productivity guidance**

**Core Features to Build:**
- AI analysis of productivity patterns across all systems
- Personalized existential insights and recommendations
- Smart suggestions based on behavior patterns
- Weekly/monthly coaching reports with cosmic humor
- Integration with external AI services for advanced analysis

## Development Guidelines
- Follow CLAUDE.md instructions exactly (in codebase)
- Use TodoWrite tool to track progress throughout development
- No comments in code unless absolutely necessary  
- Keep functions small, self-documented, highly testable
- Use Phoenix LiveView with proper assigns and streams
- Maintain ironic tone in UI copy while ensuring genuine functionality
- Test after each major component implementation
- Run `mix format` and `mix compile --warnings-as-errors` before completion

## File Structure Context
- Main contexts in `lib/neptuner/`
- LiveViews in `lib/neptuner_web/live/`
- Routes in `lib/neptuner_web/router.ex` (use `:fully_authenticated_user` scope)
- Core components in `lib/neptuner_web/components/core_components.ex`
- OAuth integrations in existing service connection infrastructure

## Key Architectural Decisions Made
- **Separate OAuth system** from user authentication for service connections
- **Context-driven architecture** with clean separation of concerns
- **LiveView streaming** for real-time updates across all interfaces
- **Existential humor** balanced with genuine productivity value
- **Mobile-first responsive design** with consistent component patterns
- **Comprehensive statistics** with philosophical interpretations

## Expected Outcomes
The next agent should leverage the existing robust foundation of tasks, habits, meetings, and OAuth connections to create sophisticated analytics that provide genuine value while maintaining Neptuner's signature philosophical perspective on modern productivity culture.

**Agent 7 (Email Intelligence) Success Criteria:**
- Email analytics dashboard integrated with existing systems
- Smart classification of email importance vs urgency
- Digital communication insights with existential commentary
- Seamless integration with OAuth connection management
- Philosophical perspective on inbox management and digital minimalism

Start by examining the existing `Neptuner.Connections` context and OAuth infrastructure, then build the email analysis system that complements the existing task/habit/meeting triumvirate with communication intelligence.