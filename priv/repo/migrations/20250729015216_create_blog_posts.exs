defmodule Neptuner.Repo.Migrations.CreateBlogPosts do
  use Ecto.Migration

  def change do
    create table(:blog_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content, :text, null: false
      add :excerpt, :text
      add :keywords, {:array, :string}, default: []
      add :meta_description, :text
      add :published_at, :naive_datetime
      add :featured_image_url, :string
      add :author_name, :string
      add :reading_time_minutes, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blog_posts, [:slug])
    create index(:blog_posts, [:published_at])
    create index(:blog_posts, [:keywords], using: :gin)
  end
end
