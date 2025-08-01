defmodule Neptuner.Integrations.IntegrationCoordinator do
  @moduledoc """
  Coordinates synchronization across multiple integration providers.
  Provides unified interface for Google, Microsoft, and other service integrations.
  """

  require Logger
  alias Neptuner.Connections
  alias Neptuner.Connections.ServiceConnection
  alias Neptuner.Integrations.{GoogleCalendar, Gmail, MicrosoftCalendar, MicrosoftOutlook}

  @doc """
  Syncs all calendar connections for a user across all providers.
  Returns summary of sync results.
  """
  def sync_all_calendars(user_id) do
    calendar_connections = Connections.get_calendar_connections(user_id)

    results =
      calendar_connections
      |> Enum.map(&sync_calendar_connection/1)
      |> Enum.group_by(fn {status, _provider, _count} -> status end)

    successful = Map.get(results, :ok, [])
    failed = Map.get(results, :error, [])

    total_synced = successful |> Enum.map(fn {_, _, count} -> count end) |> Enum.sum()

    Logger.info(
      "Calendar sync completed for user #{user_id}: #{total_synced} events synced across #{length(successful)} providers, #{length(failed)} failed"
    )

    %{
      total_events_synced: total_synced,
      successful_providers: length(successful),
      failed_providers: length(failed),
      providers_synced: successful |> Enum.map(fn {_, provider, count} -> {provider, count} end),
      errors: failed |> Enum.map(fn {_, provider, reason} -> {provider, reason} end)
    }
  end

  @doc """
  Syncs all email connections for a user across all providers.
  Returns summary of sync results.
  """
  def sync_all_emails(user_id) do
    email_connections = Connections.get_email_connections(user_id)

    results =
      email_connections
      |> Enum.map(&sync_email_connection/1)
      |> Enum.group_by(fn {status, _provider, _count} -> status end)

    successful = Map.get(results, :ok, [])
    failed = Map.get(results, :error, [])

    total_synced = successful |> Enum.map(fn {_, _, count} -> count end) |> Enum.sum()

    Logger.info(
      "Email sync completed for user #{user_id}: #{total_synced} emails synced across #{length(successful)} providers, #{length(failed)} failed"
    )

    %{
      total_emails_synced: total_synced,
      successful_providers: length(successful),
      failed_providers: length(failed),
      providers_synced: successful |> Enum.map(fn {_, provider, count} -> {provider, count} end),
      errors: failed |> Enum.map(fn {_, provider, reason} -> {provider, reason} end)
    }
  end

  @doc """
  Syncs a specific connection regardless of provider or service type.
  """
  def sync_connection(%ServiceConnection{} = connection) do
    case {connection.provider, connection.service_type} do
      {:google, :calendar} ->
        sync_calendar_connection(connection)

      {:google, :email} ->
        sync_email_connection(connection)

      {:microsoft, :calendar} ->
        sync_calendar_connection(connection)

      {:microsoft, :email} ->
        sync_email_connection(connection)

      {provider, service_type} ->
        Logger.warning("Unsupported provider/service combination: #{provider}/#{service_type}")
        {:error, provider, "Unsupported integration"}
    end
  end

  @doc """
  Gets unified email statistics across all providers for a user.
  """
  def get_unified_email_statistics(user_id, days_back \\ 7) do
    email_connections = Connections.get_email_connections(user_id)

    stats_list =
      email_connections
      |> Enum.map(&get_email_statistics_for_connection(&1, days_back))
      |> Enum.filter(fn {status, _} -> status == :ok end)
      |> Enum.map(fn {_, stats} -> stats end)

    if length(stats_list) == 0 do
      %{
        total_sent_emails: 0,
        total_received_emails: 0,
        total_unread_emails: 0,
        providers_count: 0,
        cosmic_communication_rating: 50,
        email_velocity: :terrestrial
      }
    else
      total_sent = stats_list |> Enum.map(& &1.sent_emails) |> Enum.sum()
      total_received = stats_list |> Enum.map(& &1.received_emails) |> Enum.sum()
      total_unread = stats_list |> Enum.map(& &1.unread_emails) |> Enum.sum()

      # Calculate unified cosmic rating
      unified_rating = calculate_unified_cosmic_rating(total_sent, total_received, total_unread)
      unified_velocity = calculate_unified_velocity(total_sent, total_received, days_back)

      %{
        total_sent_emails: total_sent,
        total_received_emails: total_received,
        total_unread_emails: total_unread,
        providers_count: length(stats_list),
        cosmic_communication_rating: unified_rating,
        email_velocity: unified_velocity,
        provider_breakdown: build_provider_breakdown(email_connections, stats_list)
      }
    end
  end

  @doc """
  Checks the health of all integrations for a user.
  Returns status summary across all providers and services.
  """
  def check_integration_health(user_id) do
    all_connections = Connections.list_service_connections(user_id)

    health_summary = %{
      total_connections: length(all_connections),
      active_connections: Enum.count(all_connections, &(&1.connection_status == :active)),
      expired_connections: Enum.count(all_connections, &(&1.connection_status == :expired)),
      error_connections: Enum.count(all_connections, &(&1.connection_status == :error)),
      provider_breakdown: build_health_breakdown_by_provider(all_connections),
      service_breakdown: build_health_breakdown_by_service(all_connections),
      needs_attention: filter_connections_needing_attention(all_connections)
    }

    # Calculate overall health score
    health_score = calculate_overall_health_score(health_summary)

    Map.put(health_summary, :overall_health_score, health_score)
  end

  # Private functions

  defp sync_calendar_connection(%ServiceConnection{provider: :google} = connection) do
    case GoogleCalendar.sync_calendar_events(connection) do
      {:ok, count} -> {:ok, :google, count}
      {:error, reason} -> {:error, :google, reason}
    end
  end

  defp sync_calendar_connection(%ServiceConnection{provider: :microsoft} = connection) do
    case MicrosoftCalendar.sync_calendar_events(connection) do
      {:ok, count} -> {:ok, :microsoft, count}
      {:error, reason} -> {:error, :microsoft, reason}
    end
  end

  defp sync_calendar_connection(%ServiceConnection{provider: provider}) do
    {:error, provider, "Unsupported calendar provider"}
  end

  defp sync_email_connection(%ServiceConnection{provider: :google} = connection) do
    case Gmail.sync_email_summaries(connection) do
      {:ok, count} -> {:ok, :google, count}
      {:error, reason} -> {:error, :google, reason}
    end
  end

  defp sync_email_connection(%ServiceConnection{provider: :microsoft} = connection) do
    case MicrosoftOutlook.sync_email_summaries(connection) do
      {:ok, count} -> {:ok, :microsoft, count}
      {:error, reason} -> {:error, :microsoft, reason}
    end
  end

  defp sync_email_connection(%ServiceConnection{provider: provider}) do
    {:error, provider, "Unsupported email provider"}
  end

  defp get_email_statistics_for_connection(
         %ServiceConnection{provider: :google} = connection,
         days_back
       ) do
    case Gmail.get_email_statistics(connection, days_back) do
      {:ok, stats} -> {:ok, stats}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_email_statistics_for_connection(
         %ServiceConnection{provider: :microsoft} = connection,
         days_back
       ) do
    case MicrosoftOutlook.get_email_statistics(connection, days_back) do
      {:ok, stats} -> {:ok, stats}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_email_statistics_for_connection(%ServiceConnection{provider: provider}, _days_back) do
    {:error, "Unsupported email provider: #{provider}"}
  end

  defp calculate_unified_cosmic_rating(sent, received, unread) do
    total_active = sent + received
    unread_ratio = if total_active > 0, do: unread / total_active, else: 0
    response_balance = if received > 0, do: sent / received, else: 1

    base_rating = 50

    # Unread burden across all providers
    unread_penalty = round(unread_ratio * 30)

    # Cross-provider response balance
    balance_adjustment =
      cond do
        response_balance > 2 -> -15
        response_balance < 0.5 -> -10
        response_balance >= 0.8 and response_balance <= 1.2 -> 15
        true -> 0
      end

    # Multi-provider volume wisdom
    volume_adjustment =
      cond do
        # Even worse with multiple providers
        total_active > 150 -> -25
        total_active > 75 -> -15
        total_active < 15 -> 15
        true -> 0
      end

    final_rating = base_rating - unread_penalty + balance_adjustment + volume_adjustment
    max(0, min(100, final_rating))
  end

  defp calculate_unified_velocity(sent, received, days) do
    total_emails = sent + received
    velocity = total_emails / days

    cond do
      # Beyond hyperspace with multiple providers
      velocity > 75 -> :ludicrous_speed
      velocity > 50 -> :hyperspace
      velocity > 20 -> :warp_speed
      velocity > 10 -> :cruising
      velocity > 5 -> :orbital
      velocity > 1 -> :atmospheric
      true -> :terrestrial
    end
  end

  defp build_provider_breakdown(connections, stats_list) do
    connections
    |> Enum.zip(stats_list)
    |> Enum.map(fn {connection, stats} ->
      %{
        provider: connection.provider,
        display_name: connection.display_name,
        account_email: connection.external_account_email,
        stats: stats
      }
    end)
  end

  defp build_health_breakdown_by_provider(connections) do
    connections
    |> Enum.group_by(& &1.provider)
    |> Enum.map(fn {provider, conns} ->
      {provider,
       %{
         total: length(conns),
         active: Enum.count(conns, &(&1.connection_status == :active)),
         expired: Enum.count(conns, &(&1.connection_status == :expired)),
         error: Enum.count(conns, &(&1.connection_status == :error))
       }}
    end)
    |> Enum.into(%{})
  end

  defp build_health_breakdown_by_service(connections) do
    connections
    |> Enum.group_by(& &1.service_type)
    |> Enum.map(fn {service_type, conns} ->
      {service_type,
       %{
         total: length(conns),
         active: Enum.count(conns, &(&1.connection_status == :active)),
         expired: Enum.count(conns, &(&1.connection_status == :expired)),
         error: Enum.count(conns, &(&1.connection_status == :error))
       }}
    end)
    |> Enum.into(%{})
  end

  defp filter_connections_needing_attention(connections) do
    connections
    |> Enum.filter(fn conn ->
      conn.connection_status != :active or
        ServiceConnection.needs_refresh?(conn) or
        (conn.last_sync_at && DateTime.diff(DateTime.utc_now(), conn.last_sync_at, :hour) > 6)
    end)
    |> Enum.map(fn conn ->
      %{
        id: conn.id,
        provider: conn.provider,
        service_type: conn.service_type,
        display_name: conn.display_name,
        status: conn.connection_status,
        issue: determine_connection_issue(conn)
      }
    end)
  end

  defp determine_connection_issue(conn) do
    cond do
      conn.connection_status == :expired ->
        "Token expired - needs re-authorization"

      conn.connection_status == :error ->
        "Connection error - check credentials"

      ServiceConnection.needs_refresh?(conn) ->
        "Token needs refresh"

      conn.last_sync_at && DateTime.diff(DateTime.utc_now(), conn.last_sync_at, :hour) > 6 ->
        "Sync overdue"

      true ->
        "Unknown issue"
    end
  end

  defp calculate_overall_health_score(health_summary) do
    total = health_summary.total_connections

    if total == 0 do
      # No connections is technically healthy
      100
    else
      active_ratio = health_summary.active_connections / total
      error_penalty = health_summary.error_connections * 20
      expired_penalty = health_summary.expired_connections * 15
      attention_penalty = length(health_summary.needs_attention) * 10

      base_score = round(active_ratio * 100)
      final_score = base_score - error_penalty - expired_penalty - attention_penalty

      max(0, min(100, final_score))
    end
  end
end
