defmodule NeptunerWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use NeptunerWeb, :html
  alias Backpex

  embed_templates "layouts/*"

  def app(assigns) do
    ~H"""
    <!-- Mobile-optimized header -->
    <header class="navbar bg-base-100 border-b border-base-300 px-3 py-2 sm:px-6 lg:px-8 sticky top-0 z-40">
      <div class="flex-1">
        <a href="/" class="flex items-center gap-2 p-2 rounded-lg hover:bg-base-200 transition-colors">
          <.product_logo />
          <span class="font-semibold text-base-content text-sm sm:text-base hidden xs:inline">
            {Application.get_env(:neptuner, :app_name)}
          </span>
        </a>
      </div>
      
      <div class="flex-none">
        <div class="flex items-center gap-2">
          <!-- Theme toggle with mobile-friendly sizing -->
          <div class="hidden sm:block">
            <.theme_toggle />
          </div>
          
          <!-- Mobile theme toggle (simplified) -->
          <div class="sm:hidden">
            <button
              phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
              class="btn btn-ghost btn-square btn-sm"
              title="Toggle theme"
            >
              <.icon name="hero-sun" class="size-4" />
            </button>
          </div>
          
          <!-- Profile dropdown with mobile optimization -->
          <div :if={@current_scope}>
            <.profile_dropdown
              current_scope={@current_scope}
              position="dropdown-bottom dropdown-end"
              class="btn-square"
            />
          </div>
          
          <!-- Login button for unauthenticated users -->
          <div :if={!@current_scope} class="flex items-center gap-2">
            <.link
              navigate={~p"/users/log-in"}
              class="btn btn-primary btn-sm"
            >
              <span class="hidden sm:inline">Log in</span>
              <span class="sm:hidden">Login</span>
            </.link>
          </div>
        </div>
      </div>
    </header>

    <!-- Mobile-optimized main content -->
    <main class="px-3 py-4 sm:px-6 lg:px-8 min-h-screen">
      <div class="mx-auto max-w-4xl space-y-4 sm:space-y-6">
        {render_slot(@inner_block)}
      </div>
    </main>

    <!-- Mobile-optimized toast notifications -->
    <LiveToast.toast_group
      flash={@flash}
      connected={assigns[:socket] != nil}
      toasts_sync={assigns[:toasts_sync]}
    />
    """
  end

  def dashboard(assigns) do
    ~H"""
    <!-- Mobile-first responsive dashboard layout -->
    <div class="min-h-screen flex flex-col lg:flex-row">
      <!-- Mobile header with menu toggle -->
      <div class="lg:hidden bg-base-100 border-b border-base-300 px-4 py-3">
        <div class="flex items-center justify-between">
          <a href="/" class="flex items-center gap-2">
            <.product_logo />
            <h5 class="text-lg font-semibold text-base-content">
              {Application.get_env(:neptuner, :app_name)}
            </h5>
          </a>
          
          <!-- Mobile menu button -->
          <button
            class="btn btn-ghost btn-square"
            onclick="document.getElementById('mobile-sidebar').classList.toggle('hidden')"
            aria-label="Toggle menu"
          >
            <.icon name="hero-bars-3" class="size-6" />
          </button>
        </div>
      </div>

      <!-- Mobile sidebar overlay -->
      <div
        id="mobile-sidebar"
        class="fixed inset-0 z-50 bg-black bg-opacity-50 lg:hidden hidden"
        onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
      >
        <div
          class="w-80 h-full bg-base-100 shadow-xl"
          onclick="event.stopPropagation()"
        >
          <div class="flex flex-col h-full p-4">
            <!-- Mobile sidebar header -->
            <div class="flex items-center justify-between mb-6">
              <a href="/" class="flex items-center gap-2">
                <.product_logo />
                <h5 class="text-lg font-semibold text-base-content">
                  {Application.get_env(:neptuner, :app_name)}
                </h5>
              </a>
              <button
                class="btn btn-ghost btn-square btn-sm"
                onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </div>
            
            <!-- Mobile navigation -->
            <nav class="flex-1">
              <ul class="space-y-2">
                <li>
                  <.link
                    navigate={~p"/dashboard"}
                    class="flex items-center gap-3 p-4 rounded-lg hover:bg-base-200 transition-colors text-base-content"
                    onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
                  >
                    <.icon name="hero-squares-2x2" class="size-6" />
                    <span class="font-medium">Dashboard</span>
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/tasks"}
                    class="flex items-center gap-3 p-4 rounded-lg hover:bg-base-200 transition-colors text-base-content"
                    onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
                  >
                    <.icon name="hero-check-circle" class="size-6" />
                    <span class="font-medium">Tasks</span>
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/habits"}
                    class="flex items-center gap-3 p-4 rounded-lg hover:bg-base-200 transition-colors text-base-content"
                    onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
                  >
                    <.icon name="hero-arrow-path" class="size-6" />
                    <span class="font-medium">Habits</span>
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/achievements"}
                    class="flex items-center gap-3 p-4 rounded-lg hover:bg-base-200 transition-colors text-base-content"
                    onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
                  >
                    <.icon name="hero-trophy" class="size-6" />
                    <span class="font-medium">Achievements</span>
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/connections"}
                    class="flex items-center gap-3 p-4 rounded-lg hover:bg-base-200 transition-colors text-base-content"
                    onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
                  >
                    <.icon name="hero-link" class="size-6" />
                    <span class="font-medium">Connections</span>
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/organisations/manage"}
                    class="flex items-center gap-3 p-4 rounded-lg hover:bg-base-200 transition-colors text-base-content"
                    onclick="document.getElementById('mobile-sidebar').classList.add('hidden')"
                  >
                    <.icon name="hero-building-office" class="size-6" />
                    <span class="font-medium">Organisation</span>
                  </.link>
                </li>
              </ul>
            </nav>
            
            <!-- Mobile sidebar footer -->
            <div class="border-t border-base-300 pt-4 mt-4">
              <div class="flex items-center justify-between">
                <.theme_toggle />
                <.profile_dropdown
                  current_scope={@current_scope}
                  position="dropdown-top dropdown-right"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Desktop sidebar -->
      <div class="hidden lg:flex relative w-full max-w-[20rem] flex-col bg-base-100 border-r border-base-300">
        <div class="flex flex-col h-full p-4">
          <div class="flex items-center gap-3 mb-6">
            <a href="/" class="flex items-center gap-2">
              <.product_logo />
              <h5 class="text-lg font-semibold text-base-content">
                {Application.get_env(:neptuner, :app_name)}
              </h5>
            </a>
          </div>
          
          <nav class="flex-1">
            <ul class="space-y-1">
              <li>
                <.link
                  navigate={~p"/dashboard"}
                  class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors text-base-content w-full"
                >
                  <.icon name="hero-squares-2x2" class="size-5" />
                  <span class="font-medium">Dashboard</span>
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/tasks"}
                  class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors text-base-content w-full"
                >
                  <.icon name="hero-check-circle" class="size-5" />
                  <span class="font-medium">Tasks</span>
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/habits"}
                  class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors text-base-content w-full"
                >
                  <.icon name="hero-arrow-path" class="size-5" />
                  <span class="font-medium">Habits</span>
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/achievements"}
                  class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors text-base-content w-full"
                >
                  <.icon name="hero-trophy" class="size-5" />
                  <span class="font-medium">Achievements</span>
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/connections"}
                  class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors text-base-content w-full"
                >
                  <.icon name="hero-link" class="size-5" />
                  <span class="font-medium">Connections</span>
                </.link>
              </li>
              <li>
                <.link
                  navigate={~p"/organisations/manage"}
                  class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors text-base-content w-full"
                >
                  <.icon name="hero-building-office" class="size-5" />
                  <span class="font-medium">Organisation</span>
                </.link>
              </li>
            </ul>
          </nav>
          
          <div class="border-t border-base-300 pt-4 mt-4">
            <div class="flex items-center justify-between">
              <.theme_toggle />
              <.profile_dropdown
                current_scope={@current_scope}
                position="dropdown-top dropdown-right"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Main content area -->
      <div class="flex-1 overflow-x-hidden">
        <main class="px-3 py-4 sm:px-6 lg:px-8 lg:py-8">
          <div class="mx-auto max-w-7xl space-y-4 sm:space-y-6">
            {render_slot(@inner_block)}
          </div>
        </main>

        <LiveToast.toast_group
          flash={@flash}
          connected={assigns[:socket] != nil}
          toasts_sync={assigns[:toasts_sync]}
        />
      </div>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-[33%] h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-[33%] [[data-theme=dark]_&]:left-[66%] transition-[left]" />

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})} class="flex p-2">
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})} class="flex p-2">
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})} class="flex p-2">
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  def blog(assigns) do
    ~H"""
    <Backpex.HTML.Layout.app_shell fluid={@fluid?}>
      <:topbar>
        <Backpex.HTML.Layout.topbar_branding />

        <Backpex.HTML.Layout.topbar_dropdown class="mr-2 md:mr-0">
          <:label>
            <label>
              <.icon name="hero-user" class="h-4 w-4" />
            </label>
          </:label>

          <li
            type="button"
            label={translate_backpex("Sign out")}
            icon="hero-arrow-right-start-on-rectangle"
            click="logout"
          />
        </Backpex.HTML.Layout.topbar_dropdown>
      </:topbar>

      <:sidebar>
        <Backpex.HTML.Layout.sidebar_item current_url={@current_url} navigate={~p"/admin/posts"} />
      </:sidebar>

      <div class="p-6">
        {@inner_content}
      </div>
    </Backpex.HTML.Layout.app_shell>
    """
  end
end
