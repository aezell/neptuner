# Admin Password Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Admin Password Generator configures secure Basic Auth protection for admin-only features in your Phoenix SaaS application. It automatically generates a cryptographically secure password, updates configuration files to use environment variables, and creates the necessary `.env` files for secure password management.

## Installation

Run the generator using the Mix task:

```bash
# Generate with automatic secure password
mix neptuner.gen.admin_password

# Generate with custom password
mix neptuner.gen.admin_password --password "my_secure_password"
```

## What It Does

The generator performs the following operations:

### 1. Configuration Updates (`config/config.exs`)
- Adds or updates basic auth configuration to use environment variables
- Replaces any hardcoded passwords with `System.get_env("ADMIN_PASSWORD", "admin123")`
- Maintains the default username as "admin"

### 2. Environment File Management
- **`.env.example`**: Updates or adds `ADMIN_PASSWORD` entry for team reference
- **`.env`**: Creates or updates local environment file with the generated password

### 3. Password Generation
- Generates a 16-character cryptographically secure password using `:crypto.strong_rand_bytes/1`
- Base64 encoded for safe storage and transmission
- Automatically generated if no custom password is provided

## Configuration

After running the generator, your configuration will include:

```elixir
# config/config.exs
config :neptuner, :basic_auth, 
  username: "admin", 
  password: System.get_env("ADMIN_PASSWORD", "admin123")
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ADMIN_PASSWORD` | The admin panel password | `admin123` |

## Usage

Once installed, the admin password protects access to:

### Admin Routes
- **Feature Flags UI**: `http://localhost:4000/feature-flags`
- **Other Admin Pages**: `http://localhost:4000/admin/*`

### Authentication
- **Username**: `admin` (fixed)
- **Password**: The generated password (stored in `.env` file)

### Accessing Protected Areas
1. Navigate to any admin route
2. Browser will prompt for Basic Auth credentials
3. Enter username: `admin` and the generated password
4. Access will be granted for the browser session

## Examples

### Basic Usage
```bash
$ mix neptuner.gen.admin_password

## Admin Password Updated! ✅

Your admin password has been successfully configured.

### Configuration Updated:
- config/config.exs now uses ADMIN_PASSWORD environment variable
- .env.example updated with new password
- .env file created/updated with password: K2mN8pQ7vX1zR4sY
- Username remains: admin
```

### Custom Password
```bash
$ mix neptuner.gen.admin_password --password "super_secret_admin_pass"

## Admin Password Updated! ✅

Your admin password has been successfully configured.

### Configuration Updated:
- config/config.exs now uses ADMIN_PASSWORD environment variable
- .env.example updated with new password
- .env file created/updated with password: super_secret_admin_pass
- Username remains: admin
```

### Environment File Contents

After running the generator, your `.env` file will contain:

```bash
# Admin panel basic auth password
ADMIN_PASSWORD=K2mN8pQ7vX1zR4sY
```

## Security Features

### Password Security
- **Cryptographically Secure**: Uses `:crypto.strong_rand_bytes/1` for random generation
- **Appropriate Length**: 16 characters provides strong security
- **Base64 Encoding**: Safe for environment variable storage

### Configuration Security
- **Environment Variables**: Passwords never hardcoded in source code
- **Git Ignored**: `.env` file automatically excluded from version control
- **Team Sharing**: `.env.example` provides template without exposing actual password

### Access Control
- **Basic Auth**: Industry-standard HTTP authentication
- **Session-Based**: Authentication persists for browser session
- **Route Protection**: Secures all admin routes with single configuration

## Next Steps

After installation:

1. **Start Your Server**: `mix phx.server`
2. **Test Admin Access**: Navigate to `http://localhost:4000/feature-flags`
3. **Use Admin Credentials**: Username: `admin`, Password: [generated password from output]
4. **Share with Team**: Provide team members with the password from `.env.example`
5. **Production Deployment**: Ensure `ADMIN_PASSWORD` environment variable is set in production

### Production Considerations

- Set `ADMIN_PASSWORD` in your production environment
- Use a secure password manager for team password sharing
- Consider implementing more robust authentication for production use
- Monitor admin access logs for security auditing

### Troubleshooting

If admin access isn't working:
1. Check that `.env` file exists and contains `ADMIN_PASSWORD`
2. Restart your Phoenix server after running the generator
3. Verify the password matches between `.env` and your login attempt
4. Check that basic auth configuration is present in `config/config.exs`