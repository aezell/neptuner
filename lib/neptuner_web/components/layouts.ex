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
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex items-center gap-2">
          <.product_logo />
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <.theme_toggle />
          </li>
          <div :if={@current_scope} class="flex flex-row items-center gap-2">
            <.profile_dropdown
              current_scope={@current_scope}
              position="dropdown-bottom dropdown-left"
            />
          </div>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <LiveToast.toast_group
      flash={@flash}
      connected={assigns[:socket] != nil}
      toasts_sync={assigns[:toasts_sync]}
    />
    """
  end

  def dashboard(assigns) do
    ~H"""
    <div class="min-h-screen flex">
      <div class="relative flex w-full justify-between max-w-[20rem] flex-col bg-background bg-clip-border p-4 text-secondary-content border-r border-base-300">
        <div class="flex flex-col h-full">
          <div class="flex items-center gap-4 p-4 mb-2">
            <div class="flex-1">
              <a href="/" class="flex-1 flex items-center gap-2">
                <.product_logo />
                <h5 class="block font-sans text-xl antialiased font-semibold leading-snug tracking-normal text-base-content">
                  {Application.get_env(:neptuner, :app_name)}
                </h5>
              </a>
            </div>
          </div>
          <nav class="flex min-w-[240px] flex-col gap-1 p-2 font-sans text-base font-normal text-base-content">
            <ul class="relative block w-full">
              <.link
                navigate={~p"/dashboard"}
                type="button"
                class="flex btn btn-ghost hover:text-primary items-center justify-between w-full p-3 font-sans text-xl antialiased font-semibold leading-snug text-left transition-colors"
              >
                <div class="grid mr-4 place-items-center">
                  <.icon name="hero-squares-2x2" class="size-6" />
                </div>
                <p class="block mr-auto text-base antialiased font-normal leading-relaxed">
                  Dashboard
                </p>
              </.link>
              <.link
                navigate={~p"/organisations/manage"}
                type="button"
                class="flex btn btn-ghost hover:text-primary items-center justify-between w-full p-3 font-sans text-xl antialiased font-semibold leading-snug text-left transition-colors"
              >
                <div class="grid mr-4 place-items-center">
                  <.icon name="hero-building-office" class="size-6" />
                </div>
                <p class="block mr-auto text-base antialiased font-normal leading-relaxed">
                  Organisation
                </p>
              </.link>
            </ul>
          </nav>
        </div>
        <div class="flex-none pt-6">
          <ul class="flex flex-column px-1 space-x-4 justify-between items-center">
            <li>
              <.theme_toggle />
            </li>
            <div class="flex flex-row items-center gap-2">
              <.profile_dropdown
                current_scope={@current_scope}
                position="dropdown-top dropdown-right"
              />
            </div>
          </ul>
        </div>
      </div>

      <div class="flex-1 overflow-x-hidden transition-all duration-300 ease-in-out">
        <main class="px-4 py-20 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-7xl space-y-4">
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
