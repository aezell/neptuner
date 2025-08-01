defmodule NeptunerWeb.SubscriptionComponents do
  use Phoenix.Component
  use NeptunerWeb, :verified_routes
  import NeptunerWeb.CoreComponents
  alias Neptuner.Subscriptions

  @doc """
  Feature gate component that conditionally shows content based on subscription tier.
  """
  def feature_gate(assigns) do
    ~H"""
    <%= if @user && Subscriptions.has_feature?(@user, @feature) do %>
      {render_slot(@inner_block)}
    <% else %>
      <%= if assigns[:fallback] do %>
        {render_slot(@fallback)}
      <% else %>
        <.premium_upsell user={@user} feature={@feature} />
      <% end %>
    <% end %>
    """
  end

  @doc """
  Shows premium upsell message when user hits a feature gate.
  """
  def premium_upsell(assigns) do
    ~H"""
    <div class="bg-gradient-to-r from-purple-50 to-blue-50 border border-purple-200 rounded-lg p-6">
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <.icon name="hero-star" class="w-8 h-8 text-purple-500" />
        </div>
        <div class="ml-4">
          <h3 class="text-lg font-semibold text-purple-900">Cosmic Enlightenment Required</h3>
          <p class="text-purple-700 mt-1">
            {get_feature_description(@feature)} is available in our premium tier.
          </p>
          <p class="text-sm text-purple-600 mt-2 italic">
            Unlock unlimited cosmic productivity for $29/month. The universe approves.
          </p>
          <div class="mt-4">
            <.link
              navigate={~p"/subscription"}
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
            >
              Achieve Enlightenment →
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows usage limits for the current subscription tier.
  """
  def usage_limits(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-lg p-4">
      <h4 class="text-sm font-medium text-gray-900 mb-3">Current Tier Limits</h4>
      <div class="space-y-2">
        <.usage_bar
          label="Tasks"
          current={@usage.tasks_count}
          limit={Subscriptions.get_feature_limit(@user, :tasks_limit)}
        />
        <.usage_bar
          label="Habits"
          current={@usage.habits_count}
          limit={Subscriptions.get_feature_limit(@user, :habits_limit)}
        />
        <.usage_bar
          label="Connections"
          current={@usage.connections_count}
          limit={Subscriptions.get_feature_limit(@user, :connections_limit)}
        />
      </div>

      <%= if @user.subscription_tier == :free do %>
        <div class="mt-4 pt-3 border-t border-gray-200">
          <p class="text-xs text-gray-600 mb-2">
            Want unlimited cosmic productivity?
          </p>
          <.link
            navigate={~p"/subscription"}
            class="text-sm text-purple-600 hover:text-purple-800 font-medium"
          >
            Upgrade to Cosmic Enlightenment →
          </.link>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Usage bar showing current usage vs limits.
  """
  def usage_bar(assigns) do
    percentage =
      case assigns.limit do
        :unlimited -> 0
        0 -> 100
        limit -> min(round(assigns.current / limit * 100), 100)
      end

    color_class =
      cond do
        percentage >= 90 -> "bg-red-500"
        percentage >= 75 -> "bg-yellow-500"
        true -> "bg-green-500"
      end

    assigns = assign(assigns, :percentage, percentage)
    assigns = assign(assigns, :color_class, color_class)

    ~H"""
    <div>
      <div class="flex justify-between text-xs text-gray-600 mb-1">
        <span>{@label}</span>
        <span>
          {@current}
          <%= if @limit == :unlimited do %>
            ∞
          <% else %>
            /{@limit}
          <% end %>
        </span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div class={"h-2 rounded-full #{@color_class}"} style={"width: #{@percentage}%"}></div>
      </div>
    </div>
    """
  end

  @doc """
  Premium badge for premium-only features.
  """
  def premium_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
      <.icon name="hero-star" class="w-3 h-3 mr-1" /> Premium
    </span>
    """
  end

  @doc """
  Subscription tier badge showing current user tier.
  """
  def tier_badge(assigns) do
    {badge_class, tier_name} =
      case assigns.tier do
        :free -> {"bg-gray-100 text-gray-800", "Free"}
        :cosmic_enlightenment -> {"bg-purple-100 text-purple-800", "Cosmic Enlightenment"}
        :enterprise -> {"bg-blue-100 text-blue-800", "Enterprise"}
      end

    assigns = assign(assigns, :badge_class, badge_class)
    assigns = assign(assigns, :tier_name, tier_name)

    ~H"""
    <span class={"inline-flex items-center px-3 py-1 rounded-full text-sm font-medium #{@badge_class}"}>
      <%= if @tier != :free do %>
        <.icon name="hero-star" class="w-4 h-4 mr-1" />
      <% end %>
      {@tier_name}
    </span>
    """
  end

  defp get_feature_description(feature) do
    case feature do
      :advanced_analytics -> "Advanced productivity analytics with cosmic insights"
      :premium_achievements -> "Exclusive premium achievement badges and commentary"
      :export_data -> "Data export and backup capabilities"
      :custom_cosmic_commentary -> "Personalized existential productivity insights"
      :productivity_coaching -> "AI-powered productivity coaching and recommendations"
      :trend_analysis -> "Historical trend analysis and pattern recognition"
      :cross_system_insights -> "Deep cross-system productivity intelligence"
      _ -> "This premium feature"
    end
  end
end
