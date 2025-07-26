defmodule Mix.Tasks.Neptuner.Gen.Blog do
  @moduledoc """
  Installs a blog system for the SaaS template using Igniter.

  This task:
  - Adds Backpex and Earmark dependencies to mix.exs
  - Updates .formatter.exs to include backpex
  - Adds Backpex hooks to assets/js/app.js
  - Updates CSS theme configuration
  - Creates blog context and post schema
  - Creates blog controller and HTML templates
  - Creates admin post LiveView
  - Updates router with blog routes
  - Adds Backpex translation functions
  - Creates blog posts migration

      $ mix neptuner.gen.blog

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> add_blog_dependencies()
    |> update_formatter_config()
    |> update_js_with_backpex_hooks()
    |> update_config()
    |> update_css_theme_config()
    |> create_blog_context()
    |> create_blog_post_schema()
    |> create_blog_controller()
    |> create_blog_html()
    |> create_blog_html_templates()
    |> create_admin_post_live()
    |> update_layouts()
    |> update_root_html()
    |> update_router_with_blog_routes()
    |> add_backpex_translation_functions()
    |> create_blog_posts_migration()
    |> update_sitemap_controller()
    |> print_completion_notice()
  end

  defp add_blog_dependencies(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "{:backpex,") do
        # Dependencies already exist
        source
      else
        # Add blog dependencies after timex
        updated_content =
          String.replace(
            content,
            ~r/(\{:timex, "~> 3\.7\.13"\})/,
            "\\1,\n      # Blog system\n      {:backpex, \"~> 0.13.0\"},\n      {:earmark, \"~> 1.4\"},\n      {:slugify, \"~> 1.3\"}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_config(igniter) do
    config_content = """
    config :backpex, :pubsub_server, Neptuner.PubSub

    config :backpex,
      translator_function: {NeptunerWeb.CoreComponents, :translate_backpex},
      error_translator_function: {NeptunerWeb.CoreComponents, :translate_error}
    """

    Igniter.update_file(igniter, "config/config.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "config :backpex, backpex") do
        # Config already exists
        source
      else
        # Add config before the import_config line
        updated_content =
          String.replace(
            content,
            ~r/(# Import environment specific config\. This must remain at the bottom)/,
            "\n#{config_content}\n\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_formatter_config(igniter) do
    Igniter.update_file(igniter, ".formatter.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, ":backpex") do
        # Config already updated
        source
      else
        # Add backpex to import_deps
        updated_content =
          String.replace(
            content,
            ~r/(import_deps: \[:ecto, :ecto_sql, :phoenix)/,
            "\\1, :backpex"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_js_with_backpex_hooks(igniter) do
    Igniter.update_file(igniter, "assets/js/app.js", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "BackpexHooks") do
        # Hooks already added
        source
      else
        # Add Backpex hooks import and usage
        updated_content =
          content
          |> String.replace(
            ~r/(import \{ createLiveToastHook \} from "live_toast";)/,
            "\\1\nimport { Hooks as BackpexHooks } from \"backpex\";"
          )
          |> String.replace(
            ~r/(const Hooks = \{\s*LiveToast: createLiveToastHook\(\),)/,
            "\\1\n  ...BackpexHooks,"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_css_theme_config(igniter) do
    Igniter.update_file(igniter, "assets/css/app.css", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "@source \"../../deps/backpex/**/*.*ex\";") do
        # Already updated
        source
      else
        # Add Backpex source and update DaisyUI theme configuration
        updated_content =
          content
          |> String.replace(
            ~r/@source "..\/..\/deps\/live_toast\/lib\/\*\*\/\*\.\*ex";/,
            "@source \"../../deps/live_toast/lib/**/*.*ex\";\n@source \"../../deps/backpex/**/*.*ex\";"
          )
          |> String.replace(
            ~r/themes: false;/,
            "themes: [\"light\", \"dark\"];"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_blog_context(igniter) do
    blog_context_content = """
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
    """

    igniter
    |> Igniter.create_new_file("lib/neptuner/blog.ex", blog_context_content)
  end

  defp create_blog_post_schema(igniter) do
    post_schema_content = """
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
      def changeset(post, attrs, _opts \\\\ []) do
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
                word_count = content |> String.split(~r/\\s+/) |> length()
                reading_time = max(1, round(word_count / 200))
                put_change(changeset, :reading_time_minutes, reading_time)
            end

          _reading_time ->
            changeset
        end
      end

      defp maybe_calculate_reading_time(changeset), do: changeset

      def render_content(post, field \\\\ :content) do
        to_render = Map.get(post, field)

        case Earmark.as_html(to_render) do
          {:ok, html_content, _} -> html_content
          {:error, _html_content, _errors} -> to_render
        end
      end
    end
    """

    igniter
    |> Igniter.create_new_file("lib/neptuner/blog/post.ex", post_schema_content)
  end

  defp create_blog_controller(igniter) do
    controller_content = """
    defmodule NeptunerWeb.BlogController do
      use NeptunerWeb, :controller

      alias Neptuner.Blog

      def index(conn, _params) do
        posts = Blog.list_published_posts()

        conn
        |> put_meta_tags(%{
          title: "Blog - \#{Application.get_env(:neptuner, :app_name)}",
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
              title: "\#{post.title} - \#{Application.get_env(:neptuner, :app_name)}",
              description: post.meta_description || post.excerpt,
              url: url(~p"/blog/\#{post.slug}"),
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
    """

    igniter
    |> Igniter.create_new_file(
      "lib/neptuner_web/controllers/blog_controller.ex",
      controller_content
    )
  end

  defp create_blog_html(igniter) do
    html_content = """
    defmodule NeptunerWeb.BlogHTML do
      use NeptunerWeb, :html

      embed_templates "blog_html/*"
      embed_templates "../components/marketing/*"
    end
    """

    igniter
    |> Igniter.create_new_file(
      "lib/neptuner_web/controllers/blog_html.ex",
      html_content
    )
  end

  defp create_blog_html_templates(igniter) do
    index_template = """
    <LiveToast.toast_group
      flash={@flash}
      connected={assigns[:socket] != nil}
      toasts_sync={assigns[:toasts_sync]}
    />

    <.nav current_scope={@current_scope} />

    <main class="grow">
      <div class="max-w-4xl mx-auto px-4 py-8 mt-24">
        <header class="text-center mb-12">
          <h1 class="text-4xl font-bold text-base-content mb-4">Blog</h1>
          <p class="text-lg text-secondary-content">Latest articles and insights from our team</p>
        </header>

        <%= if @posts == [] do %>
          <div class="text-center py-12">
            <p class="text-secondary-content">No blog posts published yet.</p>
          </div>
        <% else %>
          <div class="grid gap-8">
            <%= for post <- @posts do %>
              <article class="rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
                <%= if post.featured_image_url do %>
                  <img src={post.featured_image_url} alt={post.title} class="w-full h-48 object-cover" />
                <% end %>

                <div class="p-6">
                  <div class="flex items-center text-sm text-secondary-content mb-2">
                    <%= if post.author_name do %>
                      <span><%= post.author_name %></span>
                      <span class="mx-2">•</span>
                    <% end %>
                    <time><%= Calendar.strftime(post.published_at, "%B %d, %Y") %></time>
                    <%= if post.reading_time_minutes do %>
                      <span class="mx-2">•</span>
                      <span><%= post.reading_time_minutes %> min read</span>
                    <% end %>
                  </div>

                  <h2 class="text-xl font-semibold text-base-content mb-3">
                    <a href={~p"/blog/\#{post.slug}"} class="hover:text-primary">
                      <%= post.title %>
                    </a>
                  </h2>

                  <a href={~p"/blog/\#{post.slug}"} class="text-primary hover:text-primary-focus font-medium">
                    Read more →
                  </a>
                </div>
              </article>
            <% end %>
          </div>
        <% end %>
      </div>
    </main>

    <.footer />
    """

    show_template = """
    <LiveToast.toast_group
      flash={@flash}
      connected={assigns[:socket] != nil}
      toasts_sync={assigns[:toasts_sync]}
    />

    <.nav current_scope={@current_scope} />

    <main class="grow">
      <div class="max-w-4xl mx-auto px-4 py-8 mt-24">
        <header class="py-8">
          <nav class="mb-6">
            <a href={~p"/blog"} class="inline-flex items-center text-primary hover:text-secondary">
              <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Blog
            </a>
          </nav>

          <div class="mb-6">
            <h1 class="text-4xl font-bold text-base-content mb-4"><%= @post.title %></h1>

            <div class="flex items-center text-sm text-secondary-content mb-4">
              <%= if @post.author_name do %>
                <span><%= @post.author_name %></span>
                <span class="mx-2">•</span>
              <% end %>
              <time><%= Calendar.strftime(@post.published_at, "%B %d, %Y") %></time>
              <%= if @post.reading_time_minutes do %>
                <span class="mx-2">•</span>
                <span><%= @post.reading_time_minutes %> min read</span>
              <% end %>
            </div>
          </div>

          <%= if @post.featured_image_url do %>
            <img src={@post.featured_image_url} alt={@post.title} class="w-full h-64 object-cover rounded-lg mb-8" />
          <% end %>
        </header>

        <article class="prose prose-lg max-w-none">
          {raw(Neptuner.Blog.Post.render_content(@post))}
        </article>

        <div class="mt-12 pt-8 border-t border-gray-200">
          <div class="flex justify-between items-center">
            <a href={~p"/blog"} class="inline-flex items-center text-primary hover:text-primary">
              <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Blog
            </a>

            <div class="flex items-center gap-4">
              <span class="text-sm text-secondary-content">Share this article:</span>
              <div class="flex gap-2">
                <a href={"https://twitter.com/intent/tweet?url=\#{url(~p"/blog/\#{@post.slug}")}&text=\#{@post.title}"}
                   target="_blank"
                   class="text-secondary-content hover:text-primary">
                  <.icon name="hero-share" class="w-5 h-5" />
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <.footer />
    """

    igniter
    |> Igniter.create_new_file(
      "lib/neptuner_web/controllers/blog_html/index.html.heex",
      index_template
    )
    |> Igniter.create_new_file(
      "lib/neptuner_web/controllers/blog_html/show.html.heex",
      show_template
    )
  end

  defp create_admin_post_live(igniter) do
    admin_live_content = """
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
    """

    igniter
    |> Igniter.create_new_file(
      "lib/neptuner_web/live/admin/post_live.ex",
      admin_live_content
    )
  end

  defp update_layouts(igniter) do
    blog_layout_function = """

      def blog(assigns) do
        ~H\"\"\"
        <Backpex.HTML.Layout.app_shell fluid={@fluid?}>
          <:topbar>
            <Backpex.HTML.Layout.topbar_branding />

            <Backpex.HTML.Layout.topbar_dropdown class="mr-2 md:mr-0">
              <:label>
                <label>
                  <.icon name="hero-user" class="h-4 w-4" />
                </label>
              </:label>

              <li
                type="button"
                label={translate_backpex("Sign out")}
                icon="hero-arrow-right-start-on-rectangle"
                click="logout"
              />
            </Backpex.HTML.Layout.topbar_dropdown>
          </:topbar>

          <:sidebar>
            <Backpex.HTML.Layout.sidebar_item
              current_url={@current_url}
              navigate={~p"/admin/posts"}
            />
          </:sidebar>

          <div class="p-6">
            {@inner_content}
          </div>
        </Backpex.HTML.Layout.app_shell>
        \"\"\"
      end
    """

    Igniter.update_file(igniter, "lib/neptuner_web/components/layouts.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "alias Backpex") do
        # Already updated
        source
      else
        # Add Backpex alias and blog layout function
        updated_content =
          content
          |> String.replace(
            ~r/(use NeptunerWeb, :html)/,
            "\\1\n  alias Backpex"
          )
          |> String.replace(
            ~r/(def theme_toggle\(assigns\) do[\s\S]*?end)/,
            "\\1#{blog_layout_function}"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp update_root_html(igniter) do
    Igniter.update_file(
      igniter,
      "lib/neptuner_web/components/layouts/root.html.heex",
      fn source ->
        content = Rewrite.Source.get(source, :content)

        if String.contains?(content, "SEO Meta Tags") do
          # Already updated
          source
        else
          # Add SEO meta tags after the live_title
          meta_tags = """

          <!-- SEO Meta Tags -->
          <meta :if={assigns[:meta_description]} name="description" content={@meta_description} />
          <meta :if={assigns[:meta_keywords] && @meta_keywords != []} name="keywords" content={Enum.join(@meta_keywords, ", ")} />
          <meta :if={assigns[:meta_author]} name="author" content={@meta_author} />

          <!-- Open Graph Meta Tags -->
          <meta property="og:title" content={assigns[:page_title] || "Neptuner"} />
          <meta :if={assigns[:meta_description]} property="og:description" content={@meta_description} />
          <meta :if={assigns[:meta_url]} property="og:url" content={@meta_url} />
          <meta property="og:type" content={assigns[:meta_type] || "website"} />
          <meta :if={assigns[:meta_image]} property="og:image" content={@meta_image} />
          <meta property="og:site_name" content={Application.get_env(:neptuner, :app_name)} />

          <!-- Twitter Card Meta Tags -->
          <meta name="twitter:card" content="summary_large_image" />
          <meta name="twitter:title" content={assigns[:page_title] || "Neptuner"} />
          <meta :if={assigns[:meta_description]} name="twitter:description" content={@meta_description} />
          <meta :if={assigns[:meta_image]} name="twitter:image" content={@meta_image} />

          <!-- Article Meta Tags -->
          <meta :if={assigns[:meta_published_time]} property="article:published_time" content={@meta_published_time} />
          <meta :if={assigns[:meta_author]} property="article:author" content={@meta_author} />
          <%= if assigns[:meta_keywords] && @meta_keywords != [] do %>
            <%= for keyword <- @meta_keywords do %>
              <meta property="article:tag" content={keyword} />
            <% end %>
          <% end %>
          """

          updated_content =
            String.replace(
              content,
              ~r/(<\.live_title default="Neptuner" suffix=" · Phoenix Framework">[\s\S]*?<\/\.live_title>)/,
              "\\1#{meta_tags}"
            )

          Rewrite.Source.update(source, :content, updated_content)
        end
      end
    )
  end

  defp update_router_with_blog_routes(igniter) do
    Igniter.update_file(igniter, "lib/neptuner_web/router.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "get \"/blog\"") do
        # Blog routes already exist
        source
      else
        # Add Backpex import and blog routes
        updated_content =
          content
          |> String.replace(
            ~r/(import NeptunerWeb\.UserAuth)/,
            "\\1\n  import Backpex.Router"
          )
          |> String.replace(
            ~r/(get "\/", PageController, :home)/,
            "\\1\n    get \"/blog\", BlogController, :index\n    get \"/blog/:slug\", BlogController, :show"
          )
          |> String.replace(
            ~r/(scope "\/admin" do\s*pipe_through \[:browser, :admin_protected\])/,
            "\\1\n\n    backpex_routes()\n\n    live_session :default, on_mount: Backpex.InitAssigns do\n      live_resources \"/posts\", NeptunerWeb.Live.Admin.PostLive\n    end"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp add_backpex_translation_functions(igniter) do
    Igniter.update_file(
      igniter,
      "lib/neptuner_web/components/core_components.ex",
      fn source ->
        content = Rewrite.Source.get(source, :content)

        if String.contains?(content, "translate_backpex") do
          # Translation functions already exist
          source
        else
          # Add translation functions at the end of the module
          translation_functions = """
            @doc \"\"\"
            Translates Backpex strings using gettext.
            \"\"\"
            def translate_backpex({msg, bindings}) do
              Gettext.dgettext(NeptunerWeb.Gettext, "backpex", msg, bindings)
            end

            def translate_backpex(msg) when is_binary(msg) do
              Gettext.dgettext(NeptunerWeb.Gettext, "backpex", msg)
            end
          """

          updated_content =
            String.replace(
              content,
              ~r/(end\s*$)/,
              "#{translation_functions}\n\\1"
            )

          Rewrite.Source.update(source, :content, updated_content)
        end
      end
    )
  end

  defp create_blog_posts_migration(igniter) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")

    migration_content = """
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
    """

    igniter
    |> Igniter.create_new_file(
      "priv/repo/migrations/#{timestamp}_create_blog_posts.exs",
      migration_content
    )
  end

  defp update_sitemap_controller(igniter) do
    # Add blog functionality to existing sitemap controller
    sitemap_controller_path = "lib/neptuner_web/controllers/sitemap_controller.ex"

    Igniter.update_file(igniter, sitemap_controller_path, fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "add_blog_urls") do
        # Blog functionality already added
        source
      else
        blog_function = ~s"""
          defp add_blog_urls(urls, _conn) do
            blog_urls = Neptuner.Blog.list_published_posts()
            |> Enum.map(fn post ->
              %{
                loc: url(~p"/blog/\#{post.slug}"),
                lastmod: DateTime.from_naive!(post.updated_at, "Etc/UTC") |> DateTime.to_iso8601(),
                changefreq: "monthly",
                priority: "0.8"
              }
            end)

            blog_index_url = %{
              loc: url(~p"/blog"),
              changefreq: "weekly",
              priority: "0.9"
            }

            urls ++ [blog_index_url | blog_urls]
          end

        """

        # Add blog URLs to the index function and add the blog function
        updated_content =
          content
          |> String.replace(
            ~r/(urls = \[\]\s*\|\> add_static_urls\(conn\))/,
            "\\1\n    |> add_blog_urls(conn)"
          )
          |> String.replace(
            ~r/(defp generate_sitemap_xml\(urls\) do)/,
            blog_function <> "\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp print_completion_notice(igniter) do
    completion_message = """

    ## Blog System Integration Complete! 📝

    A complete blog system has been successfully integrated into your SaaS template. Here's what was configured:

    ### Dependencies Added:
    - Backpex ~> 0.13.0 for admin interface
    - Earmark ~> 1.4 for markdown rendering
    - Updated .formatter.exs to include :backpex

    ### Features Implemented:
    - **Blog Context**: Full blog functionality with published posts queries
    - **Post Schema**: Complete blog post model with auto-generated slugs, excerpts, and reading time
    - **Public Blog**: Frontend blog with index and show pages
    - **Admin Interface**: Backpex-powered admin for managing blog posts
    - **SEO Optimized**: Meta tags, slugs, and structured data
    - **Markdown Support**: Full markdown rendering with Earmark
    - **Sitemap Integration**: Automatic sitemap.xml generation including blog posts

    ### Files Created:
    - lib/neptuner/blog.ex - Blog context
    - lib/neptuner/blog/post.ex - Post schema
    - lib/neptuner_web/controllers/blog_controller.ex - Blog controller
    - lib/neptuner_web/controllers/blog_html.ex - Blog HTML module
    - lib/neptuner_web/controllers/blog_html/index.html.heex - Blog index template
    - lib/neptuner_web/controllers/blog_html/show.html.heex - Blog post template
    - lib/neptuner_web/live/admin/post_live.ex - Admin post management
    - lib/neptuner_web/controllers/sitemap_controller.ex - Sitemap generation
    - Database migration for blog_posts table

    ### Code Updates:
    - Updated mix.exs with new dependencies
    - Added Backpex hooks to assets/js/app.js
    - Updated CSS theme configuration
    - Added blog routes to router.ex
    - Added sitemap route to router.ex
    - Added Backpex translation functions to core_components.ex
    - Added Backpex alias and blog layout to layouts.ex
    - Added SEO meta tags to root.html.heex

    ### Database Schema:
    - **blog_posts** table with UUID primary key
    - Auto-generated slugs from titles
    - SEO fields: meta_description, keywords
    - Publishing workflow with published_at timestamps
    - Reading time calculation (200 words/minute)
    - Featured image support

    ### Next Steps:
    1. Run `mix deps.get` to install new dependencies
    2. Run `mix ecto.migrate` to create the blog_posts table
    3. Start your server with `mix phx.server`
    4. Visit `/blog` to see the public blog
    5. Visit `/sitemap.xml` to see the auto-generated sitemap
    6. Access the admin at `/admin/posts` to manage blog posts

    ### Blog Features:
    - **SEO Optimized**: Automatic meta tags and structured data
    - **Sitemap Integration**: All blog posts automatically included in sitemap.xml
    - **Markdown Support**: Write posts in markdown
    - **Admin Interface**: Full CRUD operations with Backpex
    - **Auto-generated Content**: Slugs, excerpts, and reading time
    - **Publishing Workflow**: Draft and publish system
    - **Responsive Design**: Mobile-friendly blog templates

    🎉 Your blog system is ready to use!
    """

    Igniter.add_notice(igniter, completion_message)
    igniter
  end
end
