defmodule NeptunerWeb.OnboardingLive do
  use NeptunerWeb, :live_view
  alias Neptuner.{Onboarding, Tasks}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    # Start onboarding if not already started
    if user.onboarding_started_at == nil do
      Onboarding.start_onboarding(user)
    end

    progress = Onboarding.get_onboarding_progress(user)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:progress, progress)
     |> assign(:cosmic_options, Onboarding.cosmic_perspective_options())
     |> assign(:task_form, to_form(%{}))
     |> assign(:demo_data_generating, false)
     |> assign(:step_loading, false)}
  end

  def handle_event("select_cosmic_perspective", %{"level" => level}, socket) do
    level_atom = String.to_existing_atom(level)
    user = socket.assigns.user

    case Onboarding.set_cosmic_perspective(user, level_atom) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> put_flash(
           :info,
           "Cosmic perspective level set! Your journey into productive enlightenment begins."
         )
         |> advance_to_next_step(:demo_data)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Cosmic alignment failed. Please try again.")}
    end
  end

  def handle_event("generate_demo_data", _params, socket) do
    # Generate demo data asynchronously
    send(self(), :generate_demo_data)

    {:noreply,
     socket
     |> assign(:demo_data_generating, true)
     |> assign(:step_loading, true)}
  end

  def handle_event("skip_demo_data", _params, socket) do
    {:noreply, advance_to_next_step(socket, :first_task)}
  end

  def handle_event("create_first_task", params, socket) do
    user = socket.assigns.user

    task_params =
      params
      |> Map.update("estimated_actual_importance", 1, fn val ->
        case Integer.parse(to_string(val)) do
          {int, _} -> int
          :error -> 1
        end
      end)
      |> Map.update("cosmic_priority", "matters_to_nobody", fn val ->
        String.to_existing_atom(val)
      end)

    case Tasks.create_task(user.id, task_params) do
      {:ok, _task} ->
        # Mark milestone and advance
        case Onboarding.mark_milestone_completed(user, :first_task_created) do
          {:ok, updated_user} ->
            {:noreply,
             socket
             |> assign(:user, updated_user)
             |> put_flash(
               :info,
               "Excellent! Your first task has been entered into the cosmic productivity matrix."
             )
             |> advance_to_next_step(:first_connection)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Task created but milestone tracking failed.")}
        end

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:task_form, to_form(changeset))
         |> put_flash(:error, "Task creation failed. Please check the details.")}
    end
  end

  def handle_event("skip_connection", _params, socket) do
    {:noreply, advance_to_next_step(socket, :dashboard_tour)}
  end

  def handle_event("start_dashboard_tour", _params, socket) do
    user = socket.assigns.user

    case Onboarding.mark_milestone_completed(user, :dashboard_tour_completed) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:user, updated_user)
         |> advance_to_next_step(:completed)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Tour completion tracking failed.")}
    end
  end

  def handle_event("complete_onboarding", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/dashboard")}
  end

  def handle_info(:generate_demo_data, socket) do
    user = socket.assigns.user

    case Onboarding.generate_demo_data(user) do
      {:ok, updated_user} ->
        # Mark demo data milestone
        case Onboarding.mark_milestone_completed(updated_user, :demo_data_generated) do
          {:ok, final_user} ->
            {:noreply,
             socket
             |> assign(:user, final_user)
             |> assign(:demo_data_generating, false)
             |> assign(:step_loading, false)
             |> put_flash(
               :info,
               "Demo data generated! Explore your cosmic productivity dashboard."
             )
             |> advance_to_next_step(:first_task)}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(:demo_data_generating, false)
             |> assign(:step_loading, false)
             |> put_flash(:error, "Demo data created but tracking failed.")}
        end

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:demo_data_generating, false)
         |> assign(:step_loading, false)
         |> put_flash(:error, "Demo data generation failed. Please try again.")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-100">
      <div class="container mx-auto px-4 py-8">
        <!-- Progress Indicator -->
        <div class="max-w-4xl mx-auto mb-8">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <h1 class="text-2xl font-bold text-gray-900">Welcome to Neptuner</h1>
              <div class="text-sm text-gray-600">
                Step {@progress.current_step |> step_number()}/6
              </div>
            </div>

            <div class="flex items-center space-x-2">
              <div class="text-sm text-gray-600">Activation Score:</div>
              <div class="px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm font-medium">
                {@progress.activation_score}/100
              </div>
            </div>
          </div>
          
    <!-- Progress Bar -->
          <div class="mt-4 w-full bg-gray-200 rounded-full h-2">
            <div
              class="bg-gradient-to-r from-purple-600 to-blue-600 h-2 rounded-full transition-all duration-500 ease-out"
              style={"width: #{progress_percentage(@progress.current_step)}%"}
            >
            </div>
          </div>
        </div>
        
    <!-- Step Content -->
        <div class="max-w-4xl mx-auto">
          <%= case @progress.current_step do %>
            <% :welcome -> %>
              <.welcome_step
                cosmic_options={@cosmic_options}
                current_level={@user.cosmic_perspective_level}
              />
            <% :cosmic_setup -> %>
              <.cosmic_setup_step
                cosmic_options={@cosmic_options}
                current_level={@user.cosmic_perspective_level}
              />
            <% :demo_data -> %>
              <.demo_data_step
                demo_data_generating={@demo_data_generating}
                step_loading={@step_loading}
                user={@user}
              />
            <% :first_task -> %>
              <.first_task_step form={@task_form} />
            <% :first_connection -> %>
              <.first_connection_step />
            <% :dashboard_tour -> %>
              <.dashboard_tour_step />
            <% :completed -> %>
              <.completion_step user={@user} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Step Components

  defp welcome_step(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg p-8 text-center">
      <div class="mb-6">
        <div class="w-16 h-16 bg-gradient-to-br from-purple-600 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
          <.icon name="hero-rocket-launch" class="w-8 h-8 text-white" />
        </div>
        <h2 class="text-3xl font-bold text-gray-900">Welcome to Cosmic Productivity!</h2>
        <p class="text-lg text-gray-600 mt-4">
          Neptuner helps you manage tasks, habits, and meetings while maintaining a healthy perspective on productivity culture.
        </p>
      </div>

      <div class="bg-gradient-to-r from-purple-50 to-blue-50 rounded-lg p-6 mb-8">
        <p class="text-gray-700 italic">
          "In the vast cosmic dance of existence, your to-do list is both utterly meaningless and surprisingly useful.
          Let's organize it anyway."
        </p>
      </div>

      <div class="space-y-4">
        <p class="text-gray-600">
          We'll help you set up your cosmic productivity workspace in just a few steps.
          This should take about 3 minutes, which is nothing compared to the heat death of the universe.
        </p>

        <button
          phx-click="select_cosmic_perspective"
          phx-value-level="skeptical"
          class="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium py-3 px-6 rounded-lg transition-all"
        >
          Begin Cosmic Setup →
        </button>
      </div>
    </div>
    """
  end

  defp cosmic_setup_step(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg p-8">
      <div class="text-center mb-8">
        <h2 class="text-2xl font-bold text-gray-900">Choose Your Cosmic Perspective</h2>
        <p class="text-gray-600 mt-2">
          How do you view the grand theater of productivity? This helps us tailor your experience.
        </p>
      </div>

      <div class="grid md:grid-cols-3 gap-6">
        <div
          :for={option <- @cosmic_options}
          class={"relative border-2 rounded-lg p-6 cursor-pointer transition-all hover:shadow-lg #{if option.key == @current_level, do: "border-purple-500 bg-purple-50", else: "border-gray-200 hover:border-purple-300"}"}
          phx-click="select_cosmic_perspective"
          phx-value-level={option.key}
        >
          <div class="text-center">
            <div class="w-12 h-12 bg-gradient-to-br from-purple-600 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-eye" class="w-6 h-6 text-white" />
            </div>

            <h3 class="text-lg font-semibold text-gray-900 mb-2">{option.title}</h3>
            <p class="text-sm text-gray-600 mb-4">{option.description}</p>

            <div class="text-xs text-purple-600 italic bg-purple-50 rounded p-2">
              {option.quote}
            </div>
          </div>

          <%= if option.key == @current_level do %>
            <div class="absolute top-2 right-2">
              <.icon name="hero-check-circle" class="w-6 h-6 text-purple-600" />
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp demo_data_step(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg p-8">
      <div class="text-center mb-8">
        <h2 class="text-2xl font-bold text-gray-900">Jumpstart Your Cosmic Journey</h2>
        <p class="text-gray-600 mt-2">
          Want to see Neptuner in action? We can create some sample tasks and habits to explore.
        </p>
      </div>

      <%= if @demo_data_generating do %>
        <div class="text-center py-8">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mb-4">
          </div>
          <p class="text-gray-600">Generating cosmic demo data...</p>
          <p class="text-sm text-gray-500 mt-2">Creating sample tasks, habits, and achievements</p>
        </div>
      <% else %>
        <div class="grid md:grid-cols-2 gap-8">
          <div class="text-center">
            <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-sparkles" class="w-8 h-8 text-green-600" />
            </div>
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Generate Demo Data</h3>
            <p class="text-gray-600 mb-4">
              We'll create sample tasks with different cosmic priorities, habits with existential commentary,
              and some achievements to show you how everything works.
            </p>
            <button
              phx-click="generate_demo_data"
              disabled={@step_loading}
              class="w-full bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white font-medium py-3 px-6 rounded-lg transition-all"
            >
              Generate Demo Data
            </button>
          </div>

          <div class="text-center">
            <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-forward" class="w-8 h-8 text-gray-600" />
            </div>
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Start Fresh</h3>
            <p class="text-gray-600 mb-4">
              Prefer to start with a blank slate? You can always create your own tasks and habits from scratch.
            </p>
            <button
              phx-click="skip_demo_data"
              disabled={@step_loading}
              class="w-full border border-gray-300 hover:bg-gray-50 disabled:opacity-50 text-gray-700 font-medium py-3 px-6 rounded-lg transition-all"
            >
              Skip Demo Data
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp first_task_step(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg p-8">
      <div class="text-center mb-8">
        <h2 class="text-2xl font-bold text-gray-900">Create Your First Task</h2>
        <p class="text-gray-600 mt-2">
          Let's add something to your cosmic to-do list. Don't worry about getting it perfect—you can always edit it later.
        </p>
      </div>

      <.form for={@form} phx-submit="create_first_task" class="max-w-2xl mx-auto space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Task Title <span class="text-red-500">*</span>
          </label>
          <.input
            field={@form[:title]}
            type="text"
            placeholder="e.g., Call dentist about that wisdom tooth situation"
            required
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Description <span class="text-gray-500">(optional)</span>
          </label>
          <.input
            field={@form[:description]}
            type="textarea"
            rows="3"
            placeholder="Any additional context or existential dread about this task..."
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Cosmic Priority Level
          </label>
          <.input
            field={@form[:cosmic_priority]}
            type="select"
            options={[
              {"Matters in 10 years", "matters_10_years"},
              {"Matters in 10 days", "matters_10_days"},
              {"Matters to nobody", "matters_to_nobody"}
            ]}
            value="matters_10_days"
          />
          <p class="text-xs text-gray-500 mt-1">
            Be honest—how important is this really in the grand scheme of existence?
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Actual Importance (1-10)
          </label>
          <.input
            field={@form[:estimated_actual_importance]}
            type="number"
            min="1"
            max="10"
            value="5"
          />
          <p class="text-xs text-gray-500 mt-1">
            Your honest assessment, separate from how urgent it feels.
          </p>
        </div>

        <div class="flex gap-4">
          <button
            type="submit"
            class="flex-1 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium py-3 px-6 rounded-lg transition-all"
          >
            Create Task
          </button>
        </div>
      </.form>
    </div>
    """
  end

  defp first_connection_step(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg p-8">
      <div class="text-center mb-8">
        <h2 class="text-2xl font-bold text-gray-900">Connect Your Digital Life</h2>
        <p class="text-gray-600 mt-2">
          Connect your calendar or email to unlock meeting analytics and productivity theater insights.
        </p>
      </div>

      <div class="grid md:grid-cols-2 gap-6 max-w-3xl mx-auto">
        <div class="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-all">
          <div class="text-center">
            <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-calendar-days" class="w-6 h-6 text-blue-600" />
            </div>
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Calendar Integration</h3>
            <p class="text-sm text-gray-600 mb-4">
              Connect Google Calendar or Outlook to analyze meeting productivity and track "could have been an email" metrics.
            </p>
            <.link
              navigate={~p"/connections"}
              class="inline-flex items-center px-4 py-2 border border-blue-600 text-blue-600 hover:bg-blue-50 rounded-lg transition-all"
            >
              <.icon name="hero-link" class="w-4 h-4 mr-2" /> Connect Calendar
            </.link>
          </div>
        </div>

        <div class="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-all">
          <div class="text-center">
            <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <.icon name="hero-envelope" class="w-6 h-6 text-red-600" />
            </div>
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Email Insights</h3>
            <p class="text-sm text-gray-600 mb-4">
              Analyze email patterns and extract actionable tasks from your inbox chaos.
            </p>
            <.link
              navigate={~p"/connections"}
              class="inline-flex items-center px-4 py-2 border border-red-600 text-red-600 hover:bg-red-50 rounded-lg transition-all"
            >
              <.icon name="hero-link" class="w-4 h-4 mr-2" /> Connect Email
            </.link>
          </div>
        </div>
      </div>

      <div class="text-center mt-8">
        <p class="text-sm text-gray-500 mb-4">
          You can always connect services later from your dashboard.
        </p>
        <button phx-click="skip_connection" class="text-gray-600 hover:text-gray-800 underline">
          Skip for now →
        </button>
      </div>
    </div>
    """
  end

  defp dashboard_tour_step(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg p-8">
      <div class="text-center mb-8">
        <h2 class="text-2xl font-bold text-gray-900">Ready for Your Cosmic Dashboard</h2>
        <p class="text-gray-600 mt-2">
          Your productivity command center awaits. Let's take a quick tour of what you can do.
        </p>
      </div>

      <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <div class="text-center p-4 border border-gray-200 rounded-lg">
          <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <.icon name="hero-check-circle" class="w-5 h-5 text-blue-600" />
          </div>
          <h3 class="font-medium text-gray-900 mb-1">Task Management</h3>
          <p class="text-xs text-gray-600">Create and track tasks with cosmic priority levels</p>
        </div>

        <div class="text-center p-4 border border-gray-200 rounded-lg">
          <div class="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <.icon name="hero-arrow-path" class="w-5 h-5 text-purple-600" />
          </div>
          <h3 class="font-medium text-gray-900 mb-1">Habit Tracking</h3>
          <p class="text-xs text-gray-600">Build habits with existential commentary</p>
        </div>

        <div class="text-center p-4 border border-gray-200 rounded-lg">
          <div class="w-10 h-10 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <.icon name="hero-trophy" class="w-5 h-5 text-yellow-600" />
          </div>
          <h3 class="font-medium text-gray-900 mb-1">Achievements</h3>
          <p class="text-xs text-gray-600">Earn badges with backhanded congratulations</p>
        </div>

        <div class="text-center p-4 border border-gray-200 rounded-lg">
          <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <.icon name="hero-calendar-days" class="w-5 h-5 text-green-600" />
          </div>
          <h3 class="font-medium text-gray-900 mb-1">Meeting Analytics</h3>
          <p class="text-xs text-gray-600">Track productivity theater metrics</p>
        </div>

        <div class="text-center p-4 border border-gray-200 rounded-lg">
          <div class="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <.icon name="hero-envelope" class="w-5 h-5 text-red-600" />
          </div>
          <h3 class="font-medium text-gray-900 mb-1">Email Insights</h3>
          <p class="text-xs text-gray-600">Analyze communication patterns</p>
        </div>

        <div class="text-center p-4 border border-gray-200 rounded-lg">
          <div class="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center mx-auto mb-3">
            <.icon name="hero-chart-bar" class="w-5 h-5 text-indigo-600" />
          </div>
          <h3 class="font-medium text-gray-900 mb-1">Cosmic Perspective</h3>
          <p class="text-xs text-gray-600">Daily wisdom and reality checks</p>
        </div>
      </div>

      <div class="text-center">
        <button
          phx-click="start_dashboard_tour"
          class="bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium py-3 px-8 rounded-lg transition-all"
        >
          Enter Your Dashboard →
        </button>
      </div>
    </div>
    """
  end

  defp completion_step(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-lg p-8 text-center">
      <div class="mb-6">
        <div class="w-20 h-20 bg-gradient-to-br from-green-500 to-blue-500 rounded-full flex items-center justify-center mx-auto mb-4">
          <.icon name="hero-check-badge" class="w-10 h-10 text-white" />
        </div>
        <h2 class="text-3xl font-bold text-gray-900">Cosmic Setup Complete!</h2>
        <p class="text-lg text-gray-600 mt-4">
          Welcome to your personal productivity universe. You're ready to organize your digital rectangles with cosmic perspective.
        </p>
      </div>

      <div class="bg-gradient-to-r from-green-50 to-blue-50 rounded-lg p-6 mb-8">
        <div class="text-sm text-gray-700 space-y-2">
          <p class="font-medium">
            Your Activation Score: <span class="text-green-600">{@user.activation_score}/100</span>
          </p>
          <p class="italic">
            "You have successfully configured a digital system to manage other digital systems.
            The universe remains unchanged, but at least your tasks are organized."
          </p>
        </div>
      </div>

      <div class="space-y-4">
        <p class="text-gray-600">
          Your cosmic productivity dashboard is ready. Remember: the goal isn't to achieve perfect productivity—it's to maintain perspective while getting things done.
        </p>

        <button
          phx-click="complete_onboarding"
          class="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-medium py-4 px-6 rounded-lg transition-all text-lg"
        >
          Launch Dashboard 🚀
        </button>
      </div>
    </div>
    """
  end

  # Helper Functions

  defp advance_to_next_step(socket, next_step) do
    user = socket.assigns.user

    case Onboarding.advance_step(user, next_step) do
      {:ok, updated_user} ->
        progress = Onboarding.get_onboarding_progress(updated_user)

        socket
        |> assign(:user, updated_user)
        |> assign(:progress, progress)
        |> assign(:step_loading, false)

      {:error, _} ->
        socket
        |> put_flash(:error, "Failed to advance to next step. Please try again.")
        |> assign(:step_loading, false)
    end
  end

  defp step_number(step) do
    case step do
      :welcome -> 1
      :cosmic_setup -> 2
      :demo_data -> 3
      :first_task -> 4
      :first_connection -> 5
      :dashboard_tour -> 6
      :completed -> 6
    end
  end

  defp progress_percentage(step) do
    case step do
      :welcome -> 0
      :cosmic_setup -> 17
      :demo_data -> 33
      :first_task -> 50
      :first_connection -> 67
      :dashboard_tour -> 83
      :completed -> 100
    end
  end
end
