defmodule Neptuner.Connections do
  @moduledoc """
  The Connections context for managing service connections.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo

  alias Neptuner.Connections.ServiceConnection

  def list_service_connections(user_id) do
    ServiceConnection
    |> where([sc], sc.user_id == ^user_id)
    |> order_by([sc], asc: sc.provider, asc: sc.service_type)
    |> Repo.all()
  end

  def list_service_connections_by_type(user_id, service_type) do
    ServiceConnection
    |> where([sc], sc.user_id == ^user_id and sc.service_type == ^service_type)
    |> where([sc], sc.connection_status == :active)
    |> Repo.all()
  end

  def get_service_connection!(id), do: Repo.get!(ServiceConnection, id)

  def get_user_service_connection!(user_id, id) do
    ServiceConnection
    |> where([sc], sc.user_id == ^user_id and sc.id == ^id)
    |> Repo.one!()
  end

  def create_service_connection(user_id, attrs \\ %{}) do
    %ServiceConnection{}
    |> ServiceConnection.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Repo.insert()
  end

  def update_service_connection(%ServiceConnection{} = service_connection, attrs) do
    service_connection
    |> ServiceConnection.changeset(attrs)
    |> Repo.update()
  end

  def delete_service_connection(%ServiceConnection{} = service_connection) do
    Repo.delete(service_connection)
  end

  def change_service_connection(%ServiceConnection{} = service_connection, attrs \\ %{}) do
    ServiceConnection.changeset(service_connection, attrs)
  end

  def get_calendar_connections(user_id) do
    list_service_connections_by_type(user_id, :calendar)
  end

  def get_email_connections(user_id) do
    list_service_connections_by_type(user_id, :email)
  end

  def get_task_connections(user_id) do
    list_service_connections_by_type(user_id, :tasks)
  end

  def mark_connection_expired(%ServiceConnection{} = service_connection) do
    update_service_connection(service_connection, %{connection_status: :expired})
  end

  def mark_connection_error(%ServiceConnection{} = service_connection) do
    update_service_connection(service_connection, %{connection_status: :error})
  end

  def refresh_connection_token(
        %ServiceConnection{} = service_connection,
        new_access_token,
        new_refresh_token,
        expires_at
      ) do
    update_service_connection(service_connection, %{
      access_token: new_access_token,
      refresh_token: new_refresh_token,
      token_expires_at: expires_at,
      connection_status: :active
    })
  end

  def update_last_sync(%ServiceConnection{} = service_connection) do
    update_service_connection(service_connection, %{last_sync_at: DateTime.utc_now()})
  end

  def get_connections_needing_refresh do
    ServiceConnection
    |> where([sc], sc.connection_status in [:active, :expired])
    |> where([sc], sc.token_expires_at < ^DateTime.utc_now() or sc.connection_status == :expired)
    |> Repo.all()
  end

  @doc """
  Refreshes the access token for a service connection using its refresh token.
  """
  def refresh_service_connection_token(%ServiceConnection{} = connection) do
    alias Neptuner.Connections.OAuthProviders

    provider = Atom.to_string(connection.provider)

    case OAuthProviders.refresh_access_token(provider, connection.refresh_token) do
      {:ok, token_data} ->
        update_service_connection(connection, %{
          access_token: token_data.access_token,
          refresh_token: token_data.refresh_token || connection.refresh_token,
          token_expires_at: token_data.expires_at,
          connection_status: :active
        })

      {:error, reason} ->
        update_service_connection(connection, %{connection_status: :expired})
        {:error, reason}
    end
  end

  def get_connection_statistics(user_id) do
    connections = list_service_connections(user_id)

    %{
      total_connections: length(connections),
      active_connections: Enum.count(connections, &(&1.connection_status == :active)),
      expired_connections: Enum.count(connections, &(&1.connection_status == :expired)),
      error_connections: Enum.count(connections, &(&1.connection_status == :error)),
      calendar_connections: Enum.count(connections, &(&1.service_type == :calendar)),
      email_connections: Enum.count(connections, &(&1.service_type == :email)),
      task_connections: Enum.count(connections, &(&1.service_type == :tasks)),
      google_connections: Enum.count(connections, &(&1.provider == :google)),
      microsoft_connections: Enum.count(connections, &(&1.provider == :microsoft)),
      apple_connections: Enum.count(connections, &(&1.provider == :apple)),
      caldav_connections: Enum.count(connections, &(&1.provider == :caldav))
    }
  end
end
