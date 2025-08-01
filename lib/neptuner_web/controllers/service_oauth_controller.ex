defmodule NeptunerWeb.ServiceOAuthController do
  use NeptunerWeb, :controller
  require Logger

  alias Neptuner.Connections
  alias Neptuner.Connections.OAuthProviders

  def connect(conn, %{"provider" => provider, "service_type" => service_type}) do
    current_user = conn.assigns.current_scope.user

    case OAuthProviders.get_authorization_url(provider, service_type) do
      {:ok, auth_url, state} ->
        # Store the state and service info in the session for security
        conn
        |> put_session(:oauth_state, state)
        |> put_session(:oauth_provider, provider)
        |> put_session(:oauth_service_type, service_type)
        |> put_session(:oauth_user_id, current_user.id)
        |> redirect(external: auth_url)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to initiate connection: #{reason}")
        |> redirect(to: ~p"/dashboard")
    end
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    with {:ok, session_state} <- get_session_value(conn, :oauth_state),
         {:ok, provider} <- get_session_value(conn, :oauth_provider),
         {:ok, service_type} <- get_session_value(conn, :oauth_service_type),
         {:ok, user_id} <- get_session_value(conn, :oauth_user_id),
         :ok <- validate_state(state, session_state),
         {:ok, token_data} <- OAuthProviders.exchange_code_for_tokens(provider, code),
         {:ok, account_info} <-
           OAuthProviders.get_account_info(provider, token_data.access_token),
         {:ok, _connection} <-
           create_service_connection(user_id, provider, service_type, token_data, account_info) do
      conn
      |> clear_oauth_session()
      |> put_flash(
        :info,
        "Successfully connected your #{String.capitalize(provider)} #{service_type} account!"
      )
      |> redirect(to: ~p"/dashboard")
    else
      {:error, reason} ->
        Logger.error("OAuth callback failed: #{inspect(reason)}")

        conn
        |> clear_oauth_session()
        |> put_flash(:error, "Failed to connect account: #{reason}")
        |> redirect(to: ~p"/dashboard")

      error ->
        Logger.error("OAuth callback unexpected error: #{inspect(error)}")

        conn
        |> clear_oauth_session()
        |> put_flash(:error, "An unexpected error occurred while connecting your account.")
        |> redirect(to: ~p"/dashboard")
    end
  end

  def callback(conn, %{"error" => error}) do
    Logger.warning("OAuth callback received error: #{error}")

    conn
    |> clear_oauth_session()
    |> put_flash(:error, "Connection cancelled or failed: #{error}")
    |> redirect(to: ~p"/dashboard")
  end

  def disconnect(conn, %{"id" => connection_id}) do
    current_user = conn.assigns.current_scope.user

    connection = Connections.get_user_service_connection!(current_user.id, connection_id)

    case Connections.delete_service_connection(connection) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Account disconnected successfully.")
        |> redirect(to: ~p"/dashboard")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to disconnect account.")
        |> redirect(to: ~p"/dashboard")
    end
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_flash(:error, "Connection not found.")
      |> redirect(to: ~p"/dashboard")
  end

  defp get_session_value(conn, key) do
    case get_session(conn, key) do
      nil -> {:error, "Missing session value for #{key}"}
      value -> {:ok, value}
    end
  end

  defp validate_state(received_state, session_state) do
    if received_state == session_state do
      :ok
    else
      {:error, "Invalid state parameter - possible CSRF attack"}
    end
  end

  defp create_service_connection(user_id, provider, service_type, token_data, account_info) do
    attrs = %{
      provider: String.to_atom(provider),
      service_type: String.to_atom(service_type),
      external_account_id: account_info.id,
      external_account_email: account_info.email,
      display_name: account_info.display_name,
      access_token: token_data.access_token,
      refresh_token: token_data.refresh_token,
      token_expires_at: token_data.expires_at,
      scopes_granted: token_data.scopes || [],
      connection_status: :active
    }

    Connections.create_service_connection(user_id, attrs)
  end

  defp clear_oauth_session(conn) do
    conn
    |> delete_session(:oauth_state)
    |> delete_session(:oauth_provider)
    |> delete_session(:oauth_service_type)
    |> delete_session(:oauth_user_id)
  end
end
