defmodule Neptuner.AI.LLM do
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias LangChain.MessageProcessors.JsonProcessor
  alias LangChain.ChatModels.ChatOpenAI

  @moduledoc """
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
  """

  @doc """
  Create a new LLM chain with the given system message.
  """
  def create_chain(system_message, options \\ []) do
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

  @doc """
  Query the LLM and return the response as a text string.
  """
  def query_text(chain, message) do
    chain
    |> LLMChain.add_message(Message.new_user!(message))
    |> LLMChain.run()
  end

  @doc """
  Query the LLM and return the response as a JSON string.

  Json responses must have:
  * A system message that instructs the LLM to respond in JSON format.
  * A configured JSON processor that will parse the response.
  * Some models will add a ```json prefix and suffix to the response - you must account for this by configuring the JSON processor to ignore the prefix and suffix.

  More info can be found in the [LangChain documentation](https://hexdocs.pm/langchain/LangChain.MessageProcessors.JsonProcessor.html#module-jsonprocessor-vs-tool-usage).

  The response is expected to be a JSON string, so the JSON processor is used to parse the response.

  ## Examples

  ```elixir
  """
  def query_json(chain, message) do
    chain
    |> LLMChain.add_message(Message.new_user!(message))
    |> LLMChain.message_processors([JsonProcessor.new!()])
    |> LLMChain.run()
  end

  @doc """
  Parse the last message of the LLM chain output.

  If the response is a JSON string, it is parsed into a map.
  Otherwise, the response is returned as a string.
  """
  def parse_output({:ok, %LangChain.Chains.LLMChain{last_message: last_message}}) do
    processed_content = last_message.processed_content

    if is_map(processed_content) do
      {:ok, processed_content}
    else
      {:ok, last_message.content}
    end
  end
end
