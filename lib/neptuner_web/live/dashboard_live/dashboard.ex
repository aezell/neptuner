defmodule NeptunerWeb.DashboardLive do
  use NeptunerWeb, :live_view
  alias Neptuner.{Dashboard, Subscriptions, PremiumAnalytics}
  import NeptunerWeb.SubscriptionComponents

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    user_id = user.id

    premium_analytics =
      case PremiumAnalytics.get_advanced_analytics(user) do
        {:ok, analytics} -> analytics
        {:error, :premium_required} -> nil
      end

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:statistics, Dashboard.get_unified_statistics(user_id))
     |> assign(:recent_activity, Dashboard.get_recent_activity(user_id, 8))
     |> assign(:theater_metrics, Dashboard.get_productivity_theater_metrics(user_id))
     |> assign(:subscription_analytics, Subscriptions.get_subscription_analytics(user))
     |> assign(:premium_analytics, premium_analytics)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <!-- Mobile-optimized header -->
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <.header class="text-xl sm:text-2xl">Cosmic Productivity Command Center</.header>
          <div class="flex items-center gap-2 sm:gap-4 flex-wrap">
            <.tier_badge tier={@user.subscription_tier} />
            <div class="text-xs sm:text-sm text-gray-500">
              {Date.utc_today() |> Calendar.strftime("%B %d, %Y")}
            </div>
          </div>
        </div>
        
    <!-- Mobile-optimized Cosmic Perspective Widget -->
        <div
          class="bg-gradient-to-r from-purple-600 to-blue-600 rounded-lg p-4 sm:p-6 text-white"
          data-tour="cosmic-perspective"
        >
          <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex-1">
              <h3 class="text-base sm:text-lg font-semibold mb-2">Daily Cosmic Perspective</h3>
              <p class="text-purple-100 text-sm sm:text-base mb-3 sm:mb-4">{@statistics.cosmic_insights.daily_wisdom}</p>
              <div class="space-y-1">
                <div
                  :for={insight <- @statistics.cosmic_insights.insights}
                  class="text-xs sm:text-sm text-purple-200"
                >
                  • {insight}
                </div>
              </div>
            </div>
            <div class="text-center sm:text-right flex-shrink-0">
              <div class="text-2xl sm:text-3xl font-bold">{@theater_metrics.meaningless_percentage}%</div>
              <div class="text-xs sm:text-sm text-purple-200">Productivity Theater</div>
              <div class="text-xs text-purple-300 mt-1">{@theater_metrics.theater_level}</div>
            </div>
          </div>
        </div>
        
    <!-- Mobile-optimized Statistics Overview -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 lg:gap-6" data-tour="statistics">
          <.stat_card
            title="Tasks"
            value={@statistics.tasks.total}
            subtitle="{@statistics.tasks.completed} completed"
            icon="hero-check-circle"
            color="bg-blue-500"
            navigate={~p"/tasks"}
          />

          <.stat_card
            title="Active Habits"
            value={@statistics.habits.active_streaks}
            subtitle="{@statistics.habits.total_current_streak} total streak days"
            icon="hero-arrow-path"
            color="bg-purple-500"
            navigate={~p"/habits"}
          />

          <.stat_card
            title="Achievements"
            value="{@statistics.achievements.completed}/{@statistics.achievements.total_achievements}"
            subtitle="{@statistics.achievements.completion_percentage}% complete"
            icon="hero-trophy"
            color="bg-yellow-500"
            navigate={~p"/achievements"}
          />

          <.stat_card
            title="Connections"
            value={@statistics.connections.active_connections}
            subtitle="{@statistics.connections.total_connections} total"
            icon="hero-link"
            color="bg-green-500"
            navigate={~p"/connections"}
          />
        </div>
        
    <!-- Mobile-optimized Productivity Theater Metrics -->
        <div class="bg-white rounded-lg shadow border border-gray-200 p-4 sm:p-6">
          <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-3 sm:mb-4">Productivity Theater Analysis</h3>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
            <div class="text-center p-3 sm:p-0">
              <div class="text-xl sm:text-2xl font-bold text-red-600">
                {@theater_metrics.total_meaningless_activity}
              </div>
              <div class="text-xs sm:text-sm text-gray-600">Theatrical Activities</div>
            </div>
            <div class="text-center p-3 sm:p-0">
              <div class="text-xl sm:text-2xl font-bold text-green-600">
                {@theater_metrics.total_meaningful_activity}
              </div>
              <div class="text-xs sm:text-sm text-gray-600">Meaningful Work</div>
            </div>
            <div class="text-center p-3 sm:p-0">
              <div class="text-base sm:text-lg font-semibold text-purple-600">
                {@theater_metrics.theater_level}
              </div>
              <div class="text-xs sm:text-sm text-gray-600">Performance Level</div>
            </div>
          </div>
          <div class="mt-3 sm:mt-4 p-3 bg-gray-50 rounded">
            <p class="text-xs sm:text-sm text-gray-700 italic">{@theater_metrics.cosmic_commentary}</p>
          </div>
        </div>
        
    <!-- Service Connection Health -->
        <div class="bg-white rounded-lg shadow border border-gray-200 p-6" data-tour="connections">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Service Connection Health</h3>
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600">
                {@statistics.connections.active_connections}
              </div>
              <div class="text-sm text-gray-600">Active</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-red-600">
                {@statistics.connections.expired_connections}
              </div>
              <div class="text-sm text-gray-600">Expired</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-yellow-600">
                {@statistics.connections.error_connections}
              </div>
              <div class="text-sm text-gray-600">Errors</div>
            </div>
            <div class="text-center">
              <.link navigate={~p"/connections"} class="text-blue-600 hover:text-blue-800">
                <div class="text-sm font-medium">Manage Connections →</div>
              </.link>
            </div>
          </div>

          <%= if @statistics.connections.active_connections == 0 do %>
            <div class="mt-4 p-3 bg-blue-50 rounded border border-blue-200">
              <p class="text-sm text-blue-700">
                ✨ Connect your digital services to unlock the full cosmic productivity experience.
              </p>
            </div>
          <% end %>
        </div>
        
    <!-- Subscription Status & Usage Limits -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Subscription Status -->
          <div class="bg-white rounded-lg shadow border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Subscription Status</h3>
            <div class="space-y-3">
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Current Tier</span>
                <.tier_badge tier={@user.subscription_tier} />
              </div>

              <%= if @user.subscription_tier != :free do %>
                <div class="flex justify-between items-center">
                  <span class="text-sm text-gray-600">Status</span>
                  <span class="text-sm font-medium text-green-600">Active</span>
                </div>

                <%= if @user.subscription_expires_at do %>
                  <div class="flex justify-between items-center">
                    <span class="text-sm text-gray-600">Expires</span>
                    <span class="text-sm text-gray-900">
                      {Calendar.strftime(@user.subscription_expires_at, "%B %d, %Y")}
                    </span>
                  </div>
                <% end %>
              <% end %>

              <div class="pt-3 border-t border-gray-200">
                <p class="text-sm text-gray-700 italic">
                  {@subscription_analytics.cosmic_commentary}
                </p>
              </div>

              <%= if @subscription_analytics.upgrade_available do %>
                <div class="pt-2">
                  <.link
                    navigate={~p"/subscription"}
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700"
                  >
                    <.icon name="hero-star" class="w-4 h-4 mr-2" /> Upgrade to Cosmic Enlightenment
                  </.link>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Usage Limits -->
          <.usage_limits user={@user} usage={@subscription_analytics.features_used} />
        </div>
        
    <!-- Premium Analytics Section -->
        <.feature_gate user={@user} feature={:advanced_analytics}>
          <%= if @premium_analytics do %>
            <div class="bg-white rounded-lg shadow border border-gray-200 p-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold text-gray-900">Advanced Cosmic Analytics</h3>
                <.premium_badge />
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <!-- Productivity Score -->
                <div class="text-center p-4 bg-gradient-to-br from-purple-50 to-blue-50 rounded-lg">
                  <div class="text-3xl font-bold text-purple-600">
                    {@premium_analytics.cosmic_coaching.productivity_score}
                  </div>
                  <div class="text-sm text-gray-600 mt-1">Holistic Score</div>
                  <div class="text-xs text-purple-600 mt-2 italic">
                    {@premium_analytics.cosmic_coaching.cosmic_guidance}
                  </div>
                </div>
                
    <!-- Trend Analysis -->
                <div class="p-4 bg-gradient-to-br from-green-50 to-blue-50 rounded-lg">
                  <h4 class="font-medium text-gray-900 mb-2">Productivity Trend</h4>
                  <div class="text-2xl font-bold text-green-600 capitalize">
                    {@premium_analytics.productivity_trends.overall_productivity_trend
                    |> Atom.to_string()}
                  </div>
                  <div class="text-xs text-gray-600 mt-2">
                    {@premium_analytics.productivity_trends.cosmic_insight}
                  </div>
                </div>
                
    <!-- Time Allocation -->
                <div class="p-4 bg-gradient-to-br from-orange-50 to-red-50 rounded-lg">
                  <h4 class="font-medium text-gray-900 mb-2">Focus Allocation</h4>
                  <div class="space-y-1">
                    <div class="flex justify-between text-xs">
                      <span>Tasks</span>
                      <span>{@premium_analytics.time_allocation.task_allocation.percentage}%</span>
                    </div>
                    <div class="flex justify-between text-xs">
                      <span>Meetings</span>
                      <span>{@premium_analytics.time_allocation.meeting_allocation.percentage}%</span>
                    </div>
                    <div class="flex justify-between text-xs">
                      <span>Habits</span>
                      <span>{@premium_analytics.time_allocation.habit_allocation.percentage}%</span>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Cosmic Coaching -->
              <div class="mt-6 p-4 bg-gradient-to-r from-purple-50 to-pink-50 rounded-lg border border-purple-200">
                <h4 class="font-medium text-purple-900 mb-2">Weekly Cosmic Guidance</h4>
                <p class="text-sm text-purple-800 mb-3">
                  Focus: {@premium_analytics.cosmic_coaching.weekly_focus_suggestion}
                </p>
                <div class="space-y-1">
                  <div
                    :for={
                      recommendation <- @premium_analytics.cosmic_coaching.actionable_recommendations
                    }
                    class="text-xs text-purple-700"
                  >
                    • {recommendation}
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </.feature_gate>
        
    <!-- Recent Activity and Quick Navigation -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Recent Activity -->
          <div
            class="bg-white rounded-lg shadow border border-gray-200 p-6"
            data-tour="recent-activity"
          >
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h3>
            <div class="space-y-3">
              <div :for={activity <- @recent_activity} class="flex items-start space-x-3">
                <div class="flex-shrink-0">
                  <div class={"w-8 h-8 rounded-lg flex items-center justify-center #{activity.color}"}>
                    <.icon name={activity.icon} class="w-4 h-4 text-white" />
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-sm font-medium text-gray-900">{activity.title}</div>
                  <div class="text-xs text-gray-600">{activity.description}</div>
                  <div class="text-xs text-gray-400 mt-1">
                    {Calendar.strftime(activity.timestamp, "%b %d at %I:%M %p")}
                  </div>
                </div>
              </div>

              <%= if Enum.empty?(@recent_activity) do %>
                <div class="text-center py-4 text-gray-500">
                  <.icon name="hero-face-frown" class="w-8 h-8 mx-auto mb-2 text-gray-400" />
                  <p class="text-sm">No recent activity. Time to create some cosmic productivity!</p>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Mobile-optimized Quick Navigation -->
          <div class="bg-white rounded-lg shadow border border-gray-200 p-4 sm:p-6" data-tour="quick-actions">
            <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-3 sm:mb-4">Quick Actions</h3>
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-3 gap-2 sm:gap-3">
              <.quick_action_button
                title="Add Task"
                icon="hero-plus-circle"
                color="bg-blue-500"
                navigate={~p"/tasks/new"}
              />

              <.quick_action_button
                title="New Habit"
                icon="hero-arrow-path"
                color="bg-purple-500"
                navigate={~p"/habits/new"}
              />

              <.quick_action_button
                title="Meetings"
                icon="hero-calendar-days"
                color="bg-orange-500"
                navigate={~p"/calendar"}
              />

              <.quick_action_button
                title="Email Insights"
                icon="hero-envelope"
                color="bg-red-500"
                navigate={~p"/communications"}
              />

              <.quick_action_button
                title="Import Data"
                icon="hero-arrow-down-tray"
                color="bg-green-500"
                navigate={~p"/import"}
              />

              <.quick_action_button
                title="Connections"
                icon="hero-link"
                color="bg-indigo-500"
                navigate={~p"/connections"}
              />
            </div>
          </div>
        </div>
      </div>
    </Layouts.dashboard>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="block bg-white rounded-lg shadow border border-gray-200 p-3 sm:p-4 lg:p-6 hover:shadow-md transition-shadow min-h-[80px] sm:min-h-[100px]"
    >
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <div class={"w-8 h-8 sm:w-10 sm:h-10 rounded-lg flex items-center justify-center #{@color}"}>
            <.icon name={@icon} class="w-4 h-4 sm:w-5 sm:h-5 lg:w-6 lg:h-6 text-white" />
          </div>
        </div>
        <div class="ml-3 sm:ml-4 min-w-0 flex-1">
          <div class="text-lg sm:text-xl lg:text-2xl font-bold text-gray-900 truncate">{@value}</div>
          <div class="text-xs sm:text-sm text-gray-600 font-medium">{@title}</div>
          <div class="text-xs text-gray-500 truncate">{@subtitle}</div>
        </div>
      </div>
    </.link>
    """
  end

  defp quick_action_button(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={"flex flex-col sm:flex-row items-center justify-center p-3 sm:p-4 rounded-lg text-white hover:opacity-90 transition-opacity min-h-[60px] sm:min-h-[64px] #{@color}"}
    >
      <.icon name={@icon} class="w-5 h-5 sm:w-4 sm:h-4 mb-1 sm:mb-0 sm:mr-2" />
      <span class="text-xs sm:text-sm font-medium text-center leading-tight">{@title}</span>
    </.link>
    """
  end
end
