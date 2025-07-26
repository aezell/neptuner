defmodule Mix.Tasks.Neptuner.Gen.Waitlist do
  @moduledoc """
  Generates waitlist functionality for the SaaS template using Igniter.

  This task creates:
  - Waitlist schema and migration
  - Waitlist components for email collection
  - Fun with flags configuration for waitlist mode
  - Updates marketing components to conditionally show waitlist

      $ mix neptuner.gen.waitlist

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)

    igniter
    |> create_waitlist_schema(app_name)
    |> create_waitlist_migration()
    |> create_waitlist_components(app_name)
    |> create_waitlist_controller(app_name)
    |> setup_fun_with_flags()
    |> update_router()
    |> update_web()
    |> print_completion_notice()
  end

  defp create_waitlist_schema(igniter, app_name) do
    schema_content = """
    defmodule Neptuner.Waitlist.Entry do
      @moduledoc \"\"\"
      Waitlist entry schema for collecting potential user information.
      \"\"\"
      use Neptuner.Schema

      schema "waitlist_entries" do
        field :email, :string
        field :name, :string
        field :company, :string
        field :role, :string
        field :use_case, :string
        field :subscribed_at, :naive_datetime

        timestamps(type: :utc_datetime)
      end

      @doc false
      def changeset(entry, attrs) do
        entry
        |> cast(attrs, [:email, :name, :company, :role, :use_case])
        |> validate_required([:email])
        |> validate_format(:email, ~r/^[^\\s]+@[^\\s]+$/, message: "must have the @ sign and no spaces")
        |> validate_length(:email, max: 160)
        |> validate_length(:name, max: 80)
        |> validate_length(:company, max: 100)
        |> validate_length(:role, max: 50)
        |> validate_length(:use_case, max: 500)
        |> unique_constraint(:email)
        |> put_subscribed_at()
      end

      defp put_subscribed_at(changeset) do
        if changeset.valid? and get_field(changeset, :subscribed_at) == nil do
          put_change(
            changeset,
            :subscribed_at,
            NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          )
        else
          changeset
        end
      end
    end
    """

    Igniter.create_new_file(igniter, "lib/#{app_name}/waitlist/entry.ex", schema_content)
  end

  defp create_waitlist_migration(igniter) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")

    migration_content = """
    defmodule Neptuner.Repo.Migrations.CreateWaitlistEntries do
      use Ecto.Migration

      def change do
        create table(:waitlist_entries, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :email, :string, null: false
          add :name, :string
          add :company, :string
          add :role, :string
          add :use_case, :text
          add :subscribed_at, :naive_datetime

          timestamps(type: :utc_datetime)
        end

        create unique_index(:waitlist_entries, [:email])
        create index(:waitlist_entries, [:subscribed_at])
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "priv/repo/migrations/#{timestamp}_create_waitlist_entries.exs",
      migration_content
    )
  end

  defp create_waitlist_components(igniter, app_name) do
    components_content = """
    defmodule NeptunerWeb.WaitlistComponents do
      @moduledoc \"\"\"
      Waitlist components and helper functions for collecting user emails and information.
      \"\"\"
      use Phoenix.Component
      import NeptunerWeb.CoreComponents

      @doc \"\"\"
      Checks if waitlist mode is enabled.
      \"\"\"
      def waitlist_mode_enabled? do
        FunWithFlags.enabled?(:waitlist_mode)
      end

      @doc \"\"\"
      Renders a simple email signup form for the waitlist.
      \"\"\"
      attr :id, :string, default: "waitlist-form"
      attr :title, :string, default: "Join the Waitlist"
      attr :subtitle, :string, default: "Be the first to know when we launch"
      attr :class, :string, default: ""

      def simple_waitlist_form(assigns) do
        ~H\"\"\"
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
        \"\"\"
      end

      @doc \"\"\"
      Renders a detailed waitlist form with additional fields.
      \"\"\"
      attr :id, :string, default: "detailed-waitlist-form"
      attr :title, :string, default: "Join the Waitlist"
      attr :subtitle, :string, default: "Help us build something amazing for you"
      attr :class, :string, default: ""

      def detailed_waitlist_form(assigns) do
        ~H\"\"\"
        <div class={["max-w-md mx-auto", @class]}>
          <div class="text-center mb-6">
            <h3 class="text-xl font-medium text-base-content mb-2"><%= @title %></h3>
            <p class="text-base-500"><%= @subtitle %></p>
          </div>
          <form id={@id} action="/waitlist" method="post" class="space-y-4">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
            <.input
              type="email"
              name="email"
              label="Email"
              placeholder="your@email.com"
              required
            />
            <.input
              type="text"
              name="name"
              label="Name"
              placeholder="Your name"
            />
            <.input
              type="text"
              name="company"
              label="Company"
              placeholder="Your company"
            />
            <.input
              type="text"
              name="role"
              label="Role"
              placeholder="Your role"
            />
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
        \"\"\"
      end

      @doc \"\"\"
      Renders a hero-style waitlist CTA.
      \"\"\"
      attr :id, :string, default: "hero-waitlist"
      attr :title, :string, default: "Get Early Access"
      attr :subtitle, :string, default: "Join the waitlist and be among the first to experience our platform"
      attr :class, :string, default: ""

      def hero_waitlist_cta(assigns) do
        ~H\"\"\"
        <div class={["text-center", @class]}>
          <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-serif font-medium text-base-content mb-4">
            <%= @title %>
          </h2>
          <p class="text-base sm:text-lg md:text-xl text-base-500 mb-8 max-w-2xl mx-auto">
            <%= @subtitle %>
          </p>
          <form id={@id} action="/waitlist" method="post" class="flex flex-col sm:flex-row gap-3 max-w-lg mx-auto">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
            <.input
              type="email"
              name="email"
              placeholder="Enter your email address"
              required
              class="flex-1 text-lg"
            />
            <.button type="submit" variant="primary" class="bg-accent-500 hover:bg-accent-600 focus:ring-accent-600 text-lg px-8">
              Get Early Access
            </.button>
          </form>
        </div>
        \"\"\"
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/#{app_name}_web/components/waitlist_components.ex",
      components_content
    )
  end

  defp create_waitlist_controller(igniter, app_name) do
    controller_content = """
    defmodule NeptunerWeb.WaitlistController do
      use NeptunerWeb, :controller

      alias Neptuner.Waitlist.Entry
      alias Neptuner.Repo

      def join(conn, %{"email" => _email} = params) do
        changeset = Entry.changeset(%Entry{}, params)

        case Repo.insert(changeset) do
          {:ok, _entry} ->
            conn
            |> put_flash(:info, "Thanks for joining our waitlist! We'll be in touch soon.")
            |> redirect(to: "/")

          {:error, %Ecto.Changeset{} = changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
              Enum.reduce(opts, msg, fn {k, v}, acc ->
                String.replace(acc, "%{\#{k}}", to_string(v))
              end)
            end)

            error_message = case errors do
              %{email: [msg | _]} -> "Email " <> msg
              _ -> "There was an error joining the waitlist. Please try again."
            end

            conn
            |> put_flash(:error, error_message)
            |> redirect(to: "/")
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/#{app_name}_web/controllers/waitlist_controller.ex",
      controller_content
    )
  end

  defp setup_fun_with_flags(igniter) do
    seeds_content = """
    # Waitlist feature flag setup

    # Enable waitlist mode by default
    case FunWithFlags.enable(:waitlist_mode) do
      {:ok, _flag} -> IO.puts("✓ Waitlist mode enabled")
      {:error, err} -> IO.puts("✗ Failed to enable waitlist mode: \#{inspect(err)}")
    end
    """

    Igniter.create_new_file(igniter, "priv/repo/seeds/waitlist.exs", seeds_content)
  end

  defp update_router(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "post \"/waitlist\"") do
        # Route already exists
        source
      else
        # Find the line with get "/" and add the post route after it
        updated_content =
          String.replace(
            content,
            ~r/(get\s+"\/",\s+PageController,\s+:home)/,
            "\\1\n    post \"/waitlist\", WaitlistController, :join"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_web(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "import NeptunerWeb.WaitlistComponents") do
        # Import already exists
        source
      else
        # Find the CoreComponents import and add WaitlistComponents after it
        updated_content =
          String.replace(
            content,
            ~r/(import NeptunerWeb\.CoreComponents)/,
            "\\1\n      import NeptunerWeb.WaitlistComponents"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Waitlist Integration Complete! ✅

    Your waitlist functionality has been successfully set up. Here's what was created:

    ### Files Created:
    - Waitlist entry schema with validations
    - Waitlist UI components (simple, detailed, hero styles)
    - Form submission controller with error handling
    - Feature flag helpers
    - Database migration
    - Feature flag seeds

    ### Components Updated:
    - Router updated with waitlist route
    - PageHTML updated with component imports

    ### Next Steps:
    1. Run `mix ecto.migrate` to create the waitlist_entries table
    2. Run `mix run priv/repo/seeds/waitlist.exs` to enable the waitlist_mode flag
    3. Use `FunWithFlags.disable(:waitlist_mode)` to switch back to regular mode

    ### Available Components:
    - `<.simple_waitlist_form />` - Basic email signup
    - `<.detailed_waitlist_form />` - Full form with additional fields
    - `<.hero_waitlist_cta />` - Hero-style waitlist CTA

    ### Helper Functions:
    - `waitlist_mode_enabled?()` - Check if waitlist mode is active

    🎉 Ready to start collecting waitlist signups!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
