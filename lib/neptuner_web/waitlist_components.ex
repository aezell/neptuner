defmodule NeptunerWeb.WaitlistComponents do
  @moduledoc """
  Waitlist components and helper functions for collecting user emails and information.
  """
  use Phoenix.Component
  import NeptunerWeb.CoreComponents

  @doc """
  Checks if waitlist mode is enabled.
  """
  def waitlist_mode_enabled? do
    FunWithFlags.enabled?(:waitlist_mode)
  end

  @doc """
  Renders a simple email signup form for the waitlist.
  """
  attr :id, :string, default: "waitlist-form"
  attr :title, :string, default: "Join the Waitlist"
  attr :subtitle, :string, default: "Be the first to know when we launch"
  attr :class, :string, default: ""

  def simple_waitlist_form(assigns) do
    ~H"""
    <div class={["text-center w-full", @class]}>
      <form
        id={@id}
        action="/waitlist"
        method="post"
        class="inline-flex flex-col sm:flex-row gap-2 [>input]:min-w-48 max-w-xl mx-auto"
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

        <.input
          value=""
          type="email"
          name="email"
          placeholder="Enter your email"
          required
          class="flex-1 w-full"
        />
        <.button type="submit" variant="primary" class="whitespace-nowrap">
          Join Waitlist
        </.button>
      </form>
      <p class="text-base-500 text-sm mb-4">{@subtitle}</p>
    </div>
    """
  end

  @doc """
  Renders a detailed waitlist form with additional fields.
  """
  attr :id, :string, default: "detailed-waitlist-form"
  attr :title, :string, default: "Join the Waitlist"
  attr :subtitle, :string, default: "Help us build something amazing for you"
  attr :class, :string, default: ""

  def detailed_waitlist_form(assigns) do
    ~H"""
    <div class={["max-w-md mx-auto", @class]}>
      <div class="text-center mb-6">
        <h3 class="text-xl font-medium text-base-content mb-2">{@title}</h3>
        <p class="text-base-500">{@subtitle}</p>
      </div>
      <form id={@id} action="/waitlist" method="post" class="space-y-4">
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <.input type="email" name="email" label="Email" placeholder="your@email.com" required />
        <.input type="text" name="name" label="Name" placeholder="Your name" />
        <.input type="text" name="company" label="Company" placeholder="Your company" />
        <.input type="text" name="role" label="Role" placeholder="Your role" />
        <.input
          type="textarea"
          name="use_case"
          label="How will you use this?"
          placeholder="Tell us about your use case..."
          rows="3"
        />
        <.button type="submit" variant="primary" class="w-full">
          Join Waitlist
        </.button>
      </form>
    </div>
    """
  end

  @doc """
  Renders a hero-style waitlist CTA.
  """
  attr :id, :string, default: "hero-waitlist"
  attr :title, :string, default: "Get Early Access"

  attr :subtitle, :string,
    default: "Join the waitlist and be among the first to experience our platform"

  attr :class, :string, default: ""

  def hero_waitlist_cta(assigns) do
    ~H"""
    <div class={["text-center", @class]}>
      <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-serif font-medium text-base-content mb-4">
        {@title}
      </h2>
      <p class="text-base sm:text-lg md:text-xl text-base-500 mb-8 max-w-2xl mx-auto">
        {@subtitle}
      </p>
      <form
        id={@id}
        action="/waitlist"
        method="post"
        class="flex flex-col sm:flex-row gap-3 max-w-lg mx-auto"
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <.input
          type="email"
          name="email"
          placeholder="Enter your email address"
          required
          class="flex-1 text-lg"
        />
        <.button
          type="submit"
          variant="primary"
          class="bg-accent-500 hover:bg-accent-600 focus:ring-accent-600 text-lg px-8"
        >
          Get Early Access
        </.button>
      </form>
    </div>
    """
  end
end
