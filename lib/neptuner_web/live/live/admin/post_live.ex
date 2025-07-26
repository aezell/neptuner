defmodule NeptunerWeb.Live.Admin.PostLive do
  use Backpex.LiveResource,
    layout: {NeptunerWeb.Layouts, :blog},
    adapter_config: [
      schema: Neptuner.Blog.Post,
      repo: Neptuner.Repo,
      update_changeset: &Neptuner.Blog.Post.changeset/3,
      create_changeset: &Neptuner.Blog.Post.changeset/3
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Post"

  @impl Backpex.LiveResource
  def plural_name, do: "Posts"

  @impl Backpex.LiveResource
  def fields do
    [
      title: %{
        module: Backpex.Fields.Text,
        label: "Title",
        searchable: true
      },
      slug: %{
        module: Backpex.Fields.Text,
        label: "Slug",
        searchable: true,
        readonly: true
      },
      content: %{
        module: Backpex.Fields.Textarea,
        label: "Content",
        searchable: true,
        readonly: false
      },
      published_at: %{
        module: Backpex.Fields.DateTime,
        label: "Published At"
      },
      author_name: %{
        module: Backpex.Fields.Text,
        label: "Author",
        searchable: true
      }
    ]
  end
end
