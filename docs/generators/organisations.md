# Organisations Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Organisations generator adds complete multi-tenancy functionality to your Phoenix SaaS template. It implements a comprehensive organisation system with role-based access control, invitation workflows, and team management capabilities. This generator transforms your single-user application into a multi-tenant SaaS platform where users can create and manage organisations with team members.

## Installation

```bash
mix neptuner.gen.organisations
```

The generator uses Igniter to safely modify existing files and create new ones. It will show you a preview of all changes before applying them.

## What It Does

### Database Schema

The generator creates three main database tables:

- **organisations**: Stores organisation information with UUID primary keys
- **organisation_members**: Junction table managing user-organisation relationships with roles
- **organisation_invitations**: Handles email-based invitation system with token validation

### Core Modules Created

- **Neptuner.Organisations**: Main context module with full CRUD operations
- **Neptuner.Organisations.Organisation**: Organisation schema
- **Neptuner.Organisations.OrganisationMember**: Membership schema with role management
- **Neptuner.Organisations.OrganisationInvitation**: Invitation schema with expiration handling

### LiveView Components

- **OrganisationsLive.New**: Organisation creation interface
- **OrganisationsLive.Manage**: Team management dashboard with member invitation/removal
- **OrganisationsLive.Invitation**: Invitation acceptance flow

### Authentication & Authorization Updates

- Updates `Neptuner.Accounts.Scope` to include organisation context
- Adds organisation-aware authentication plugs to `UserAuth`
- Implements role-based permission checking
- Creates LiveView hooks for organisation requirements

### Files Created

```
lib/neptuner/organisations.ex
lib/neptuner/organisations/organisation.ex
lib/neptuner/organisations/organisation_member.ex
lib/neptuner/organisations/organisation_invitation.ex
lib/neptuner_web/live/organisations_live/manage.ex
lib/neptuner_web/live/organisations_live/new.ex
lib/neptuner_web/live/organisations_live/invitation.ex
priv/repo/migrations/TIMESTAMP_create_organisations_and_members.exs
priv/repo/migrations/TIMESTAMP_create_organisation_invitations.exs
```

### Files Updated

- `config/config.exs`: Adds organisation scope configuration
- `lib/neptuner/accounts/user.ex`: Adds organisation relationships
- `lib/neptuner/accounts/scope.ex`: Adds organisation context helpers
- `lib/neptuner/accounts/user_notifier.ex`: Adds invitation email templates
- `lib/neptuner_web/router.ex`: Adds organisation routes with proper authentication
- `lib/neptuner_web/user_auth.ex`: Adds organisation auth hooks
- `lib/neptuner_web/components/layouts.ex`: Adds organisation navigation

## Configuration

The generator automatically configures the scope system in `config/config.exs`:

```elixir
config :neptuner, Neptuner.Accounts.Scope,
  scopes: [
    # ... existing user scope
    organisation: [
      module: Neptuner.Accounts.Scope,
      assign_key: :current_scope,
      access_path: [:organisation, :id],
      schema_key: :org_id,
      schema_type: :id,
      schema_table: :organisations,
      test_data_fixture: Neptuner.AccountsFixtures,
      test_login_helper: :register_and_log_in_user_with_org
    ]
  ]
```

## Usage

### After Installation

1. **Run the migrations**:
   ```bash
   mix ecto.migrate
   ```

2. **Restart your Phoenix server**:
   ```bash
   mix phx.server
   ```

### User Flow

1. **User Registration**: After registering, users are redirected to create an organisation
2. **Organisation Creation**: Users create an organisation and become the owner
3. **Team Invitation**: Owners and admins can invite members via email
4. **Invitation Acceptance**: Invited users receive emails with acceptance links
5. **Team Management**: Manage roles, remove members, and edit organisation details

### Role-Based Access Control

The system implements three permission levels:

- **Owner**: Full access to all organisation functions
- **Admin**: Can manage team members and organisation settings
- **Member**: Basic access to organisation resources

### Accessing Organisation Data

In LiveViews and controllers, organisation data is available through the scope:

```elixir
# Get current organisation
organisation = socket.assigns.current_scope.organisation

# Get user's role
role = socket.assigns.current_scope.organisation_role

# Check permissions
can_manage = Neptuner.Accounts.Scope.can_manage_organisation?(socket.assigns.current_scope)
```

## Examples

### Creating Organisation-Scoped Queries

```elixir
# In your context modules
def list_posts_for_organisation(organisation) do
  from(p in Post, where: p.org_id == ^organisation.id)
  |> Repo.all()
end

# In LiveViews
def mount(_params, _session, socket) do
  organisation = socket.assigns.current_scope.organisation
  posts = MyApp.Posts.list_posts_for_organisation(organisation)
  {:ok, assign(socket, :posts, posts)}
end
```

### Permission Checking

```elixir
# In LiveViews
def handle_event("delete_post", %{"id" => id}, socket) do
  if Neptuner.Accounts.Scope.can_manage_organisation?(socket.assigns.current_scope) do
    # Allow deletion
  else
    {:noreply, put_flash(socket, :error, "You don't have permission to delete posts")}
  end
end
```

### Inviting Users

```elixir
# In your LiveView or controller
organisation = socket.assigns.current_scope.organisation
inviter = socket.assigns.current_scope.user

case Neptuner.Organisations.invite_user_to_organisation(
  organisation,
  inviter,
  %{email: "user@example.com", role: "member"},
  &url(~p"/invitations/accept/#{&1}")
) do
  {:ok, _invitation} ->
    # Success - invitation sent
  {:error, :already_member} ->
    # User is already a member
  {:error, changeset} ->
    # Validation errors
end
```

## Next Steps

1. **Add Organisation Scoping**: Update your existing schemas to include `org_id` fields
2. **Customize Invitation Emails**: Modify the email template in `UserNotifier`
3. **Implement Data Scoping**: Add organisation-based filtering to all queries
4. **Add Organisation Settings**: Extend the organisation schema with additional fields
5. **Create Organisation-Specific Features**: Build features that leverage the multi-tenant architecture

### Routes Available

- `/organisations/new` - Create new organisation (authenticated users without organisation)
- `/organisations/manage` - Manage organisation and team members (requires organisation)
- `/invitations/accept/:token` - Accept invitation via email link
- `/dashboard` - Main dashboard (requires organisation)

### Environment Variables

The generator uses the existing email configuration. Ensure you have configured:

```elixir
# config/dev.exs or config/prod.exs
config :neptuner, Neptuner.Mailer,
  adapter: Swoosh.Adapters.Local # or your preferred adapter
```

This generator provides a solid foundation for building multi-tenant SaaS applications with comprehensive team management capabilities.