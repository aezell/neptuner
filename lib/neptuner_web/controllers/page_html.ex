defmodule NeptunerWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use NeptunerWeb, :html

  embed_templates "page_html/*"
  embed_templates "../components/marketing/*"
end
