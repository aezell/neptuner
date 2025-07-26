defmodule NeptunerWeb.BlogHTML do
  use NeptunerWeb, :html

  embed_templates "blog_html/*"
  embed_templates "../components/marketing/*"
end
