# Google OAuth Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Google OAuth generator integrates Google OAuth authentication into your Phoenix SaaS template. It provides a complete implementation that allows users to sign in with their Google accounts, automatically creating new accounts for first-time users and logging in existing users with matching email addresses.

## Installation

Run the generator from the project root:

```bash
mix neptuner.gen.oauth_google
```

After installation, you'll need to run the database migration:

```bash
mix ecto.migrate
```

## What It Does

The generator makes comprehensive changes to your application:

### Dependencies Added
- Adds `ueberauth_google (~> 0.10)` to `mix.exs` for Google OAuth strategy

### Configuration Files
- **config/config.exs**: Adds Ueberauth configuration with Google strategy
- **.env.example**: Adds Google OAuth environment variables

### Database Changes
- Creates a migration to add OAuth fields to the `users` table:
  - `is_oauth_user` (boolean, default: false)
  - `oauth_provider` (string, nullable)
  - Modifies `hashed_password` to be nullable for OAuth users

### Schema Updates
- **lib/neptuner/accounts/user.ex**: 
  - Adds OAuth fields to the User schema
  - Adds `oauth_registration_changeset/2` function for OAuth user registration

### Context Updates
- **lib/neptuner/accounts.ex**:
  - Adds `register_oauth_user/1` function for creating OAuth users

### Controller Creation
- **lib/neptuner_web/controllers/google_auth_controller.ex**: New controller handling OAuth flow with two actions:
  - `request/2`: Initiates OAuth request
  - `callback/2`: Handles OAuth callback and user registration/login

### Router Updates
- **lib/neptuner_web/router.ex**: Adds OAuth routes under `/auth` scope:
  - `GET /auth/google` - OAuth request
  - `GET /auth/google/callback` - OAuth callback

### UI Updates
- **lib/neptuner_web/live/user_live/login.ex**: Adds "Login with Google" button to the login page

## Configuration

### Environment Variables

The generator adds the following environment variables to `.env.example`:

```bash
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### Google OAuth Setup

1. **Create Google OAuth Credentials**:
   - Visit [Google Cloud Console](https://console.developers.google.com/)
   - Create a new project or select an existing one
   - Enable the Google+ API
   - Create OAuth 2.0 credentials
   - Set authorized redirect URI: `http://localhost:4000/auth/google/callback`

2. **Configure Environment Variables**:
   - Copy `.env.example` to `.env` (if not already done)
   - Replace placeholder values with your actual Google OAuth credentials:
     ```bash
     GOOGLE_CLIENT_ID=your_actual_google_client_id
     GOOGLE_CLIENT_SECRET=your_actual_google_client_secret
     ```

3. **Production Configuration**:
   - Update the authorized redirect URI for your production domain
   - Example: `https://yourdomain.com/auth/google/callback`

## Usage

### User Authentication Flow

1. **New Users**:
   - Click "Login with Google" on the login page
   - Authenticate with Google
   - System automatically creates a new account with:
     - Email from Google profile
     - `is_oauth_user: true`
     - `oauth_provider: "google"`
     - No password (OAuth users don't need passwords)

2. **Existing Users**:
   - Users with matching email addresses are automatically logged in
   - System updates their session without requiring password

### OAuth User Properties

OAuth users have the following characteristics:
- `is_oauth_user` field is set to `true`
- `oauth_provider` field is set to `"google"`
- `hashed_password` field is `nil` (OAuth users don't have passwords)
- Can only authenticate via Google OAuth

## Examples

### Accessing OAuth User Information

```elixir
# Check if user is an OAuth user
if user.is_oauth_user do
  # Handle OAuth user logic
  provider = user.oauth_provider # "google"
end

# Get OAuth users
oauth_users = Accounts.list_users()
|> Enum.filter(& &1.is_oauth_user)
```

### Customizing OAuth Flow

The OAuth controller can be customized to handle additional user data:

```elixir
def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
  email = auth.info.email
  name = auth.info.name  # Additional user info
  
  # Custom user creation logic
  user_params = %{
    email: email,
    name: name,  # If you have a name field
    oauth_provider: "google"
  }
  
  # Rest of the callback logic...
end
```

## Next Steps

After installation and configuration:

1. **Test the OAuth Flow**:
   - Start your Phoenix server: `mix phx.server`
   - Navigate to `/users/log_in`
   - Click "Login with Google" and test the authentication

2. **Customize User Registration**:
   - Modify `oauth_registration_changeset/2` to include additional fields
   - Update the callback controller to handle more user data from Google

3. **Add Additional OAuth Providers**:
   - The Ueberauth library supports many providers (Facebook, GitHub, etc.)
   - Follow similar patterns to add more OAuth options

4. **Handle User Profiles**:
   - Consider adding user profile management for OAuth users
   - Implement profile picture handling using Google's profile image URLs

5. **Security Considerations**:
   - Implement proper error handling for OAuth failures
   - Consider email verification requirements for your application
   - Review and customize the OAuth scope permissions as needed

The Google OAuth integration provides a seamless authentication experience while maintaining the flexibility to customize the user registration and login process according to your application's needs.