# Neptuner Development Continuation - Agent 4: Task Management System

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

## Next Task: Agent 4 - Task Management System

Build the core task management interface with:

### Required Features:
1. **Task CRUD LiveView** with cosmic priority system
2. **Task dashboard** with filtering by cosmic priority and status  
3. **Auto-suggestion engine** that suggests most tasks "matter to nobody"
4. **Weekly Reality Check** showing breakdown of low-importance completed tasks
5. **Ironic but functional UI** that gently mocks productivity while being genuinely useful

### Key Requirements:
- Use existing `Neptuner.Tasks` context (already implemented)
- Build on `Tasks.Task` model with cosmic priorities: `:matters_10_years`, `:matters_10_days`, `:matters_to_nobody`
- Status tracking: `:pending`, `:completed`, `:abandoned_wisely`
- Integration with user's `total_meaningless_tasks_completed` counter
- Routes should go in `:fully_authenticated_user` live_session scope
- Follow Phoenix conventions and Neptuner's ironic tone

### Existing Infrastructure Available:
- Database models and contexts are complete and tested
- Authentication system with proper scopes
- Tailwind CSS with custom theme
- Component system in `core_components.ex`
- Task statistics functions already implemented in context

## Development Guidelines:
- Follow CLAUDE.md instructions exactly (in codebase)
- Use TodoWrite tool to track progress
- No comments in code unless absolutely necessary  
- Keep functions small, self-documented, highly testable
- Use Phoenix LiveView with proper assigns and streams
- Ironic tone in UI copy while maintaining genuine functionality
- Test after each major component

## File Structure Context:
- Main contexts in `lib/neptuner/`
- LiveViews in `lib/neptuner_web/live/`
- Routes in `lib/neptuner_web/router.ex` 
- Core components in `lib/neptuner_web/components/core_components.ex`

Start by examining the existing `Neptuner.Tasks` context and `Tasks.Task` model, then build the task management LiveView interface. The goal is to create something genuinely useful that happens to have a sense of humor about itself.