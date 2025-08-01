defmodule Neptuner.Subscriptions do
  alias Neptuner.Accounts.User
  alias Neptuner.Repo
  import Ecto.Query

  @subscription_tiers %{
    free: %{
      name: "Free Tier",
      description: "Basic cosmic productivity with existential awareness",
      price: 0,
      features: %{
        tasks_limit: 50,
        habits_limit: 10,
        connections_limit: 2,
        advanced_analytics: false,
        premium_achievements: false,
        priority_support: false,
        export_data: false,
        custom_cosmic_commentary: false
      }
    },
    cosmic_enlightenment: %{
      name: "Cosmic Enlightenment",
      description: "Advanced productivity theater analysis with unlimited cosmic insights",
      price: 29.00,
      features: %{
        tasks_limit: :unlimited,
        habits_limit: :unlimited,
        connections_limit: :unlimited,
        advanced_analytics: true,
        premium_achievements: true,
        priority_support: true,
        export_data: true,
        custom_cosmic_commentary: true,
        productivity_coaching: true,
        trend_analysis: true,
        cross_system_insights: true
      }
    },
    enterprise: %{
      name: "Enterprise Enlightenment",
      description: "Team productivity theater with organizational cosmic perspective",
      price: 99.00,
      features: %{
        tasks_limit: :unlimited,
        habits_limit: :unlimited,
        connections_limit: :unlimited,
        advanced_analytics: true,
        premium_achievements: true,
        priority_support: true,
        export_data: true,
        custom_cosmic_commentary: true,
        productivity_coaching: true,
        trend_analysis: true,
        cross_system_insights: true,
        team_management: true,
        sso_integration: true,
        api_access: true,
        white_label: true
      }
    }
  }

  def get_subscription_tiers, do: @subscription_tiers

  def get_tier_info(tier) when tier in [:free, :cosmic_enlightenment, :enterprise] do
    Map.get(@subscription_tiers, tier)
  end

  def get_user_subscription_tier(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user.subscription_tier || :free}
    end
  end

  def has_feature?(user, feature) do
    tier_info = get_tier_info(user.subscription_tier)
    feature_enabled = get_in(tier_info, [:features, feature])

    case {user.subscription_status, feature_enabled} do
      {:active, true} -> true
      {:trial, true} -> not_expired?(user)
      _ -> false
    end
  end

  def get_feature_limit(user, feature) do
    tier_info = get_tier_info(user.subscription_tier)
    limit = get_in(tier_info, [:features, feature])

    if has_feature?(user, String.to_atom("#{feature}_unlimited")) do
      :unlimited
    else
      limit || 0
    end
  end

  def within_limit?(user, feature, current_count) do
    limit = get_feature_limit(user, feature)

    case limit do
      :unlimited -> true
      num when is_integer(num) -> current_count < num
      _ -> false
    end
  end

  def upgrade_user_subscription(user, tier, lemonsqueezy_data \\ %{}) do
    subscription_features = get_tier_features(tier)

    user
    |> User.changeset(%{
      subscription_tier: tier,
      subscription_status: :active,
      subscription_expires_at: calculate_expiry_date(lemonsqueezy_data),
      lemonsqueezy_customer_id: Map.get(lemonsqueezy_data, "customer_id"),
      subscription_features: subscription_features
    })
    |> Repo.update()
  end

  def cancel_user_subscription(user) do
    user
    |> User.changeset(%{
      subscription_status: :cancelled,
      subscription_expires_at: thirty_days_from_now()
    })
    |> Repo.update()
  end

  def expire_user_subscription(user) do
    user
    |> User.changeset(%{
      subscription_tier: :free,
      subscription_status: :expired,
      subscription_features: get_tier_features(:free)
    })
    |> Repo.update()
  end

  def check_subscription_status(user) do
    case {user.subscription_status, user.subscription_expires_at} do
      {:active, nil} ->
        :active

      {:active, expires_at} when not is_nil(expires_at) ->
        if DateTime.after?(expires_at, DateTime.utc_now()) do
          :active
        else
          :expired
        end

      {:cancelled, expires_at} when not is_nil(expires_at) ->
        if DateTime.after?(expires_at, DateTime.utc_now()) do
          :cancelled_but_active
        else
          :expired
        end

      status ->
        status
    end
  end

  def get_subscription_analytics(user) do
    tier_info = get_tier_info(user.subscription_tier)
    status = check_subscription_status(user)

    features_used = %{
      tasks_count: count_user_tasks(user.id),
      habits_count: count_user_habits(user.id),
      connections_count: count_user_connections(user.id)
    }

    %{
      current_tier: user.subscription_tier,
      tier_name: tier_info.name,
      status: status,
      expires_at: user.subscription_expires_at,
      features_used: features_used,
      upgrade_available: user.subscription_tier == :free,
      cosmic_commentary: generate_subscription_commentary(user, features_used)
    }
  end

  defp get_tier_features(tier) do
    tier_info = get_tier_info(tier)
    tier_info[:features] || %{}
  end

  defp calculate_expiry_date(%{"billing_period" => "monthly"}), do: thirty_days_from_now()
  defp calculate_expiry_date(%{"billing_period" => "yearly"}), do: one_year_from_now()
  defp calculate_expiry_date(_), do: thirty_days_from_now()

  defp thirty_days_from_now do
    DateTime.utc_now() |> DateTime.add(30, :day)
  end

  defp one_year_from_now do
    DateTime.utc_now() |> DateTime.add(365, :day)
  end

  defp not_expired?(user) do
    case user.subscription_expires_at do
      nil -> true
      expires_at -> DateTime.after?(expires_at, DateTime.utc_now())
    end
  end

  defp count_user_tasks(user_id) do
    from(t in Neptuner.Tasks.Task, where: t.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp count_user_habits(user_id) do
    from(h in Neptuner.Habits.Habit, where: h.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp count_user_connections(user_id) do
    from(c in Neptuner.Connections.ServiceConnection, where: c.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp generate_subscription_commentary(user, features_used) do
    case user.subscription_tier do
      :free ->
        cond do
          features_used.tasks_count > 40 ->
            "You're approaching peak free-tier productivity theater. The universe suggests considering enlightenment."

          features_used.connections_count >= 2 ->
            "Maximum digital service integration achieved on free tier. Your cosmic connectivity is complete, yet limited."

          true ->
            "Free tier: where productivity dreams meet reality's gentle constraints."
        end

      :cosmic_enlightenment ->
        "Cosmic Enlightenment achieved. You've transcended basic productivity theater and embraced unlimited existential task management."

      :enterprise ->
        "Enterprise Enlightenment: Because sometimes you need to scale your existential dread across an entire organization."
    end
  end
end
