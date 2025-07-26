defmodule Mix.Tasks.Neptuner.Setup do
  @moduledoc """
  Interactive setup script for the SaaS Template Starter.

  This task provides an interactive setup experience for customizing your
  SaaS template project. It will:

  1. Ask for a new project name
  2. Ask if you want waitlist functionality
  3. Run the appropriate generators and setup tasks
  4. Rename the project (last step)

  ## Usage

      $ mix neptuner.setup

  """
  use Mix.Task
  require Logger

  @shortdoc "Interactive setup for SaaS Template Starter"

  # Color helper functions
  defp puts_cyan(text), do: IO.puts(IO.ANSI.cyan() <> text <> IO.ANSI.reset())
  defp puts_yellow(text), do: IO.puts(IO.ANSI.yellow() <> text <> IO.ANSI.reset())
  defp puts_green(text), do: IO.puts(IO.ANSI.green() <> text <> IO.ANSI.reset())
  defp puts_red(text), do: IO.puts(IO.ANSI.red() <> text <> IO.ANSI.reset())
  defp puts_blue(text), do: IO.puts(IO.ANSI.blue() <> text <> IO.ANSI.reset())
  defp puts_white(text), do: IO.puts(IO.ANSI.white() <> text <> IO.ANSI.reset())
  defp puts_light_black(text), do: IO.puts(IO.ANSI.light_black() <> text <> IO.ANSI.reset())
  defp puts_magenta(text), do: IO.puts(IO.ANSI.magenta() <> text <> IO.ANSI.reset())

  defp setup_logger do
    :ok = :logger.remove_handler(:default)

    :ok =
      :logger.add_handler(:default, :logger_std_h, %{
        config: %{type: {:device, Owl.LiveScreen}},
        formatter: Logger.Formatter.new()
      })
  end

  def run(_args) do
    # Start necessary applications
    Application.ensure_all_started(:owl)
    setup_logger()

    puts_cyan("🚀 Welcome to SaaS Template Starter Setup!")
    puts_light_black("This interactive setup will customize your project.\n")

    try do
      project_name = prompt_for_project_name()
      wants_waitlist = prompt_for_waitlist()
      wants_analytics = prompt_for_analytics()
      wants_error_tracker = prompt_for_error_tracker()
      wants_google_oauth = prompt_for_google_oauth()
      wants_github_oauth = prompt_for_github_oauth()
      wants_llm = prompt_for_llm()
      wants_oban = prompt_for_oban()
      wants_multi_tenancy = prompt_for_multi_tenancy()
      wants_blog = prompt_for_blog()
      payment_processor = prompt_for_payment_processor()
      admin_password = prompt_for_admin_password()

      puts_yellow("\n📋 Setup Summary:")
      puts_white("  • Project Name: #{project_name}")
      puts_white("  • Waitlist Mode: #{if wants_waitlist, do: "Yes", else: "No"}")
      puts_white("  • Analytics: #{if wants_analytics, do: "Yes", else: "No"}")
      puts_white("  • Error Tracking: #{if wants_error_tracker, do: "Yes", else: "No"}")
      puts_white("  • Google OAuth: #{if wants_google_oauth, do: "Yes", else: "No"}")
      puts_white("  • GitHub OAuth: #{if wants_github_oauth, do: "Yes", else: "No"}")
      puts_white("  • LLM Integration: #{if wants_llm, do: "Yes", else: "No"}")
      puts_white("  • Oban Background Jobs: #{if wants_oban, do: "Yes", else: "No"}")
      puts_white("  • Multi tenancy: #{if wants_multi_tenancy, do: "Yes", else: "No"}")
      puts_white("  • Blog System: #{if wants_blog, do: "Yes", else: "No"}")
      puts_white("  • Payment Processor: #{payment_processor}")

      puts_white(
        "  • Admin Password: #{if String.length(admin_password) > 0, do: "Custom", else: "Generated"}"
      )

      confirm_setup = Owl.IO.confirm(message: "\nProceed with setup?")

      if confirm_setup do
        execute_setup(
          project_name,
          wants_waitlist,
          wants_analytics,
          wants_error_tracker,
          wants_google_oauth,
          wants_github_oauth,
          wants_llm,
          wants_oban,
          wants_multi_tenancy,
          wants_blog,
          payment_processor,
          admin_password
        )
      else
        puts_red("Setup cancelled.")
      end
    rescue
      error ->
        puts_red("Setup failed: #{inspect(error)}")
        puts_light_black("You can run the individual commands manually if needed.")
    end
  end

  defp prompt_for_project_name do
    puts_blue("📝 Let's customize your project name.")
    puts_light_black("Current project name: Neptuner")
    puts_light_black("Choose a new name (PascalCase, e.g., MyAwesomeApp):\n")

    project_name =
      Owl.IO.input(
        message: "Enter your project name",
        cast: :string
      )

    # Validate the project name
    if valid_project_name?(project_name) do
      project_name
    else
      puts_red("Invalid project name. Please use PascalCase (e.g., MyAwesomeApp)")

      prompt_for_project_name()
    end
  end

  defp prompt_for_waitlist do
    puts_blue("\n🎯 Waitlist Functionality")
    puts_light_black("Add waitlist functionality to collect early user signups?")
    puts_light_black("This includes email collection forms, database schema, and feature flags.")

    Owl.IO.confirm(message: "Enable waitlist mode?")
  end

  defp prompt_for_analytics do
    puts_blue("\n📊 Analytics")
    puts_light_black("Add Phoenix Analytics to track page views, user sessions, and metrics?")

    puts_light_black(
      "This includes real-time analytics dashboard and automatic request tracking."
    )

    puts_yellow("⚠️  WARNING: Fly.io does not support Phoenix Analytics at the time of writing.")
    puts_light_black("Only enable if you plan to deploy outside of Fly.io or can use alternative hosting.")

    Owl.IO.confirm(message: "Enable analytics tracking?")
  end

  defp prompt_for_error_tracker do
    puts_blue("\n🔍 Error Tracking")
    puts_light_black("Add Error Tracker to monitor and track application errors?")

    puts_light_black(
      "This includes error dashboard, automatic error capture, and error analysis."
    )

    Owl.IO.confirm(message: "Enable error tracking?")
  end

  defp prompt_for_google_oauth do
    puts_blue("\n🔐 Google OAuth")
    puts_light_black("Add Google OAuth authentication for social login?")
    puts_light_black("Users will be able to sign in with their Google accounts.")

    Owl.IO.confirm(message: "Enable Google OAuth?")
  end

  defp prompt_for_github_oauth do
    puts_blue("\n🔐 GitHub OAuth")
    puts_light_black("Add GitHub OAuth authentication for social login?")
    puts_light_black("Users will be able to sign in with their GitHub accounts.")

    Owl.IO.confirm(message: "Enable GitHub OAuth?")
  end

  defp prompt_for_llm do
    puts_blue("\n🤖 LLM Integration")
    puts_light_black("Add LLM functionality with LangChain and OpenAI integration?")

    puts_light_black(
      "This includes AI chat capabilities, text generation, and JSON response parsing."
    )

    Owl.IO.confirm(message: "Enable LLM integration?")
  end

  defp prompt_for_oban do
    puts_blue("\n⚙️ Oban Background Jobs")
    puts_light_black("Add Oban for reliable background job processing?")
    puts_light_black("This includes job queues, scheduling, and a web UI for monitoring.")

    Owl.IO.confirm(message: "Enable Oban background jobs?")
  end

  defp prompt_for_multi_tenancy do
    puts_blue("\n🏢 Multi-Tenancy (Organisations)")

    puts_light_black(
      "Add multi-tenancy functionality with organisations and role-based access control?"
    )

    puts_light_black("This includes organisation management, invitations, and member roles.")

    Owl.IO.confirm(message: "Enable multi-tenancy?")
  end

  defp prompt_for_blog do
    puts_blue("\n📝 Blog System")
    puts_light_black("Add a complete blog system with admin interface and public pages?")

    puts_light_black(
      "This includes blog posts, markdown support, SEO optimization, and Backpex admin interface."
    )

    Owl.IO.confirm(message: "Enable blog functionality?")
  end

  defp prompt_for_payment_processor do
    puts_blue("\n💳 Payment Processing")
    puts_light_black("Choose a payment processor for your SaaS application.")
    puts_light_black("This includes payment handling, webhooks, and purchase tracking.")

    options = [
      {"💳 Stripe", "stripe"},
      {"🍋 LemonSqueezy", "lemonsqueezy"},
      {"❄️ Polar.sh", "polar"},
      {"❌ None", "none"}
    ]

    {_display, value} =
      Owl.IO.select(
        options,
        label: "Select payment processor:",
        render_as: fn {display, _value} -> display end
      )

    value
  end

  defp prompt_for_admin_password do
    puts_blue("\n🔐 Admin Panel Security")
    puts_light_black("Set a password for admin panel access (feature flags, etc.).")
    puts_light_black("Leave blank to generate a secure random password.")

    admin_password =
      Owl.IO.input(
        message: "Enter admin password (or press Enter for auto-generation)",
        cast: :string,
        optional: true,
        secret: true
      )

    if is_nil(admin_password) or String.trim(admin_password) == "" do
      # Generate a secure password
      generate_secure_password()
    else
      String.trim(admin_password)
    end
  end

  defp generate_secure_password do
    # Generate a 16-character cryptographically secure password
    :crypto.strong_rand_bytes(16)
    |> Base.encode64()
    |> binary_part(0, 16)
  end

  defp valid_project_name?(name) do
    # Check if it's a valid Elixir module name
    String.match?(name, ~r/^[A-Z][a-zA-Z0-9]*$/) and String.length(name) > 1
  end

  defp execute_setup(
         project_name,
         wants_waitlist,
         wants_analytics,
         wants_error_tracker,
         wants_google_oauth,
         wants_github_oauth,
         wants_llm,
         wants_oban,
         wants_multi_tenancy,
         wants_blog,
         payment_processor,
         admin_password
       ) do
    puts_cyan("\n🔧 Executing setup...")

    # Step 1: Generate waitlist before rename (if requested)
    if wants_waitlist do
      execute_step("waitlist", "Setting up waitlist functionality...", fn ->
        generate_waitlist()
      end)

      execute_step("deps_waitlist", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 2: Generate analytics before rename (if requested)
    if wants_analytics do
      execute_step("analytics", "Setting up analytics tracking...", fn ->
        generate_analytics()
      end)

      execute_step("deps_analytics", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 3: Generate error tracker before rename (if requested)
    if wants_error_tracker do
      execute_step("error_tracker", "Setting up error tracking...", fn ->
        generate_error_tracker()
      end)

      execute_step("deps_error_tracker", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 4: Generate Google OAuth before rename (if requested)
    if wants_google_oauth do
      execute_step("google_oauth", "Setting up Google OAuth authentication...", fn ->
        generate_google_oauth()
      end)

      execute_step("deps_google", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 4: Generate GitHub OAuth before rename (if requested)
    if wants_github_oauth do
      execute_step("github_oauth", "Setting up GitHub OAuth authentication...", fn ->
        generate_github_oauth()
      end)

      execute_step("deps_github", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 5: Generate LLM integration before rename (if requested)
    if wants_llm do
      execute_step("llm", "Setting up LLM integration with LangChain...", fn ->
        generate_llm()
      end)

      execute_step("deps_llm", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 6: Install Oban before rename (if requested)
    if wants_oban do
      execute_step("oban", "Installing Oban background job processor...", fn ->
        install_oban()
      end)

      execute_step("oban_web", "Installing Oban Web UI...", fn ->
        install_oban_web()
      end)

      execute_step("deps_oban", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 7: Generate multi-tenancy functionality before rename (if requested)
    if wants_multi_tenancy do
      execute_step("organisations", "Setting up multi-tenancy with organisations...", fn ->
        generate_organisations()
      end)

      execute_step("organisations_test", "Setting up multi-tenancy tests...", fn ->
        generate_organisations_test()
      end)

      execute_step("deps_organisations", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 8: Generate blog functionality before rename (if requested)
    if wants_blog do
      execute_step("blog", "Setting up blog system with admin interface...", fn ->
        generate_blog()
      end)

      execute_step("deps_blog", "Fetching dependencies...", fn ->
        fetch_dependencies()
      end)
    end

    # Step 9: Generate payment processor integration before rename (if requested)
    case payment_processor do
      "stripe" ->
        execute_step("stripe", "Setting up Stripe payment integration...", fn ->
          generate_stripe()
        end)

        execute_step("deps_stripe", "Fetching dependencies...", fn ->
          fetch_dependencies()
        end)

      "lemonsqueezy" ->
        execute_step("lemonsqueezy", "Setting up LemonSqueezy payment integration...", fn ->
          generate_lemonsqueezy()
        end)

        execute_step("deps_lemonsqueezy", "Fetching dependencies...", fn ->
          fetch_dependencies()
        end)

      "polar" ->
        execute_step("polar", "Setting up Polar.sh payment integration...", fn ->
          generate_polar()
        end)

        execute_step("deps_polar", "Fetching dependencies...", fn ->
          fetch_dependencies()
        end)

      "none" ->
        :ok
    end

    # Step 10: Set up admin password
    execute_step("admin_password", "Setting up admin password...", fn ->
      setup_admin_password(admin_password)
    end)

    # Step 11: Rename project
    execute_step("rename", "Renaming project to #{project_name}...", fn ->
      rename_project(project_name)
    end)

    # Step 12: Setup database with new name
    execute_step("database", "Setting up database with new project name...", fn ->
      setup_database_after_rename()
    end)

    # Step 13: Run waitlist seeds (if waitlist was enabled)
    if wants_waitlist do
      execute_step("waitlist_seeds", "Enabling waitlist mode...", fn -> run_waitlist_seeds() end)
    end

    # Step 14: Rebuild assets
    execute_step("assets", "Rebuilding assets with new project name...", fn ->
      rebuild_assets()
    end)

    # Wait for final render and stop live screen
    Owl.LiveScreen.await_render()
    
    # Stop live screen to prevent duplicate output
    try do
      Owl.LiveScreen.stop()
    catch
      _ -> :ok  # Ignore if already stopped
    end

    # Final instructions
    display_completion_message(
      project_name,
      wants_waitlist,
      wants_analytics,
      wants_error_tracker,
      wants_google_oauth,
      wants_github_oauth,
      wants_llm,
      wants_oban,
      wants_multi_tenancy,
      wants_blog,
      payment_processor,
      admin_password
    )

    # Save setup information to file
    save_setup_info_to_file(
      project_name,
      wants_waitlist,
      wants_analytics,
      wants_error_tracker,
      wants_google_oauth,
      wants_github_oauth,
      wants_llm,
      wants_oban,
      wants_multi_tenancy,
      wants_blog,
      payment_processor,
      admin_password
    )

    # Initialize git repository for user's project
    execute_step("git_setup", "Setting up Git repository for your project...", fn ->
      setup_git_repository(project_name)
    end)
  end

  defp execute_step(id, label, task_fn) do
    block_id = {:setup_task, id}

    Owl.LiveScreen.add_block(block_id,
      state: :init,
      render: fn
        :init ->
          [
            Owl.Data.tag(label, :yellow),
            "\n",
            "Status: ",
            Owl.Data.tag("starting...", :cyan)
          ]

        :running ->
          [
            Owl.Data.tag(label, :yellow),
            "\n",
            "Status: ",
            Owl.Data.tag("running...", :cyan)
          ]

        :completed ->
          [
            Owl.Data.tag(label, :yellow),
            "\n",
            "Status: ",
            Owl.Data.tag("completed ✅", :green)
          ]

        {:error, reason} ->
          [
            Owl.Data.tag(label, :yellow),
            "\n",
            "Status: ",
            Owl.Data.tag("failed ❌ - #{reason}", :red)
          ]
      end
    )

    Owl.LiveScreen.update(block_id, :running)

    try do
      task_fn.()
      Owl.LiveScreen.update(block_id, :completed)
    rescue
      error ->
        Owl.LiveScreen.update(block_id, {:error, inspect(error)})
        raise error
    end
  end

  defp generate_waitlist do
    try do
      # Run the waitlist generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.waitlist", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Waitlist functionality generated successfully")
      else
        Logger.error("Waitlist generation failed: #{output}")
        raise "Waitlist generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating waitlist: #{inspect(error)}")
        raise error
    end
  end

  defp generate_analytics do
    try do
      # Run the analytics generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.analytics", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Analytics functionality generated successfully")
      else
        Logger.error("Analytics generation failed: #{output}")
        raise "Analytics generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating analytics: #{inspect(error)}")
        raise error
    end
  end

  defp generate_error_tracker do
    try do
      # Run the error tracker generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.error_tracker", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Error tracker functionality generated successfully")
      else
        Logger.error("Error tracker generation failed: #{output}")
        raise "Error tracker generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating error tracker: #{inspect(error)}")
        raise error
    end
  end

  defp generate_google_oauth do
    try do
      # Run the Google OAuth generator
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.oauth_google", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Google OAuth functionality generated successfully")
      else
        Logger.error("Google OAuth generation failed: #{output}")
        raise "Google OAuth generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating Google OAuth: #{inspect(error)}")
        raise error
    end
  end

  defp generate_github_oauth do
    try do
      # Run the GitHub OAuth generator
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.oauth_github", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("GitHub OAuth functionality generated successfully")
      else
        Logger.error("GitHub OAuth generation failed: #{output}")
        raise "GitHub OAuth generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating GitHub OAuth: #{inspect(error)}")
        raise error
    end
  end

  defp generate_llm do
    try do
      # Run the LLM generator
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.llm", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("LLM functionality generated successfully")
      else
        Logger.error("LLM generation failed: #{output}")
        raise "LLM generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating LLM: #{inspect(error)}")
        raise error
    end
  end

  defp install_oban do
    try do
      # Install Oban using Igniter
      {output, exit_code} =
        System.cmd(
          "mix",
          ["igniter.install", "oban", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Oban installed successfully")
      else
        Logger.error("Oban installation failed: #{output}")
        raise "Oban installation failed"
      end
    rescue
      error ->
        Logger.error("Error installing Oban: #{inspect(error)}")
        raise error
    end
  end

  defp install_oban_web do
    try do
      # Install Oban Web using Igniter
      {output, exit_code} =
        System.cmd(
          "mix",
          ["igniter.install", "oban_web", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Oban Web installed successfully")
      else
        Logger.error("Oban Web installation failed: #{output}")
        raise "Oban Web installation failed"
      end
    rescue
      error ->
        Logger.error("Error installing Oban Web: #{inspect(error)}")
        raise error
    end
  end

  defp generate_stripe do
    try do
      # Run the Stripe generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.stripe", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Stripe integration generated successfully")
      else
        Logger.error("Stripe generation failed: #{output}")
        raise "Stripe generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating Stripe integration: #{inspect(error)}")
        raise error
    end
  end

  defp generate_lemonsqueezy do
    try do
      # Run the LemonSqueezy generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.lemonsqueezy", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("LemonSqueezy integration generated successfully")
      else
        Logger.error("LemonSqueezy generation failed: #{output}")
        raise "LemonSqueezy generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating LemonSqueezy integration: #{inspect(error)}")
        raise error
    end
  end

  defp generate_organisations do
    try do
      # Run the organisations generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.organisations", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Organisations functionality generated successfully")
      else
        Logger.error("Organisations generation failed: #{output}")
        raise "Organisations generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating organisations: #{inspect(error)}")
        raise error
    end
  end

  defp generate_organisations_test do
    try do
      # Run the organisations test generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.organisations_test", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Organisations tests generated successfully")
      else
        Logger.error("Organisations test generation failed: #{output}")
        raise "Organisations test generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating organisations tests: #{inspect(error)}")
        raise error
    end
  end

  defp generate_blog do
    try do
      # Run the blog generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.blog", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Blog system generated successfully")
      else
        Logger.error("Blog generation failed: #{output}")
        raise "Blog generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating blog system: #{inspect(error)}")
        raise error
    end
  end

  defp generate_polar do
    try do
      # Run the Polar generator using the original project name
      # Use --yes flag to bypass confirmation prompts
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.polar", "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Polar.sh integration generated successfully")
      else
        Logger.error("Polar generation failed: #{output}")
        raise "Polar generation failed"
      end
    rescue
      error ->
        Logger.error("Error generating Polar.sh integration: #{inspect(error)}")
        raise error
    end
  end

  defp setup_admin_password(admin_password) do
    try do
      # Run the admin password generator
      {output, exit_code} =
        System.cmd(
          "mix",
          ["neptuner.gen.admin_password", "--password", admin_password, "--yes"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Admin password configured successfully")
      else
        Logger.error("Admin password setup failed: #{output}")
        raise "Admin password setup failed"
      end
    rescue
      error ->
        Logger.error("Error setting up admin password: #{inspect(error)}")
        raise error
    end
  end

  defp fetch_dependencies do
    try do
      # Fetch new dependencies that were added by generators
      {output, exit_code} =
        System.cmd(
          "mix",
          ["deps.get"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Dependencies fetched successfully")
      else
        Logger.error("Dependency fetch failed: #{output}")
        raise "Dependency fetch failed"
      end
    rescue
      error ->
        Logger.error("Error fetching dependencies: #{inspect(error)}")
        raise error
    end
  end

  defp rename_project(project_name) do
    try do
      # Use System.cmd to call the rename mix task
      {output, exit_code} =
        System.cmd(
          "mix",
          ["rename", "Neptuner", project_name],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Project renamed successfully")
        # Fix the CSS @source directive that doesn't get renamed by mix rename
        fix_css_source_directive(project_name)
        # Update app_name in config.exs
        update_app_name_in_config(project_name)
      else
        Logger.error("Project rename failed: #{output}")
        raise "Project rename failed"
      end
    rescue
      error ->
        Logger.error("Error running rename: #{inspect(error)}")
        raise error
    end
  end

  defp update_app_name_in_config(project_name) do
    config_file = "config/config.exs"
    # Convert PascalCase to Title Case, e.g., "MyAwesomeApp" -> "My Awesome App"
    new_app_name = String.replace(project_name, ~r/(?<!^)(?=[A-Z])/, " ")

    if File.exists?(config_file) do
      content = File.read!(config_file)

      updated_content =
        Regex.replace(~r/(app_name: *)".*?"/, content, "\\1\"#{new_app_name}\"")

      File.write!(config_file, updated_content)
      Logger.info("Updated app_name in config.exs to: \"#{new_app_name}\"")
    else
      Logger.warning("config/config.exs not found, skipping app_name update.")
    end
  end

  defp fix_css_source_directive(project_name) do
    css_file = "assets/css/app.css"
    project_name_snake = Macro.underscore(project_name)

    if File.exists?(css_file) do
      content = File.read!(css_file)

      updated_content =
        String.replace(
          content,
          "@source \"../../lib/neptuner_web\";",
          "@source \"../../lib/#{project_name_snake}_web\";"
        )

      File.write!(css_file, updated_content)
      Logger.info("Fixed CSS @source directive for #{project_name}")
    end
  end

  defp setup_database_after_rename do
    try do
      # Run ecto.setup to create the database with the new project name
      {output, exit_code} =
        System.cmd(
          "mix",
          ["ecto.setup"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Database setup completed with new project name")
      else
        Logger.error("Database setup failed: #{output}")
        raise "Database setup failed"
      end
    rescue
      error ->
        Logger.error("Error setting up database: #{inspect(error)}")
        raise error
    end
  end

  defp run_waitlist_seeds do
    try do
      # Run the waitlist seeds to enable the feature flag
      {output, exit_code} =
        System.cmd(
          "mix",
          ["run", "priv/repo/seeds/waitlist.exs"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Waitlist mode enabled successfully")
      else
        Logger.error("Waitlist seeds failed: #{output}")
        raise "Waitlist seeds failed"
      end
    rescue
      error ->
        Logger.error("Error running waitlist seeds: #{inspect(error)}")
        raise error
    end
  end

  defp rebuild_assets do
    try do
      # Rebuild assets with the new project name
      {output, exit_code} =
        System.cmd(
          "mix",
          ["assets.build"],
          stderr_to_stdout: true
        )

      if exit_code == 0 do
        Logger.info("Assets rebuilt successfully")
      else
        Logger.error("Asset rebuild failed: #{output}")
        raise "Asset rebuild failed"
      end
    rescue
      error ->
        Logger.error("Error rebuilding assets: #{inspect(error)}")
        raise error
    end
  end

  defp display_completion_message(
         project_name,
         wants_waitlist,
         wants_analytics,
         wants_error_tracker,
         wants_google_oauth,
         wants_github_oauth,
         wants_llm,
         wants_oban,
         wants_multi_tenancy,
         wants_blog,
         payment_processor,
         admin_password
       ) do
    # Ensure we start fresh
    IO.puts("")
    puts_green("🎉 Setup Complete!")
    puts_green("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    puts_cyan("#{project_name} project is ready!")

    puts_yellow("\n📋 What was set up:")
    puts_white("  • Dependencies installed")
    puts_white("  • Database created and migrated")

    if wants_waitlist do
      puts_white("  • Waitlist functionality enabled")
      puts_white("  • Waitlist mode activated")
    end

    if wants_analytics do
      puts_white("  • Analytics tracking enabled")
      puts_white("  • Analytics dashboard configured")
    end

    if wants_error_tracker do
      puts_white("  • Error tracking enabled")
      puts_white("  • Error dashboard configured")
    end

    puts_white("  • Project renamed to #{project_name}")
    puts_white("  • Admin password configured")
    puts_white("  • Assets compiled")
    puts_white("  • Git repository initialized for your project")
    puts_white("  • Template remote removed")

    if wants_waitlist do
      puts_green("\n🚀 Waitlist features available:")
      puts_light_black("  • Use `FunWithFlags.disable(:waitlist_mode)` to disable waitlist mode")

      puts_light_black(
        "  • Available components: <.simple_waitlist_form />, <.detailed_waitlist_form />, <.hero_waitlist_cta />"
      )
    end

    if wants_analytics do
      puts_green("\n📊 Analytics features available:")

      puts_light_black(
        "  • Visit http://localhost:4000/dev/analytics to view analytics dashboard"
      )

      puts_light_black("  • Page views, sessions, and metrics are tracked automatically")
      puts_light_black("  • Configure PHX_HOST environment variable for production")
    end

    if wants_error_tracker do
      puts_green("\n🔍 Error Tracking features available:")
      puts_light_black("  • Visit http://localhost:4000/dev/errors to view error dashboard")
      puts_light_black("  • Visit http://localhost:4000/admin/errors (requires admin auth)")
      puts_light_black("  • Automatic error capture for Phoenix, LiveView, and Oban")
      puts_light_black("  • Error grouping, stack traces, and context information")
      puts_light_black("  • Manual error reporting with ErrorTracker.report/2")
    end

    # Display OAuth configuration if enabled
    display_oauth_config(wants_google_oauth, wants_github_oauth)

    # Display feature configurations
    display_llm_config(wants_llm)
    display_oban_config(wants_oban)
    display_multi_tenancy_config(wants_multi_tenancy)
    display_blog_config(wants_blog)
    display_payment_config(payment_processor)
    
    # Display final configuration
    display_admin_config(admin_password)
    display_development_commands()
    
    puts_magenta("\n🎯 Happy coding!")
  end

  defp display_oauth_config(wants_google_oauth, wants_github_oauth) do
    if wants_google_oauth or wants_github_oauth do
      puts_green("\n🔐 OAuth Authentication configured:")

      if wants_google_oauth do
        puts_white("  • Google OAuth integration enabled")
        puts_light_black("  • Create OAuth app at https://console.developers.google.com/")
        puts_light_black("  • Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env")
      end

      if wants_github_oauth do
        puts_white("  • GitHub OAuth integration enabled")
        puts_light_black("  • Create OAuth app at https://github.com/settings/developers")
        puts_light_black("  • Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET in .env")
      end

      puts_light_black("  • Users can now sign in with social accounts on the login page")
      puts_light_black("  • OAuth callback URLs: /auth/google/callback, /auth/github/callback")
    end
  end

  defp display_llm_config(wants_llm) do
    if wants_llm do
      puts_green("\n🤖 LLM Integration configured:")
      puts_white("  • LangChain integration with OpenAI support")
      puts_white("  • AI.LLM module for text and JSON responses")
      puts_light_black("  • Get API key at https://platform.openai.com/api-keys")
      puts_light_black("  • Set OPENAI_API_KEY in your environment variables")
      puts_light_black("  • Example usage: Neptuner.AI.example_query()")
    end
  end

  defp display_oban_config(wants_oban) do
    if wants_oban do
      puts_green("\n⚙️ Oban Background Jobs configured:")
      puts_white("  • Oban job processing with PostgreSQL backend")
      puts_white("  • Oban Web UI for job monitoring and management")
      puts_light_black("  • Visit /oban to view the web interface")
      puts_light_black("  • Create jobs with: %{} |> MyApp.Worker.new() |> Oban.insert()")
      puts_light_black("  • Automatic job retries and dead letter queue")
    end
  end

  defp display_multi_tenancy_config(wants_multi_tenancy) do
    if wants_multi_tenancy do
      puts_green("\n🏢 Multi-Tenancy (Organisations) configured:")
      puts_white("  • Organisation management with role-based access control")
      puts_white("  • Three-tier authentication system (basic → org assignment → org requirement)")
      puts_white("  • Email-based invitation system with token validation")
      puts_white("  • Role hierarchy: owner, admin, member with different permissions")
      puts_light_black("  • Visit /organisations/new to create your first organisation")
      puts_light_black("  • Invite users via /organisations/manage")
      puts_light_black("  • Comprehensive test suite included")
    end
  end

  defp display_blog_config(wants_blog) do
    if wants_blog do
      puts_green("\n📝 Blog System configured:")
      puts_white("  • Complete blog system with admin interface")
      puts_white("  • Markdown content support with Earmark")
      puts_white("  • SEO optimization with meta tags and structured data")
      puts_white("  • Backpex-powered admin interface for blog management")
      puts_light_black("  • Visit /blog to view the public blog")
      puts_light_black("  • Visit /admin/posts to manage blog posts")
      puts_light_black("  • Auto-generated slugs, excerpts, and reading time")
      puts_light_black("  • Publishing workflow with draft/published states")
    end
  end

  defp display_payment_config(payment_processor) do
    case payment_processor do
      "stripe" ->
        puts_green("\n💳 Stripe Payment Processing configured:")
        puts_white("  • Stripe payment integration with webhooks")
        puts_white("  • Purchase tracking and management")
        puts_light_black("  • Get API keys at https://dashboard.stripe.com/apikeys")
        puts_light_black("  • Set STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET in .env")
        puts_light_black("  • Webhook endpoint: /api/stripe/webhooks")
        puts_light_black("  • Example: Neptuner.Purchases.list_purchases()")

      "lemonsqueezy" ->
        puts_green("\n🍋 LemonSqueezy Payment Processing configured:")
        puts_white("  • LemonSqueezy payment integration with webhooks")
        puts_white("  • Purchase and subscription tracking")
        puts_light_black("  • Get API keys at https://app.lemonsqueezy.com/settings/api")
        puts_light_black("  • Set LEMONSQUEEZY_API_KEY and LEMONSQUEEZY_WEBHOOK_SECRET in .env")
        puts_light_black("  • Webhook endpoint: /webhook/lemonsqueezy")
        puts_light_black("  • Example: Neptuner.Purchases.list_purchases()")

      "polar" ->
        puts_green("\n❄️ Polar.sh Payment Processing configured:")
        puts_white("  • Polar.sh payment integration with webhooks")
        puts_white("  • Purchase, checkout, and subscription tracking")
        puts_light_black("  • Get API keys at https://polar.sh/settings")
        puts_light_black("  • Set POLAR_ACCESS_TOKEN and POLAR_WEBHOOK_SECRET in .env")
        puts_light_black("  • Webhook endpoint: /api/webhooks/polar")
        puts_light_black("  • Example: Neptuner.Purchases.list_purchases()")

      "none" ->
        :ok
    end
  end

  defp display_admin_config(admin_password) do
    puts_green("\n🔐 Admin Panel Access:")
    puts_white("  • Admin password: #{admin_password}")
    puts_white("  • Username: admin")
    puts_white("  • Feature flags UI: http://localhost:4000/feature-flags")
    puts_light_black("  • Password stored in .env file for security")
  end

  defp display_development_commands do
    puts_yellow("\n🔧 Development commands:")
    puts_white("  • `mix phx.server` - Start development server")
    puts_white("  • `iex -S mix phx.server` - Start with interactive shell")
    puts_white("  • Visit http://localhost:4000 to see your application")
  end

  defp save_setup_info_to_file(
         project_name,
         wants_waitlist,
         wants_analytics,
         wants_error_tracker,
         wants_google_oauth,
         wants_github_oauth,
         wants_llm,
         wants_oban,
         wants_multi_tenancy,
         wants_blog,
         payment_processor,
         admin_password
       ) do
    content =
      generate_setup_info_content(
        project_name,
        wants_waitlist,
        wants_analytics,
        wants_error_tracker,
        wants_google_oauth,
        wants_github_oauth,
        wants_llm,
        wants_oban,
        wants_multi_tenancy,
        wants_blog,
        payment_processor,
        admin_password
      )

    filename = "SETUP_INFO.md"
    File.write!(filename, content)
    puts_cyan("\n💾 Setup information saved to #{filename}")
  end

  defp generate_setup_info_content(
         project_name,
         wants_waitlist,
         wants_analytics,
         wants_error_tracker,
         wants_google_oauth,
         wants_github_oauth,
         wants_llm,
         wants_oban,
         wants_multi_tenancy,
         wants_blog,
         payment_processor,
         admin_password
       ) do
    """
    # #{project_name} Setup Information

    This file contains important setup information generated during the SaaS Template setup process.

    ## Setup Summary

    - **Project Name**: #{project_name}
    - **Waitlist Mode**: #{if wants_waitlist, do: "Yes", else: "No"}
    - **Analytics**: #{if wants_analytics, do: "Yes", else: "No"}
    - **Error Tracking**: #{if wants_error_tracker, do: "Yes", else: "No"}
    - **Google OAuth**: #{if wants_google_oauth, do: "Yes", else: "No"}
    - **GitHub OAuth**: #{if wants_github_oauth, do: "Yes", else: "No"}
    - **LLM Integration**: #{if wants_llm, do: "Yes", else: "No"}
    - **Oban Background Jobs**: #{if wants_oban, do: "Yes", else: "No"}
    - **Multi-tenancy**: #{if wants_multi_tenancy, do: "Yes", else: "No"}
    - **Blog System**: #{if wants_blog, do: "Yes", else: "No"}
    - **Payment Processor**: #{payment_processor}
    - **Admin Password**: #{if String.length(admin_password) > 0, do: "Custom", else: "Generated"}

    ## What was set up

    - Dependencies installed
    - Database created and migrated
    #{if wants_waitlist, do: "- Waitlist functionality enabled\n- Waitlist mode activated", else: ""}
    #{if wants_analytics, do: "- Analytics tracking enabled\n- Analytics dashboard configured", else: ""}
    #{if wants_error_tracker, do: "- Error tracking enabled\n- Error dashboard configured", else: ""}
    - Project renamed to #{project_name}
    - Admin password configured
    - Assets compiled
    - Git repository initialized for your project
    - Template remote removed

    #{if wants_waitlist, do: waitlist_features_content(), else: ""}
    #{if wants_analytics, do: analytics_features_content(), else: ""}
    #{if wants_error_tracker, do: error_tracking_features_content(), else: ""}
    #{if wants_google_oauth or wants_github_oauth, do: oauth_features_content(wants_google_oauth, wants_github_oauth), else: ""}
    #{if wants_llm, do: llm_features_content(), else: ""}
    #{if wants_oban, do: oban_features_content(), else: ""}
    #{if wants_multi_tenancy, do: multi_tenancy_features_content(), else: ""}
    #{if wants_blog, do: blog_features_content(), else: ""}
    #{payment_processor_content(payment_processor)}

    ## Admin Panel Access

    - **Admin password**: REDACTED
    - **Username**: `admin`
    - **Feature flags UI**: http://localhost:4000/feature-flags
    - Password stored in .env file for security

    ## Development Commands

    - `mix phx.server` - Start development server
    - `iex -S mix phx.server` - Start with interactive shell
    - Visit http://localhost:4000 to see your application

    ---
    *Generated on #{DateTime.utc_now() |> DateTime.to_string()}*
    """
  end

  defp waitlist_features_content do
    """
    ## Waitlist Features

    - Use `FunWithFlags.disable(:waitlist_mode)` to disable waitlist mode
    - Available components: `<.simple_waitlist_form />`, `<.detailed_waitlist_form />`, `<.hero_waitlist_cta />`
    """
  end

  defp analytics_features_content do
    """
    ## Analytics Features

    - Visit http://localhost:4000/dev/analytics to view analytics dashboard
    - Page views, sessions, and metrics are tracked automatically
    - Configure PHX_HOST environment variable for production
    """
  end

  defp error_tracking_features_content do
    """
    ## Error Tracking Features

    - Visit http://localhost:4000/dev/errors to view error dashboard
    - Visit http://localhost:4000/admin/errors (requires admin auth)
    - Automatic error capture for Phoenix, LiveView, and Oban
    - Error grouping, stack traces, and context information
    - Manual error reporting with `ErrorTracker.report/2`
    """
  end

  defp oauth_features_content(wants_google_oauth, wants_github_oauth) do
    google_content =
      if wants_google_oauth do
        """
        - Google OAuth integration enabled
        - Create OAuth app at https://console.developers.google.com/
        - Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env
        """
      else
        ""
      end

    github_content =
      if wants_github_oauth do
        """
        - GitHub OAuth integration enabled
        - Create OAuth app at https://github.com/settings/developers
        - Set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET in .env
        """
      else
        ""
      end

    """
    ## OAuth Authentication

    #{google_content}#{github_content}
    - Users can now sign in with social accounts on the login page
    - OAuth callback URLs: /auth/google/callback, /auth/github/callback
    """
  end

  defp llm_features_content do
    """
    ## LLM Integration

    - LangChain integration with OpenAI support
    - AI.LLM module for text and JSON responses
    - Get API key at https://platform.openai.com/api-keys
    - Set OPENAI_API_KEY in your environment variables
    - Example usage: `Neptuner.AI.example_query()`
    """
  end

  defp oban_features_content do
    """
    ## Oban Background Jobs

    - Oban job processing with PostgreSQL backend
    - Oban Web UI for job monitoring and management
    - Visit /oban to view the web interface
    - Create jobs with: `%{} |> MyApp.Worker.new() |> Oban.insert()`
    - Automatic job retries and dead letter queue
    """
  end

  defp multi_tenancy_features_content do
    """
    ## Multi-Tenancy (Organisations)

    - Organisation management with role-based access control
    - Three-tier authentication system (basic → org assignment → org requirement)
    - Email-based invitation system with token validation
    - Role hierarchy: owner, admin, member with different permissions
    - Visit /organisations/new to create your first organisation
    - Invite users via /organisations/manage
    - Comprehensive test suite included
    """
  end

  defp blog_features_content do
    """
    ## Blog System

    - Complete blog system with admin interface
    - Markdown content support with Earmark
    - SEO optimization with meta tags and structured data
    - Backpex-powered admin interface for blog management
    - Visit /blog to view the public blog
    - Visit /admin/posts to manage blog posts
    - Auto-generated slugs, excerpts, and reading time
    - Publishing workflow with draft/published states
    """
  end

  defp payment_processor_content(payment_processor) do
    case payment_processor do
      "stripe" ->
        """
        ## Stripe Payment Processing

        - Stripe payment integration with webhooks
        - Purchase tracking and management
        - Get API keys at https://dashboard.stripe.com/apikeys
        - Set STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET in .env
        - Webhook endpoint: /api/stripe/webhooks
        - Example: `Neptuner.Purchases.list_purchases()`
        """

      "lemonsqueezy" ->
        """
        ## LemonSqueezy Payment Processing

        - LemonSqueezy payment integration with webhooks
        - Purchase and subscription tracking
        - Get API keys at https://app.lemonsqueezy.com/settings/api
        - Set LEMONSQUEEZY_API_KEY and LEMONSQUEEZY_WEBHOOK_SECRET in .env
        - Webhook endpoint: /webhook/lemonsqueezy
        - Example: `Neptuner.Purchases.list_purchases()`
        """

      "polar" ->
        """
        ## Polar.sh Payment Processing

        - Polar.sh payment integration with webhooks
        - Purchase, checkout, and subscription tracking
        - Get API keys at https://polar.sh/settings
        - Set POLAR_ACCESS_TOKEN and POLAR_WEBHOOK_SECRET in .env
        - Webhook endpoint: /api/webhooks/polar
        - Example: `Neptuner.Purchases.list_purchases()`
        """

      "none" ->
        ""
    end
  end

  defp setup_git_repository(project_name) do
    try do
      # Remove the origin remote to disconnect from template repository
      {_output, _exit_code} =
        System.cmd(
          "git",
          ["remote", "remove", "origin"],
          stderr_to_stdout: true
        )

      # Stage all changes
      {stage_output, stage_exit_code} =
        System.cmd(
          "git",
          ["add", "."],
          stderr_to_stdout: true
        )

      if stage_exit_code != 0 do
        Logger.error("Git staging failed: #{stage_output}")
        raise "Git staging failed"
      end

      # Amend the commit with a new message for the user's project
      commit_message = """
      Initial #{project_name} setup

      This commit represents the initial setup of #{project_name} based on the SaaS Template.
      All selected features have been configured and the project has been customized.

      Ready to start building your SaaS application!
      """

      {commit_output, commit_exit_code} =
        System.cmd(
          "git",
          ["commit", "--amend", "-m", commit_message],
          stderr_to_stdout: true
        )

      if commit_exit_code == 0 do
        Logger.info("Git repository initialized for #{project_name}")
        Logger.info("Template origin remote removed")
        Logger.info("Commit amended with project setup")
      else
        Logger.error("Git commit amend failed: #{commit_output}")
        raise "Git commit amend failed"
      end
    rescue
      error ->
        Logger.error("Error setting up git repository: #{inspect(error)}")
        raise error
    end
  end
end
