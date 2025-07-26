defmodule Mix.Tasks.Neptuner.Gen.Llm do
  @moduledoc """
  Installs LLM functionality for the SaaS template using Igniter.

  This task:
  - Adds LangChain dependency to mix.exs
  - Adds LangChain configuration to config.exs
  - Creates AI.LLM module for OpenAI integration
  - Updates .env.example with OpenAI API key

      $ mix neptuner.gen.llm

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      |> add_langchain_dependency()
      |> add_langchain_config()
      |> create_llm_module()
      |> create_ai_context_module()
      |> update_env_example()

    if opts[:yes] do
      igniter
    else
      print_completion_notice(igniter)
    end
  end

  defp add_langchain_dependency(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:langchain,") do
        # Dependency already exists
        source
      else
        # Add langchain dependency after timex
        updated_content =
          String.replace(
            content,
            ~r/(\{:timex, "~> 3\.7\.13"\})/,
            "\\1,\n      # AI\n      {:langchain, \"0.3.3\"}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_langchain_config(igniter) do
    config_content = """
    config :langchain, openai_key: System.get_env("OPENAI_API_KEY")
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :langchain") do
        # Config already exists
        source
      else
        # Add LangChain config before the import_config line
        updated_content =
          String.replace(
            content,
            ~r/(# Import environment specific config\. This must remain at the bottom)/,
            "\n#{config_content}\n\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_ai_context_module(igniter) do
    ai_content = """
    defmodule Neptuner.AI do
      alias Neptuner.AI.LLM

      def example_query do
        LLM.create_chain("You are a helpful assistant.")
        |> LLM.query_text("What is the capital of France?")
        |> LLM.parse_output()
      end

      def example_json_query do
        LLM.create_chain("You are a helpful assistant. Respond in JSON format.", json_response: true)
        |> LLM.query_json("What is the capital of France?")
        |> LLM.parse_output()
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/ai.ex",
      ai_content
    )
  end

  defp create_llm_module(igniter) do
    llm_content = """
    defmodule Neptuner.AI.LLM do
      alias LangChain.Chains.LLMChain
      alias LangChain.Message
      alias LangChain.MessageProcessors.JsonProcessor
      alias LangChain.ChatModels.ChatOpenAI

      @moduledoc \"\"\"
      This module provides a simple interface for interacting with the LLMs using LangChain.

      Refer to the [LangChain documentation](https://hexdocs.pm/langchain/LangChain.html) for more information.
      Other models can be used - ensure your API key is set in the environment variables and config/config.exs.

      ## Examples

      ```elixir
      chain = Neptuner.AI.LLM.create_chain("You are a helpful assistant.")
      Neptuner.AI.LLM.query_text(chain, "What is the capital of France?")
      {:ok, "The capital of France is Paris."}

      json_chain = Neptuner.AI.LLM.create_chain("You are a helpful assistant.", json_response: true)
      Neptuner.AI.LLM.query_json(json_chain, "What is the capital of France?")
      {:ok, %{"capital" => "Paris"}}
      ```
      \"\"\"

      @doc \"\"\"
      Create a new LLM chain with the given system message.
      \"\"\"
      def create_chain(system_message, options \\\\ []) do
        model =
          ChatOpenAI.new!(%{
            temperature: 0,
            stream: false,
            model: Keyword.get(options, :model, "gpt-4o"),
            json_response: Keyword.get(options, :json_response, false)
          })

        %{llm: model, verbose: false, stream: false}
        |> LLMChain.new!()
        |> LLMChain.add_message(Message.new_system!(system_message))
      end

      @doc \"\"\"
      Query the LLM and return the response as a text string.
      \"\"\"
      def query_text(chain, message) do
        chain
        |> LLMChain.add_message(Message.new_user!(message))
        |> LLMChain.run()
      end

      @doc \"\"\"
      Query the LLM and return the response as a JSON string.

      Json responses must have:
      * A system message that instructs the LLM to respond in JSON format.
      * A configured JSON processor that will parse the response.
      * Some models will add a ```json prefix and suffix to the response - you must account for this by configuring the JSON processor to ignore the prefix and suffix.

      More info can be found in the [LangChain documentation](https://hexdocs.pm/langchain/LangChain.MessageProcessors.JsonProcessor.html#module-jsonprocessor-vs-tool-usage).

      The response is expected to be a JSON string, so the JSON processor is used to parse the response.

      ## Examples

      ```elixir
      \"\"\"
      def query_json(chain, message) do
        chain
        |> LLMChain.add_message(Message.new_user!(message))
        |> LLMChain.message_processors([JsonProcessor.new!()])
        |> LLMChain.run()
      end

      @doc \"\"\"
      Parse the last message of the LLM chain output.

      If the response is a JSON string, it is parsed into a map.
      Otherwise, the response is returned as a string.
      \"\"\"
      def parse_output({:ok, %LangChain.Chains.LLMChain{last_message: last_message}}) do
        processed_content = last_message.processed_content

        if is_map(processed_content) do
          {:ok, processed_content}
        else
          {:ok, last_message.content}
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "lib/neptuner/ai/llm.ex",
      llm_content
    )
  end

  defp update_env_example(igniter) do
    Igniter.update_file(igniter, ".env.example", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "OPENAI_API_KEY") do
        # OpenAI API key already exists
        source
      else
        # Add OpenAI API key at the top
        openai_env_var = "OPENAI_API_KEY=your-open-ai-key"

        updated_content =
          if String.trim(content) == "" do
            openai_env_var
          else
            openai_env_var <> "\n" <> content
          end

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## LLM Integration Complete! 🤖

    LangChain has been successfully integrated into your SaaS template for LLM functionality. Here's what was configured:

    ### Dependencies Added:
    - langchain (0.3.3) for LLM integration and OpenAI interaction

    ### Configuration Added:
    - LangChain configuration in config/config.exs
    - OpenAI API key configuration from environment variables

    ### Code Created:
    - Neptuner.AI.LLM module for LLM interactions
    - Neptuner.AI context module with example functions
    - Support for both text and JSON responses
    - Chain management for conversational AI

    ### Files Created:
    - lib/neptuner/ai.ex - AI context module with examples
    - lib/neptuner/ai/llm.ex - Main LLM interface module

    ### Files Updated:
    - .env.example with OPENAI_API_KEY environment variable

    ### Next Steps:
    1. Set up OpenAI API key:
       - Visit https://platform.openai.com/api-keys
       - Create a new API key
       - Set OPENAI_API_KEY in your environment variables

    2. Usage examples:
       ```elixir
       # Create a simple text chain
       chain = Neptuner.AI.LLM.create_chain("You are a helpful assistant.")
       {:ok, response} = Neptuner.AI.LLM.query_text(chain, "Hello!")

       # Create a JSON response chain
       json_chain = Neptuner.AI.LLM.create_chain("Respond in JSON format.", json_response: true)
       {:ok, parsed} = Neptuner.AI.LLM.query_json(json_chain, "Tell me about Paris")
       ```

    3. Available models:
       - Default: gpt-4o
       - Customizable via options: `create_chain(message, model: "gpt-3.5-turbo")`

    ### LLM Features:
    - Text-based AI conversations
    - JSON response parsing
    - Configurable models and parameters
    - Built on LangChain for extensibility

    🎉 Your app now supports LLM functionality with OpenAI!
    """

    Igniter.add_notice(igniter, completion_message)
  end
end
