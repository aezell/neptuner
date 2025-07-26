# LLM Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The LLM generator integrates Large Language Model (LLM) functionality into your SaaS template using the LangChain library. It provides a streamlined interface for interacting with OpenAI's GPT models, supporting both text and JSON responses through a simple, chainable API.

## Installation

Run the generator from your project root:

```bash
mix neptuner.gen.llm
```

To skip the completion notice and run silently:

```bash
mix neptuner.gen.llm --yes
```

## What It Does

The generator performs the following modifications to your project:

### Dependencies Added
- **langchain (0.3.3)**: Added to `mix.exs` for LLM integration and OpenAI interaction

### Configuration Added
- **LangChain configuration**: Added to `config/config.exs` with OpenAI API key from environment variables

### Files Created
- **`lib/neptuner/ai.ex`**: Main AI context module with example functions
- **`lib/neptuner/ai/llm.ex`**: Core LLM interface module with chain management

### Files Updated
- **`.env.example`**: Added `OPENAI_API_KEY` environment variable template

## Configuration

### Environment Variables

Set your OpenAI API key in your environment:

```bash
export OPENAI_API_KEY=your-actual-api-key-here
```

Or add it to your `.env` file:

```env
OPENAI_API_KEY=your-actual-api-key-here
```

### LangChain Configuration

The generator automatically adds this configuration to `config/config.exs`:

```elixir
config :langchain, openai_key: System.fetch_env!("OPENAI_API_KEY")
```

## Usage

### Basic Text Queries

```elixir
# Create a simple text chain
chain = Neptuner.AI.LLM.create_chain("You are a helpful assistant.")
{:ok, response} = Neptuner.AI.LLM.query_text(chain, "What is the capital of France?")
{:ok, parsed} = Neptuner.AI.LLM.parse_output(response)
# Returns: {:ok, "The capital of France is Paris."}
```

### JSON Response Queries

```elixir
# Create a JSON response chain
json_chain = Neptuner.AI.LLM.create_chain("You are a helpful assistant. Respond in JSON format.", json_response: true)
{:ok, response} = Neptuner.AI.LLM.query_json(json_chain, "What is the capital of France?")
{:ok, parsed} = Neptuner.AI.LLM.parse_output(response)
# Returns: {:ok, %{"capital" => "Paris"}}
```

### Custom Model Configuration

```elixir
# Use a different model
chain = Neptuner.AI.LLM.create_chain("You are a helpful assistant.", model: "gpt-3.5-turbo")
```

### Available Chain Options

- `model`: Specify the OpenAI model (default: "gpt-4o")
- `json_response`: Enable JSON response mode (default: false)

## Examples

### Simple Question Answering

```elixir
# Using the convenience functions from Neptuner.AI
{:ok, response} = Neptuner.AI.example_query()
# Returns a simple text response
```

### JSON Data Extraction

```elixir
# Using the JSON convenience function
{:ok, parsed_data} = Neptuner.AI.example_json_query()
# Returns parsed JSON data as a map
```

### Custom Implementation

```elixir
defmodule MyApp.Assistant do
  alias Neptuner.AI.LLM

  def analyze_sentiment(text) do
    LLM.create_chain("You are a sentiment analysis expert. Respond in JSON format.", json_response: true)
    |> LLM.query_json("Analyze the sentiment of this text: #{text}")
    |> LLM.parse_output()
  end

  def summarize_text(text) do
    LLM.create_chain("You are a skilled summarizer.")
    |> LLM.query_text("Summarize this text in 2-3 sentences: #{text}")
    |> LLM.parse_output()
  end
end
```

## API Reference

### Neptuner.AI.LLM

#### `create_chain/2`

Creates a new LLM chain with system message and options.

**Parameters:**
- `system_message` (string): Instructions for the AI
- `options` (keyword list): Configuration options
  - `:model` - OpenAI model to use (default: "gpt-4o")
  - `:json_response` - Enable JSON parsing (default: false)

#### `query_text/2`

Queries the LLM and returns text response.

**Parameters:**
- `chain`: LLM chain created with `create_chain/2`
- `message` (string): User message to send

#### `query_json/2`

Queries the LLM and returns JSON response with automatic parsing.

**Parameters:**
- `chain`: LLM chain with `json_response: true`
- `message` (string): User message to send

#### `parse_output/1`

Parses the LLM response into usable format.

**Parameters:**
- `response`: Response from `query_text/2` or `query_json/2`

**Returns:**
- `{:ok, string}` for text responses
- `{:ok, map}` for JSON responses

## Next Steps

1. **Set up OpenAI API Key**:
   - Visit [OpenAI API Keys](https://platform.openai.com/api-keys)
   - Create a new API key
   - Set `OPENAI_API_KEY` in your environment variables

2. **Install Dependencies**:
   ```bash
   mix deps.get
   ```

3. **Test the Integration**:
   ```elixir
   # In IEx
   iex -S mix
   {:ok, response} = Neptuner.AI.example_query()
   ```

4. **Explore Advanced Features**:
   - Review [LangChain documentation](https://hexdocs.pm/langchain/LangChain.html)
   - Implement custom chains for your specific use cases
   - Add error handling and retry logic for production use

5. **Production Considerations**:
   - Implement rate limiting for API calls
   - Add proper error handling and logging
   - Consider caching for frequently asked questions
   - Monitor API usage and costs

The LLM integration provides a solid foundation for adding AI capabilities to your SaaS application, from simple chatbots to complex data analysis and content generation features.