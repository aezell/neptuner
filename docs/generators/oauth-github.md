# GitHub OAuth Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The GitHub OAuth generator adds complete GitHub OAuth authentication functionality to your Phoenix SaaS template. It integrates with the existing authentication system, allowing users to sign in with their GitHub accounts alongside traditional email/password authentication.

## Installation

Run the generator from your project root:

```bash
mix neptuner.gen.oauth_github
```

To skip the interactive confirmation and apply changes immediately:

```bash
mix neptuner.gen.oauth_github --yes
```

## What It Does

The generator performs the following operations:

### Dependencies
- Adds `ueberauth_github (~> 0.8)` dependency to `mix.exs`

### Configuration
- Updates `config/config.exs` with Ueberauth configuration for GitHub provider
- Adds GitHub OAuth strategy configuration with environment variable support

### Database Schema
- Updates `User` schema with OAuth fields:
  - `is_oauth_user` (boolean, default: false)
  - `oauth_provider` (string, nullable)
- Creates database migration to add OAuth fields to users table
- Makes `hashed_password` nullable for OAuth users

### Authentication Logic
- Adds `oauth_registration_changeset/3` function to User schema
- Extends Accounts context with `register_oauth_user/1` function
- Creates `GitHubAuthController` to handle OAuth flow

### Routes
- Adds GitHub OAuth routes to router:
  - `GET /auth/github` - Initiates OAuth flow
  - `GET /auth/github/callback` - Handles OAuth callback

### UI Updates
- Adds "Login with GitHub" button to login page
- Integrates with existing authentication UI

### Environment Configuration
- Updates `.env.example` with GitHub OAuth environment variables

### Files Created
- `lib/neptuner_web/controllers/github_auth_controller.ex`
- Database migration file for OAuth user fields

### Files Modified
- `mix.exs` - Dependency addition
- `config/config.exs` - OAuth configuration
- `lib/neptuner/accounts/user.ex` - Schema and changeset updates
- `lib/neptuner/accounts.ex` - Context function addition
- `lib/neptuner_web/router.ex` - Route additions
- `lib/neptuner_web/live/user_live/login.ex` - UI button addition
- `.env.example` - Environment variable examples

## Configuration

### GitHub OAuth Application Setup

1. Visit [GitHub OAuth Apps](https://github.com/settings/applications/new)
2. Create a new OAuth App with these settings:
   - **Application name**: Your app name
   - **Homepage URL**: `http://localhost:4000` (development)
   - **Authorization callback URL**: `http://localhost:4000/auth/github/callback`

### Environment Variables

Add these variables to your `.env` file:

```bash
# GitHub OAuth Configuration
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
```

Replace `your_github_client_id` and `your_github_client_secret` with the values from your GitHub OAuth application.

### Database Migration

After running the generator, apply the database migration:

```bash
mix ecto.migrate
```

## Usage

### User Experience

1. Users visit the login page
2. Click "Login with GitHub" button
3. Redirected to GitHub for authorization
4. After approval, redirected back to your app
5. Automatically logged in (new users are registered automatically)

### Authentication Flow

The OAuth flow works as follows:

1. **Initial Request**: User clicks GitHub login button → `/auth/github`
2. **GitHub Authorization**: Redirected to GitHub OAuth page
3. **Callback**: GitHub redirects to `/auth/github/callback` with auth code
4. **User Lookup**: System checks if user exists by email
5. **Registration/Login**: 
   - If user doesn't exist: Creates new OAuth user account
   - If user exists: Logs in existing user

### Integration with Existing Authentication

- OAuth users and regular users share the same User schema
- OAuth users have `is_oauth_user: true` and `oauth_provider: "github"`
- OAuth users don't have a `hashed_password` (it's nullable)
- All existing authentication features work with OAuth users

## Examples

### Controller Usage

The generated `GitHubAuthController` handles the OAuth flow:

```elixir
defmodule NeptunerWeb.GitHubAuthController do
  use NeptunerWeb, :controller
  alias Neptuner.Accounts
  alias NeptunerWeb.UserAuth
  
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email
    
    case Accounts.get_user_by_email(email) do
      nil ->
        # Create new OAuth user
        user_params = %{email: email, oauth_provider: "github"}
        case Accounts.register_oauth_user(user_params) do
          {:ok, user} -> UserAuth.log_in_user(conn, user)
          {:error, _} -> redirect(conn, to: ~p"/")
        end
      
      user ->
        # Login existing user
        UserAuth.log_in_user(conn, user)
    end
  end
end
```

### User Schema Changes

The User schema is extended with OAuth fields:

```elixir
schema "users" do
  field :email, :string
  field :hashed_password, :string  # Now nullable
  field :is_oauth_user, :boolean, default: false
  field :oauth_provider, :string
  # ... other fields
end

def oauth_registration_changeset(user, attrs, opts \\ []) do
  user
  |> cast(attrs, [:email, :oauth_provider])
  |> validate_required([:email, :oauth_provider])
  |> validate_email(opts)
  |> put_change(:is_oauth_user, true)
end
```

## Next Steps

After installation:

1. **Set up GitHub OAuth App** (see Configuration section)
2. **Configure environment variables**
3. **Run database migration**: `mix ecto.migrate`
4. **Test the OAuth flow** in development
5. **Update production callback URL** when deploying
6. **Consider adding additional OAuth providers** (Google, etc.)

### Production Deployment

For production, update your GitHub OAuth application settings:

- **Homepage URL**: `https://yourdomain.com`
- **Authorization callback URL**: `https://yourdomain.com/auth/github/callback`

Ensure your production environment has the correct `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` values.

### Security Considerations

- GitHub OAuth tokens are handled by the Ueberauth library
- No sensitive data is stored in your database
- Users can only access their own account information
- OAuth flow uses secure HTTPS in production

### Troubleshooting

Common issues and solutions:

- **"Invalid client" error**: Check your GitHub Client ID and Secret
- **"Redirect URI mismatch"**: Ensure callback URL matches GitHub app settings
- **Database errors**: Run `mix ecto.migrate` to apply OAuth schema changes
- **Missing login button**: Check that the login page was properly updated

The GitHub OAuth integration provides a seamless authentication experience while maintaining security and compatibility with your existing authentication system.