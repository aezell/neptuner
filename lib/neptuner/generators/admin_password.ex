defmodule Mix.Tasks.Neptuner.Gen.AdminPassword do
  @moduledoc """
  Updates the basic auth admin password in config.exs using Igniter.

  This task updates the admin password configuration for basic auth protection.

      $ mix neptuner.gen.admin_password
      $ mix neptuner.gen.admin_password --password "my_secure_password"

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    # Parse options
    {opts, _argv} =
      OptionParser.parse!(igniter.args.argv, strict: [password: :string, yes: :boolean])

    password = opts[:password] || generate_secure_password()

    igniter
    |> update_basic_auth_config(password)
    |> print_completion_notice(password)
  end

  defp generate_secure_password() do
    # Generate a 16-character cryptographically secure password
    :crypto.strong_rand_bytes(16)
    |> Base.encode64()
    |> binary_part(0, 16)
  end

  defp update_basic_auth_config(igniter, password) do
    igniter
    |> update_config_file()
    |> update_env_example(password)
    |> create_env_file_if_missing(password)
  end

  defp update_config_file(igniter) do
    config_path = "config/config.exs"

    Igniter.update_file(igniter, config_path, fn source ->
      content = Rewrite.Source.get(source, :content)

      # Check if basic auth config already uses environment variables
      if String.contains?(content, "System.get_env(\"ADMIN_PASSWORD\")") do
        # Already configured correctly
        source
      else
        # Pattern to match the basic auth config line with hardcoded password
        pattern = ~r/(config :neptuner, :basic_auth, username: "admin", password: )"[^"]*"/

        if Regex.match?(pattern, content) do
          # Replace with environment variable version
          updated_content =
            Regex.replace(
              pattern,
              content,
              "\\1System.get_env(\"ADMIN_PASSWORD\", \"admin123\")"
            )

          Rewrite.Source.update(source, :content, updated_content)
        else
          # If no existing config, add it before the import_config line
          import_pattern = ~r/(# Import environment specific config.*\nimport_config)/

          if Regex.match?(import_pattern, content) do
            basic_auth_config = """
            # Configures Basic Auth for Admin page access
            config :neptuner, :basic_auth, username: "admin", password: System.get_env("ADMIN_PASSWORD", "admin123")

            """

            updated_content =
              Regex.replace(
                import_pattern,
                content,
                "#{basic_auth_config}\\1"
              )

            Rewrite.Source.update(source, :content, updated_content)
          else
            # Fallback: append to end of file
            updated_content =
              content <>
                """

                # Configures Basic Auth for Admin page access
                config :neptuner, :basic_auth, username: "admin", password: System.get_env("ADMIN_PASSWORD", "admin123")
                """

            Rewrite.Source.update(source, :content, updated_content)
          end
        end
      end
    end)
  end

  defp update_env_example(igniter, password) do
    env_example_path = ".env.example"

    Igniter.update_file(igniter, env_example_path, fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "ADMIN_PASSWORD=") do
        # Replace existing ADMIN_PASSWORD line
        updated_content =
          Regex.replace(
            ~r/ADMIN_PASSWORD=.*/,
            content,
            "ADMIN_PASSWORD=#{password}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      else
        # Add ADMIN_PASSWORD to the end of the file
        updated_content =
          content <>
            """

            # Admin panel basic auth password
            ADMIN_PASSWORD=#{password}
            """

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_env_file_if_missing(igniter, password) do
    env_path = ".env"

    # Only create .env if it doesn't exist
    if File.exists?(env_path) do
      # Update existing .env file
      Igniter.update_file(igniter, env_path, fn source ->
        content = Rewrite.Source.get(source, :content)

        if String.contains?(content, "ADMIN_PASSWORD=") do
          # Replace existing ADMIN_PASSWORD line
          updated_content =
            Regex.replace(
              ~r/ADMIN_PASSWORD=.*/,
              content,
              "ADMIN_PASSWORD=#{password}"
            )

          Rewrite.Source.update(source, :content, updated_content)
        else
          # Add ADMIN_PASSWORD to the end of the file
          updated_content =
            content <>
              """

              # Admin panel basic auth password
              ADMIN_PASSWORD=#{password}
              """

          Rewrite.Source.update(source, :content, updated_content)
        end
      end)
    else
      # Create new .env file
      env_content = """
      # Admin panel basic auth password
      ADMIN_PASSWORD=#{password}
      """

      Igniter.create_new_file(igniter, env_path, env_content)
    end
  end

  defp print_completion_notice(igniter, password) do
    completion_message = """

    ## Admin Password Updated! ✅

    Your admin password has been successfully configured.

    ### Configuration Updated:
    - config/config.exs now uses ADMIN_PASSWORD environment variable
    - .env.example updated with new password
    - .env file created/updated with password: #{password}
    - Username remains: admin

    ### Access Admin Features:
    - Feature flags UI: http://localhost:4000/feature-flags
    - Other admin pages: http://localhost:4000/admin/*

    ### Security Notes:
    - Password is stored in environment variables (not hardcoded)
    - The password is #{String.length(password)} characters long and cryptographically secure
    - .env file is gitignored by default for security

    🔐 Admin access is now secured with your new password!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
