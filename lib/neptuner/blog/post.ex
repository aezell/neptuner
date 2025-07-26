defmodule Neptuner.Blog.Post do
  use Neptuner.Schema

  schema "blog_posts" do
    field :title, :string
    field :slug, :string
    field :content, :string
    field :excerpt, :string
    field :keywords, {:array, :string}, default: []
    field :meta_description, :string
    field :published_at, :naive_datetime
    field :featured_image_url, :string
    field :author_name, :string
    field :reading_time_minutes, :integer

    timestamps()
  end

  @doc false
  def changeset(post, attrs, _opts \\ []) do
    post
    |> cast(attrs, [
      :title,
      :slug,
      :content,
      :excerpt,
      :keywords,
      :meta_description,
      :published_at,
      :featured_image_url,
      :author_name,
      :reading_time_minutes
    ])
    |> validate_required([:title, :content])
    |> maybe_generate_slug()
    |> maybe_generate_excerpt()
    |> maybe_calculate_reading_time()
    |> unique_constraint(:slug)
  end

  defp maybe_generate_slug(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :title) do
          nil -> changeset
          title -> put_change(changeset, :slug, Slug.slugify(title))
        end

      _slug ->
        changeset
    end
  end

  defp maybe_generate_slug(changeset), do: changeset

  defp maybe_generate_excerpt(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :excerpt) do
      nil ->
        case get_change(changeset, :content) do
          nil ->
            changeset

          content ->
            excerpt = content |> String.slice(0, 200) |> String.trim() |> Kernel.<>("...")
            put_change(changeset, :excerpt, excerpt)
        end

      _excerpt ->
        changeset
    end
  end

  defp maybe_generate_excerpt(changeset), do: changeset

  defp maybe_calculate_reading_time(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :reading_time_minutes) do
      nil ->
        case get_change(changeset, :content) do
          nil ->
            changeset

          content ->
            word_count = content |> String.split(~r/\s+/) |> length()
            reading_time = max(1, round(word_count / 200))
            put_change(changeset, :reading_time_minutes, reading_time)
        end

      _reading_time ->
        changeset
    end
  end

  defp maybe_calculate_reading_time(changeset), do: changeset

  def render_content(post, field \\ :content) do
    to_render = Map.get(post, field)

    case Earmark.as_html(to_render) do
      {:ok, html_content, _} -> html_content
      {:error, _html_content, _errors} -> to_render
    end
  end
end
