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
