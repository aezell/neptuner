defmodule Neptuner.Blog do
  import Ecto.Query, warn: false
  alias Neptuner.Repo
  alias Neptuner.Blog.Post

  def list_published_posts do
    from(p in Post,
      where: not is_nil(p.published_at),
      order_by: [desc: p.published_at]
    )
    |> Repo.all()
  end

  def get_post_by_slug(slug) do
    from(p in Post,
      where: p.slug == ^slug and not is_nil(p.published_at)
    )
    |> Repo.one()
  end
end
