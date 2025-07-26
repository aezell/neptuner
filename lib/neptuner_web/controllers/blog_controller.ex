defmodule NeptunerWeb.BlogController do
  use NeptunerWeb, :controller

  alias Neptuner.Blog

  def index(conn, _params) do
    posts = Blog.list_published_posts()

    conn
    |> put_meta_tags(%{
      title: "Blog - #{Application.get_env(:neptuner, :app_name)}",
      description: "Latest articles and insights from our team",
      url: url(~p"/blog"),
      type: "website"
    })
    |> render(:index, posts: posts)
  end

  def show(conn, %{"slug" => slug}) do
    case Blog.get_post_by_slug(slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(NeptunerWeb.ErrorHTML)
        |> render(:"404")

      post ->
        conn
        |> put_meta_tags(%{
          title: "#{post.title} - #{Application.get_env(:neptuner, :app_name)}",
          description: post.meta_description || post.excerpt,
          url: url(~p"/blog/#{post.slug}"),
          type: "article",
          image: post.featured_image_url
        })
        |> render(:show, post: post)
    end
  end

  defp put_meta_tags(conn, meta) do
    conn
    |> assign(:page_title, meta.title)
    |> assign(:meta_description, meta.description)
    |> assign(:meta_url, meta.url)
    |> assign(:meta_type, meta.type)
    |> assign(:meta_image, Map.get(meta, :image))
    |> assign(:meta_keywords, Map.get(meta, :keywords, []))
    |> assign(:meta_published_time, Map.get(meta, :published_time))
    |> assign(:meta_author, Map.get(meta, :author))
  end
end
