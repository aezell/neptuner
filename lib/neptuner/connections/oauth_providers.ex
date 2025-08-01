defmodule Neptuner.Connections.OAuthProviders do
  @moduledoc """
  OAuth provider implementations for service connections.
  Handles Google, Microsoft, Apple, and CalDAV connections.
  """

  require Logger

  @google_auth_url "https://accounts.google.com/o/oauth2/v2/auth"
  @google_token_url "https://oauth2.googleapis.com/token"
  @google_userinfo_url "https://www.googleapis.com/oauth2/v2/userinfo"

  @microsoft_auth_url "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
  @microsoft_token_url "https://login.microsoftonline.com/common/oauth2/v2.0/token"
  @microsoft_userinfo_url "https://graph.microsoft.com/v1.0/me"

  @apple_auth_url "https://appleid.apple.com/auth/authorize"
  @apple_token_url "https://appleid.apple.com/auth/token"

  def get_authorization_url("google", service_type) do
    scopes = get_google_scopes(service_type)
    state = generate_state()

    params = %{
      client_id: get_google_client_id(),
      redirect_uri: get_callback_url("google"),
      response_type: "code",
      scope: Enum.join(scopes, " "),
      state: state,
      access_type: "offline",
      prompt: "consent"
    }

    url = build_auth_url(@google_auth_url, params)
    {:ok, url, state}
  end

  def get_authorization_url("microsoft", service_type) do
    scopes = get_microsoft_scopes(service_type)
    state = generate_state()

    params = %{
      client_id: get_microsoft_client_id(),
      redirect_uri: get_callback_url("microsoft"),
      response_type: "code",
      scope: Enum.join(scopes, " "),
      state: state,
      response_mode: "query"
    }

    url = build_auth_url(@microsoft_auth_url, params)
    {:ok, url, state}
  end

  def get_authorization_url("apple", service_type) do
    scopes = get_apple_scopes(service_type)
    state = generate_state()

    params = %{
      client_id: get_apple_client_id(),
      redirect_uri: get_callback_url("apple"),
      response_type: "code",
      scope: Enum.join(scopes, " "),
      state: state,
      response_mode: "form_post"
    }

    url = build_auth_url(@apple_auth_url, params)
    {:ok, url, state}
  end

  def get_authorization_url("caldav", _service_type) do
    # CalDAV doesn't use OAuth - it uses basic auth or app passwords
    # We'll handle this through a separate credential form
    {:error, "CalDAV uses direct credential authentication"}
  end

  def get_authorization_url(_provider, _service_type) do
    {:error, "Unsupported provider"}
  end

  @doc """
  Creates a CalDAV connection with provided credentials.
  CalDAV uses basic authentication with username/password or app-specific passwords.
  """
  def create_caldav_connection(user_id, attrs) do
    # Validate CalDAV server by attempting to connect
    case validate_caldav_credentials(attrs) do
      {:ok, server_info} ->
        connection_attrs = %{
          provider: :caldav,
          service_type: :calendar,
          external_account_id: attrs.username,
          external_account_email: attrs.username,
          display_name: server_info.display_name || attrs.username,
          # Store encrypted credentials instead of tokens
          access_token:
            encrypt_caldav_credentials(attrs.username, attrs.password, attrs.server_url),
          refresh_token: nil,
          token_expires_at: nil,
          scopes_granted: ["calendar:read", "calendar:write"],
          connection_status: :active
        }

        alias Neptuner.Connections
        Connections.create_service_connection(user_id, connection_attrs)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def exchange_code_for_tokens("google", code) do
    body = %{
      client_id: get_google_client_id(),
      client_secret: get_google_client_secret(),
      code: code,
      grant_type: "authorization_code",
      redirect_uri: get_callback_url("google")
    }

    case Req.post(@google_token_url, form: body) do
      {:ok, %{status: 200, body: response}} ->
        parse_google_token_response(response)

      {:ok, %{status: status, body: body}} ->
        Logger.error("Google token exchange failed: #{status} - #{inspect(body)}")
        {:error, "Token exchange failed"}

      {:error, reason} ->
        Logger.error("Google token exchange request failed: #{inspect(reason)}")
        {:error, "Network error during token exchange"}
    end
  end

  def exchange_code_for_tokens("microsoft", code) do
    body = %{
      client_id: get_microsoft_client_id(),
      client_secret: get_microsoft_client_secret(),
      code: code,
      grant_type: "authorization_code",
      redirect_uri: get_callback_url("microsoft")
    }

    case Req.post(@microsoft_token_url, form: body) do
      {:ok, %{status: 200, body: response}} ->
        parse_microsoft_token_response(response)

      {:ok, %{status: status, body: body}} ->
        Logger.error("Microsoft token exchange failed: #{status} - #{inspect(body)}")
        {:error, "Token exchange failed"}

      {:error, reason} ->
        Logger.error("Microsoft token exchange request failed: #{inspect(reason)}")
        {:error, "Network error during token exchange"}
    end
  end

  def exchange_code_for_tokens("apple", code) do
    with {:ok, client_secret} <- generate_apple_client_secret() do
      body = %{
        client_id: get_apple_client_id(),
        client_secret: client_secret,
        code: code,
        grant_type: "authorization_code",
        redirect_uri: get_callback_url("apple")
      }

      case Req.post(@apple_token_url, form: body) do
        {:ok, %{status: 200, body: response}} ->
          parse_apple_token_response(response)

        {:ok, %{status: status, body: body}} ->
          Logger.error("Apple token exchange failed: #{status} - #{inspect(body)}")
          {:error, "Token exchange failed"}

        {:error, reason} ->
          Logger.error("Apple token exchange request failed: #{inspect(reason)}")
          {:error, "Network error during token exchange"}
      end
    else
      {:error, reason} ->
        Logger.error("Failed to generate Apple client secret: #{inspect(reason)}")
        {:error, "Failed to generate client secret"}
    end
  end

  def get_account_info("google", access_token) do
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.get(@google_userinfo_url, headers: headers) do
      {:ok, %{status: 200, body: response}} ->
        {:ok,
         %{
           id: response["id"],
           email: response["email"],
           display_name: response["name"] || response["email"]
         }}

      {:error, reason} ->
        Logger.error("Failed to get Google account info: #{inspect(reason)}")
        {:error, "Failed to get account information"}
    end
  end

  def get_account_info("microsoft", access_token) do
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.get(@microsoft_userinfo_url, headers: headers) do
      {:ok, %{status: 200, body: response}} ->
        {:ok,
         %{
           id: response["id"],
           email: response["mail"] || response["userPrincipalName"],
           display_name:
             response["displayName"] || response["mail"] || response["userPrincipalName"]
         }}

      {:error, reason} ->
        Logger.error("Failed to get Microsoft account info: #{inspect(reason)}")
        {:error, "Failed to get account information"}
    end
  end

  def get_account_info("apple", _access_token) do
    # Apple doesn't provide a user info endpoint with access tokens
    # User info is typically provided in the ID token during initial auth
    # For now, we'll return a placeholder that can be updated when we have the ID token
    {:ok,
     %{
       id: "apple_user",
       email: "apple_user@privaterelay.appleid.com",
       display_name: "Apple User"
     }}
  end

  def get_account_info("caldav", _credentials) do
    # CalDAV account info is derived from the server and stored during connection
    {:error, "CalDAV account info stored during connection creation"}
  end

  def refresh_access_token("google", refresh_token) do
    body = %{
      client_id: get_google_client_id(),
      client_secret: get_google_client_secret(),
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    }

    case Req.post(@google_token_url, form: body) do
      {:ok, %{status: 200, body: response}} ->
        parse_google_token_response(response)

      {:error, reason} ->
        Logger.error("Google token refresh failed: #{inspect(reason)}")
        {:error, "Token refresh failed"}
    end
  end

  def refresh_access_token("microsoft", refresh_token) do
    body = %{
      client_id: get_microsoft_client_id(),
      client_secret: get_microsoft_client_secret(),
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    }

    case Req.post(@microsoft_token_url, form: body) do
      {:ok, %{status: 200, body: response}} ->
        parse_microsoft_token_response(response)

      {:error, reason} ->
        Logger.error("Microsoft token refresh failed: #{inspect(reason)}")
        {:error, "Token refresh failed"}
    end
  end

  def refresh_access_token("apple", refresh_token) do
    with {:ok, client_secret} <- generate_apple_client_secret() do
      body = %{
        client_id: get_apple_client_id(),
        client_secret: client_secret,
        refresh_token: refresh_token,
        grant_type: "refresh_token"
      }

      case Req.post(@apple_token_url, form: body) do
        {:ok, %{status: 200, body: response}} ->
          parse_apple_token_response(response)

        {:error, reason} ->
          Logger.error("Apple token refresh failed: #{inspect(reason)}")
          {:error, "Token refresh failed"}
      end
    else
      {:error, reason} ->
        Logger.error("Failed to generate Apple client secret for refresh: #{inspect(reason)}")
        {:error, "Failed to generate client secret"}
    end
  end

  def refresh_access_token("caldav", _refresh_token) do
    # CalDAV doesn't use refresh tokens - credentials are long-lived
    {:error, "CalDAV doesn't use refresh tokens"}
  end

  # Private functions

  defp get_google_scopes("calendar") do
    ["https://www.googleapis.com/auth/calendar.readonly", "email", "profile"]
  end

  defp get_google_scopes("email") do
    ["https://www.googleapis.com/auth/gmail.readonly", "email", "profile"]
  end

  defp get_google_scopes("tasks") do
    ["https://www.googleapis.com/auth/tasks", "email", "profile"]
  end

  defp get_microsoft_scopes("calendar") do
    ["https://graph.microsoft.com/Calendars.Read", "https://graph.microsoft.com/User.Read"]
  end

  defp get_microsoft_scopes("email") do
    ["https://graph.microsoft.com/Mail.Read", "https://graph.microsoft.com/User.Read"]
  end

  defp get_microsoft_scopes("tasks") do
    ["https://graph.microsoft.com/Tasks.ReadWrite", "https://graph.microsoft.com/User.Read"]
  end

  defp get_apple_scopes("calendar") do
    ["name", "email"]
  end

  defp get_apple_scopes("email") do
    ["name", "email"]
  end

  defp get_apple_scopes("tasks") do
    ["name", "email"]
  end

  defp generate_state do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp build_auth_url(base_url, params) do
    query_string = URI.encode_query(params)
    "#{base_url}?#{query_string}"
  end

  defp parse_google_token_response(response) do
    expires_at =
      if response["expires_in"] do
        DateTime.utc_now() |> DateTime.add(response["expires_in"], :second)
      else
        nil
      end

    {:ok,
     %{
       access_token: response["access_token"],
       refresh_token: response["refresh_token"],
       expires_at: expires_at,
       scopes: if(response["scope"], do: String.split(response["scope"], " "), else: [])
     }}
  end

  defp parse_microsoft_token_response(response) do
    expires_at =
      if response["expires_in"] do
        DateTime.utc_now() |> DateTime.add(response["expires_in"], :second)
      else
        nil
      end

    {:ok,
     %{
       access_token: response["access_token"],
       refresh_token: response["refresh_token"],
       expires_at: expires_at,
       scopes: if(response["scope"], do: String.split(response["scope"], " "), else: [])
     }}
  end

  defp parse_apple_token_response(response) do
    expires_at =
      if response["expires_in"] do
        DateTime.utc_now() |> DateTime.add(response["expires_in"], :second)
      else
        nil
      end

    {:ok,
     %{
       access_token: response["access_token"],
       refresh_token: response["refresh_token"],
       expires_at: expires_at,
       scopes: []
     }}
  end

  defp get_google_client_id do
    System.get_env("GOOGLE_OAUTH_CLIENT_ID") ||
      raise "GOOGLE_OAUTH_CLIENT_ID environment variable not set"
  end

  defp get_google_client_secret do
    System.get_env("GOOGLE_OAUTH_CLIENT_SECRET") ||
      raise "GOOGLE_OAUTH_CLIENT_SECRET environment variable not set"
  end

  defp get_microsoft_client_id do
    System.get_env("MICROSOFT_OAUTH_CLIENT_ID") ||
      raise "MICROSOFT_OAUTH_CLIENT_ID environment variable not set"
  end

  defp get_microsoft_client_secret do
    System.get_env("MICROSOFT_OAUTH_CLIENT_SECRET") ||
      raise "MICROSOFT_OAUTH_CLIENT_SECRET environment variable not set"
  end

  defp get_apple_client_id do
    System.get_env("APPLE_OAUTH_CLIENT_ID") ||
      raise "APPLE_OAUTH_CLIENT_ID environment variable not set"
  end

  defp get_apple_team_id do
    System.get_env("APPLE_OAUTH_TEAM_ID") ||
      raise "APPLE_OAUTH_TEAM_ID environment variable not set"
  end

  defp get_apple_key_id do
    System.get_env("APPLE_OAUTH_KEY_ID") ||
      raise "APPLE_OAUTH_KEY_ID environment variable not set"
  end

  defp get_apple_private_key_path do
    System.get_env("APPLE_OAUTH_PRIVATE_KEY_PATH") ||
      raise "APPLE_OAUTH_PRIVATE_KEY_PATH environment variable not set"
  end

  defp generate_apple_client_secret do
    try do
      # Read the private key
      private_key_path = get_apple_private_key_path()
      private_key = File.read!(private_key_path)

      # Create JWT headers
      headers = %{
        "alg" => "ES256",
        "kid" => get_apple_key_id()
      }

      # Create JWT payload
      now = System.system_time(:second)

      payload = %{
        "iss" => get_apple_team_id(),
        "iat" => now,
        # 1 hour
        "exp" => now + 3600,
        "aud" => "https://appleid.apple.com",
        "sub" => get_apple_client_id()
      }

      # Sign the JWT
      jwk = JOSE.JWK.from_pem(private_key)
      {_type, jwt} = JOSE.JWT.sign(jwk, headers, payload) |> JOSE.JWS.compact()

      {:ok, jwt}
    rescue
      e ->
        Logger.error("Failed to generate Apple client secret: #{inspect(e)}")
        {:error, "Failed to generate JWT"}
    end
  end

  defp validate_caldav_credentials(%{
         username: username,
         password: password,
         server_url: server_url
       }) do
    # Attempt to connect to CalDAV server using PROPFIND request
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{username}:#{password}")}"},
      {"Depth", "0"},
      {"Content-Type", "application/xml; charset=utf-8"}
    ]

    propfind_body = """
    <?xml version="1.0" encoding="utf-8" ?>
    <D:propfind xmlns:D="DAV:">
      <D:prop>
        <D:displayname />
        <D:resourcetype />
      </D:prop>
    </D:propfind>
    """

    case Req.request(method: :propfind, url: server_url, headers: headers, body: propfind_body) do
      {:ok, %{status: status}} when status in 200..299 ->
        {:ok, %{display_name: "CalDAV: #{server_url}", server_url: server_url}}

      {:ok, %{status: 401}} ->
        {:error, "Invalid credentials"}

      {:ok, %{status: status}} ->
        {:error, "Server error: #{status}"}

      {:error, reason} ->
        Logger.error("CalDAV validation failed: #{inspect(reason)}")
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  defp encrypt_caldav_credentials(username, password, server_url) do
    # In a real implementation, you'd want to use proper encryption
    # For now, we'll base64 encode the credentials as a simple example
    credentials = %{
      username: username,
      password: password,
      server_url: server_url
    }

    Jason.encode!(credentials) |> Base.encode64()
  end

  def decrypt_caldav_credentials(encrypted_credentials) do
    try do
      encrypted_credentials
      |> Base.decode64!()
      |> Jason.decode!()
      |> then(fn creds -> {:ok, creds} end)
    rescue
      _ -> {:error, "Failed to decrypt credentials"}
    end
  end

  defp get_callback_url(provider) do
    base_url = System.get_env("APP_URL") || "http://localhost:4000"
    "#{base_url}/oauth/#{provider}/callback"
  end
end
