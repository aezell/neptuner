# OAuth Setup for Service Connections

This document explains how to set up OAuth applications for Google and Microsoft to enable service connections in Neptuner.

## Overview

Neptuner uses **two separate OAuth systems**:

1. **User Authentication** - For logging users into Neptuner (uses existing Google/GitHub OAuth)
2. **Service Connections** - For connecting external accounts to sync calendars, emails, and tasks

This guide covers setting up the **Service Connections** OAuth applications.

## Google OAuth Setup

### 1. Create a Google Cloud Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the required APIs:
   - Google Calendar API
   - Gmail API
   - Google Tasks API
   - Google+ API (for user info)

### 2. Configure OAuth Consent Screen

1. Go to "APIs & Services" → "OAuth consent screen"
2. Choose "External" user type (or "Internal" if using Google Workspace)
3. Fill in the required information:
   - App name: "Neptuner"
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/calendar.readonly`
   - `https://www.googleapis.com/auth/gmail.readonly`
   - `https://www.googleapis.com/auth/tasks`
   - `email`
   - `profile`

### 3. Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client IDs"
3. Select "Web application"
4. Add authorized redirect URIs:
   - `http://localhost:4000/oauth/google/callback` (development)
   - `https://yourdomain.com/oauth/google/callback` (production)
5. Note the Client ID and Client Secret

### 4. Update Environment Variables

Add to your `.env` file:

```bash
GOOGLE_OAUTH_CLIENT_ID=your_google_client_id_here
GOOGLE_OAUTH_CLIENT_SECRET=your_google_client_secret_here
```

## Microsoft OAuth Setup

### 1. Register an Application

1. Go to the [Azure Portal](https://portal.azure.com/)
2. Navigate to "Microsoft Entra ID" (formerly Azure AD)
3. Go to "App registrations" → "New registration"
4. Fill in the details:
   - Name: "Neptuner Service Connections"
   - Supported account types: "Accounts in any organizational directory and personal Microsoft accounts"
   - Redirect URI: 
     - Platform: Web
     - URI: `http://localhost:4000/oauth/microsoft/callback` (add production URI later)

### 2. Configure API Permissions

1. In your app registration, go to "API permissions"
2. Click "Add a permission" → "Microsoft Graph"
3. Select "Delegated permissions" and add:
   - `Calendars.Read`
   - `Mail.Read`
   - `Tasks.ReadWrite`
   - `User.Read`
4. Click "Grant admin consent" if you have admin privileges

### 3. Create Client Secret

1. Go to "Certificates & secrets"
2. Click "New client secret"
3. Add a description and set expiration
4. Note the secret value (you can only see it once!)

### 4. Update Environment Variables

Add to your `.env` file:

```bash
MICROSOFT_OAUTH_CLIENT_ID=your_microsoft_client_id_here
MICROSOFT_OAUTH_CLIENT_SECRET=your_microsoft_client_secret_here
```

## Testing the Setup

1. Start your Phoenix server: `mix phx.server`
2. Register/login to Neptuner
3. Go to `/connections` in your browser
4. Try connecting a Google or Microsoft account
5. Check the server logs for any OAuth errors

## Security Notes

- Keep your client secrets secure and never commit them to version control
- Use different OAuth applications for development and production
- Regularly rotate client secrets
- Monitor OAuth usage in the respective admin consoles

## Troubleshooting

### Common Google Issues

- **"Error 400: redirect_uri_mismatch"**: Check that your redirect URI exactly matches what's configured in Google Cloud Console
- **"Access blocked"**: Make sure your OAuth consent screen is properly configured and published
- **Scope errors**: Ensure all required APIs are enabled in Google Cloud Console

### Common Microsoft Issues

- **"AADSTS50011"**: The redirect URI doesn't match the registered URI
- **"Insufficient privileges"**: Check that API permissions are granted and admin consent is provided
- **Token errors**: Verify the client secret hasn't expired

### General Issues

- Check server logs for detailed error messages
- Verify environment variables are loaded correctly
- Ensure `APP_URL` is set correctly in your environment
- Check that the callback routes are properly configured in the router

## Adding Apple OAuth (Future)

Apple OAuth implementation is planned but not yet implemented. When ready, you'll need to:

1. Set up an Apple Developer account
2. Create a Services ID in the Apple Developer portal
3. Configure Sign in with Apple
4. Add the necessary environment variables

## CalDAV Connections (Future)

CalDAV connections will use basic authentication or app-specific passwords rather than OAuth, as most CalDAV servers don't support OAuth 2.0.