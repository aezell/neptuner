defmodule NeptunerWeb.SubscriptionLive do
  use NeptunerWeb, :live_view
  alias Neptuner.Subscriptions
  import NeptunerWeb.SubscriptionComponents

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    tiers = Subscriptions.get_subscription_tiers()
    subscription_analytics = Subscriptions.get_subscription_analytics(user)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:tiers, tiers)
     |> assign(:current_tier, user.subscription_tier)
     |> assign(:subscription_analytics, subscription_analytics)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <div class="flex items-center justify-between">
          <.header>Cosmic Subscription Management</.header>
          <.tier_badge tier={@user.subscription_tier} />
        </div>
        
    <!-- Current Subscription Status -->
        <div class="bg-white rounded-lg shadow border border-gray-200 p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Current Subscription</h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <dl class="space-y-3">
                <div class="flex justify-between">
                  <dt class="text-sm text-gray-600">Plan</dt>
                  <dd class="text-sm font-medium text-gray-900">
                    {@tiers[@current_tier].name}
                  </dd>
                </div>

                <div class="flex justify-between">
                  <dt class="text-sm text-gray-600">Status</dt>
                  <dd class="text-sm font-medium text-green-600">
                    {String.capitalize(Atom.to_string(@subscription_analytics.status))}
                  </dd>
                </div>

                <%= if @user.subscription_expires_at do %>
                  <div class="flex justify-between">
                    <dt class="text-sm text-gray-600">Expires</dt>
                    <dd class="text-sm text-gray-900">
                      {Calendar.strftime(@user.subscription_expires_at, "%B %d, %Y")}
                    </dd>
                  </div>
                <% end %>
              </dl>
            </div>

            <div class="bg-purple-50 p-4 rounded-lg">
              <p class="text-sm text-purple-700 italic">
                {@subscription_analytics.cosmic_commentary}
              </p>
            </div>
          </div>
        </div>
        
    <!-- Available Plans -->
        <div class="bg-white rounded-lg shadow border border-gray-200 p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-6">Available Plans</h3>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div :for={{tier_key, tier_info} <- @tiers} class="relative">
              <!-- Premium Badge -->
              <%= if tier_key != :free do %>
                <div class="absolute -top-2 -right-2 z-10">
                  <.premium_badge />
                </div>
              <% end %>
              
    <!-- Current Plan Indicator -->
              <%= if tier_key == @current_tier do %>
                <div class="absolute -top-2 -left-2 z-10">
                  <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    Current Plan
                  </span>
                </div>
              <% end %>

              <div class={[
                "border rounded-lg p-6 h-full flex flex-col",
                if(tier_key == @current_tier,
                  do: "border-purple-300 bg-purple-50",
                  else: "border-gray-200 bg-white"
                )
              ]}>
                <div class="flex-1">
                  <h4 class="text-xl font-semibold text-gray-900 mb-2">{tier_info.name}</h4>
                  <p class="text-gray-600 text-sm mb-4">{tier_info.description}</p>

                  <div class="mb-4">
                    <%= if tier_info.price == 0 do %>
                      <span class="text-3xl font-bold text-gray-900">Free</span>
                    <% else %>
                      <span class="text-3xl font-bold text-gray-900">${tier_info.price}</span>
                      <span class="text-sm text-gray-600">/month</span>
                    <% end %>
                  </div>
                  
    <!-- Feature List -->
                  <ul class="space-y-2 text-sm text-gray-600">
                    <li class="flex items-center">
                      <.icon name="hero-check" class="w-4 h-4 text-green-500 mr-2" />
                      Tasks: {format_limit(tier_info.features.tasks_limit)}
                    </li>
                    <li class="flex items-center">
                      <.icon name="hero-check" class="w-4 h-4 text-green-500 mr-2" />
                      Habits: {format_limit(tier_info.features.habits_limit)}
                    </li>
                    <li class="flex items-center">
                      <.icon name="hero-check" class="w-4 h-4 text-green-500 mr-2" />
                      Connections: {format_limit(tier_info.features.connections_limit)}
                    </li>

                    <%= if tier_info.features.advanced_analytics do %>
                      <li class="flex items-center">
                        <.icon name="hero-check" class="w-4 h-4 text-green-500 mr-2" />
                        Advanced Analytics
                      </li>
                    <% end %>

                    <%= if tier_info.features.premium_achievements do %>
                      <li class="flex items-center">
                        <.icon name="hero-check" class="w-4 h-4 text-green-500 mr-2" />
                        Premium Achievements
                      </li>
                    <% end %>

                    <%= if tier_info.features.export_data do %>
                      <li class="flex items-center">
                        <.icon name="hero-check" class="w-4 h-4 text-green-500 mr-2" /> Data Export
                      </li>
                    <% end %>
                  </ul>
                </div>
                
    <!-- Action Button -->
                <div class="mt-6">
                  <%= if tier_key == @current_tier do %>
                    <button
                      class="w-full px-4 py-2 bg-gray-100 text-gray-500 rounded-md cursor-not-allowed"
                      disabled
                    >
                      Current Plan
                    </button>
                  <% else %>
                    <%= if tier_key == :free do %>
                      <button
                        phx-click="downgrade_to_free"
                        class="w-full px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700 transition-colors"
                      >
                        Downgrade to Free
                      </button>
                    <% else %>
                      <button
                        phx-click="upgrade_to_tier"
                        phx-value-tier={tier_key}
                        class="w-full px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 transition-colors"
                      >
                        {if @current_tier == :free, do: "Upgrade Now", else: "Switch Plan"}
                      </button>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Usage Statistics -->
        <.usage_limits user={@user} usage={@subscription_analytics.features_used} />
      </div>
    </Layouts.dashboard>
    """
  end

  def handle_event("upgrade_to_tier", %{"tier" => tier}, socket) do
    _tier_atom = String.to_existing_atom(tier)

    # In a real implementation, this would redirect to LemonSqueezy checkout
    # For now, we'll simulate an upgrade for demo purposes
    socket =
      socket
      |> put_flash(:info, "Upgrade to #{tier} would redirect to payment processor. (Demo mode)")

    {:noreply, socket}
  end

  def handle_event("downgrade_to_free", _params, socket) do
    user = socket.assigns.user

    case Subscriptions.cancel_user_subscription(user) do
      {:ok, updated_user} ->
        socket =
          socket
          |> assign(:user, updated_user)
          |> assign(:current_tier, updated_user.subscription_tier)
          |> put_flash(
            :info,
            "Your subscription has been cancelled. You'll retain premium features until your billing period ends."
          )

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Unable to cancel subscription. Please try again.")

        {:noreply, socket}
    end
  end

  defp format_limit(:unlimited), do: "Unlimited"
  defp format_limit(num) when is_integer(num), do: "#{num}"
  defp format_limit(_), do: "0"
end
