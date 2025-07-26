# Blog Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Blog generator integrates a complete content management system into your Phoenix SaaS template. It provides a full-featured blog with markdown support, SEO optimization, admin interface, and publishing workflow using Backpex for content management.

## Installation

Run the generator from your project root:

```bash
mix neptuner.gen.blog
```

The generator can also be automatically installed through the interactive setup process:

```bash
mix neptuner.setup
```

## What It Does

The generator makes comprehensive changes to your application:

### Dependencies Added
- **backpex** (~> 0.13.0) - Modern admin interface for blog management
- **earmark** (~> 1.4) - Markdown parsing and HTML generation
- **slugify** (~> 1.3) - URL-friendly slug generation from titles

### Configuration Files Updated
- **config/config.exs** - Backpex PubSub server and translation configuration
- **.formatter.exs** - Added Backpex to import_deps for consistent formatting
- **assets/js/app.js** - Backpex hooks integration for admin interface
- **assets/css/app.css** - DaisyUI theme configuration and Backpex styling

### Database Schema Created
- **Blog Posts table** (`blog_posts`) - Comprehensive schema for blog content
- **Migration file** (`priv/repo/migrations/*_create_blog_posts.exs`) - Database migration with proper indexes
- **UUID primary keys** - Consistent with template schema conventions

### Core Modules Created
- **Neptuner.Blog** (`lib/neptuner/blog.ex`) - Context module for blog functionality
- **Neptuner.Blog.Post** (`lib/neptuner/blog/post.ex`) - Post schema with auto-generation features
- **BlogController** (`lib/neptuner_web/controllers/blog_controller.ex`) - Public blog routes
- **BlogHTML** (`lib/neptuner_web/controllers/blog_html.ex`) - HTML rendering module

### Admin Interface
- **Admin Post LiveView** (`lib/neptuner_web/live/admin/post_live.ex`) - Backpex-powered blog management
- **Blog layout function** - Custom admin layout with sidebar navigation
- **Translation functions** - Backpex integration with gettext

### Frontend Templates
- **Blog index template** (`blog_html/index.html.heex`) - Blog listing page with pagination
- **Blog post template** (`blog_html/show.html.heex`) - Individual post display with prose styling
- **SEO meta tags** - Comprehensive social media and search engine optimization

### Application Updates
- **Router** (`lib/neptuner_web/router.ex`) - Public blog routes and admin Backpex integration
- **Layouts** (`lib/neptuner_web/components/layouts.ex`) - Blog admin layout function
- **Core Components** (`lib/neptuner_web/components/core_components.ex`) - Backpex translation functions
- **Root HTML** (`lib/neptuner_web/components/layouts/root.html.heex`) - SEO meta tag support

## Configuration

### Blog Post Schema Fields

```elixir
# Content fields
field :title, :string           # Post title (required)
field :slug, :string            # URL-friendly slug (auto-generated)
field :content, :string         # Markdown content (required)
field :excerpt, :string         # Auto-generated excerpt

# SEO fields
field :keywords, {:array, :string}, default: []  # SEO keywords
field :meta_description, :string                 # Meta description
field :featured_image_url, :string              # Social media image

# Publishing fields
field :published_at, :naive_datetime            # Publication timestamp
field :author_name, :string                     # Post author
field :reading_time_minutes, :integer           # Auto-calculated reading time
```

### Auto-Generated Features

- **Slugs**: Automatically generated from titles using the slugify library
- **Excerpts**: First 200 characters of content with ellipsis
- **Reading Time**: Calculated at 200 words per minute
- **SEO Tags**: Comprehensive meta tags for social media sharing

## Usage

### After Installation

1. **Install dependencies:**
   ```bash
   mix deps.get
   ```

2. **Run the database migration:**
   ```bash
   mix ecto.migrate
   ```

3. **Start your server:**
   ```bash
   mix phx.server
   ```

4. **Access the blog:**
   - Public blog: `http://localhost:4000/blog`
   - Admin interface: `http://localhost:4000/admin/posts`

### Blog Management

#### Creating Posts
1. Navigate to `/admin/posts`
2. Click "New Post"
3. Fill in title and content (markdown supported)
4. Set publication date to publish immediately
5. Save to create draft or publish

#### Blog Context Functions

```elixir
# List all published posts
Neptuner.Blog.list_published_posts()

# Get a published post by slug
Neptuner.Blog.get_post_by_slug("my-blog-post")
```

#### Post Schema Functions

```elixir
# Render markdown content as HTML
Neptuner.Blog.Post.render_content(post)

# Render specific field (content or excerpt)
Neptuner.Blog.Post.render_content(post, :excerpt)
```

### Admin Features

The Backpex admin interface provides:

- **CRUD Operations**: Create, read, update, delete blog posts
- **Search**: Full-text search across title, content, and author
- **Field Management**: Rich text editing for content
- **Publishing Workflow**: Draft and publish system with timestamps
- **Slug Management**: Automatic slug generation with readonly display

### SEO Optimization

The blog includes comprehensive SEO features:

#### Meta Tags
- Page title with site name
- Meta description (from post or auto-generated)
- Keywords array for search optimization
- Author attribution

#### Open Graph Tags
- Facebook and LinkedIn sharing optimization
- Featured image support
- Article-specific metadata
- Publication time tracking

#### Twitter Cards
- Twitter sharing optimization
- Large image cards for better engagement
- Title and description optimization

#### Structured Data
- Article schema markup
- Author and publication metadata
- Keyword tagging for better discoverability

## Examples

### Blog Post Creation

```elixir
# Manual post creation
{:ok, post} = Neptuner.Blog.Post.changeset(%Neptuner.Blog.Post{}, %{
  title: "My First Blog Post",
  content: """
  # Welcome to Our Blog
  
  This is **markdown** content that will be rendered as HTML.
  
  - Lists work great
  - So do [links](https://example.com)
  - And `code snippets`
  """,
  author_name: "John Doe",
  published_at: ~N[2024-01-15 10:00:00]
}) |> Neptuner.Repo.insert()
```

### Markdown Rendering

```elixir
# In templates
<article class="prose prose-lg max-w-none">
  <%= raw(Neptuner.Blog.Post.render_content(@post)) %>
</article>
```

### Custom Styling

The blog uses the custom prose CSS classes for beautiful typography:

```html
<!-- Different prose sizes -->
<div class="prose">Regular blog content</div>
<div class="prose-sm">Smaller text</div>
<div class="prose-lg">Larger text</div>
<div class="prose-xl">Extra large text</div>
```

## Customization

### Admin Interface

Modify the admin layout in `layouts.ex`:

```elixir
def blog(assigns) do
  ~H"""
  <Backpex.HTML.Layout.app_shell fluid={@fluid?}>
    <:topbar>
      <!-- Customize admin topbar -->
    </:topbar>
    
    <:sidebar>
      <!-- Add more admin navigation items -->
    </:sidebar>
    
    <div class="p-6">
      {@inner_content}
    </div>
  </Backpex.HTML.Layout.app_shell>
  """
end
```

### Blog Templates

Customize the blog appearance in the template files:

- `blog_html/index.html.heex` - Blog listing page
- `blog_html/show.html.heex` - Individual post page

### Post Schema

Extend the Post schema with additional fields:

```elixir
# Add new fields to migration and schema
field :category, :string
field :tags, {:array, :string}, default: []
field :featured, :boolean, default: false
```

## Next Steps

1. **Customize styling** - Modify prose CSS classes and blog templates
2. **Add categories** - Extend schema with post categorization
3. **Implement comments** - Add reader engagement features
4. **Set up analytics** - Track blog performance and engagement
5. **Create RSS feeds** - Add XML feed generation for subscribers
6. **Add author management** - Multi-author blog support
7. **Implement content approval** - Editorial workflow for team blogs

### Integration with User System

Link blog posts to your user system:

```elixir
# Add author relationship to Post schema
belongs_to :author, Neptuner.Accounts.User, foreign_key: :author_id

# Update admin interface to show author selection
# Add author_id to Backpex fields configuration
```

### Performance Optimization

- **Database indexes**: Already included for published_at and keywords
- **Caching**: Consider caching published posts for high traffic
- **Image optimization**: Optimize featured images for web
- **CDN integration**: Serve static assets through CDN

The Blog generator provides a complete content management foundation for your SaaS application with modern admin tools, SEO optimization, and beautiful typography styling.