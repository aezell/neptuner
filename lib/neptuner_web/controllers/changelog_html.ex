defmodule NeptunerWeb.ChangelogHTML do
  use NeptunerWeb, :html

  embed_templates "changelog_html/*"
  embed_templates "../components/marketing/*"
end
