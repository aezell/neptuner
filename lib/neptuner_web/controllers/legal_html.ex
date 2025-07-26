defmodule NeptunerWeb.LegalHTML do
  use NeptunerWeb, :html

  embed_templates "legal_html/*"
  embed_templates "../components/marketing/*"
end
