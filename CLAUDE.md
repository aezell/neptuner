# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Phoenix SaaS Template** - a full-stack Elixir web application built with Phoenix Framework v1.8.0-rc.0. The project serves as a foundation for building Software as a Service applications with modern tooling and comprehensive styling setup.

## Development Commands

### Project Setup

```bash
mix setup                   # Complete project setup: deps, database, assets
mix neptuner.setup     # Modular application setup
mix phx.server              # Start development server at localhost:4000
iex -S mix phx.server       # Start server with interactive Elixir shell
```

### Database Operations

```bash
mix ecto.setup              # Create database, run migrations, seed data
mix ecto.reset              # Drop and recreate database
mix ecto.create             # Create database only
mix ecto.migrate            # Run pending migrations
```

### Asset Management

```bash
mix assets.setup            # Install Tailwind and esbuild tools
mix assets.build            # Build assets for development
mix assets.deploy           # Build and optimize assets for production (includes minification and digest)
```

### Testing

```bash
mix test                    # Run tests (automatically creates test database)
mix test.watch              # Run continuous tests for development purposes
```

## Architecture Overview

### Application Structure

- **Neptuner.Application**: OTP supervision tree with telemetry, database, PubSub, and web endpoint
- **NeptunerWeb**: Web layer containing controllers, components, and LiveView functionality
- **Database**: PostgreSQL with Ecto ORM (currently minimal schema setup)

### Key Dependencies

- **Phoenix LiveView**: Enables real-time, interactive UI without JavaScript
- **Tailwind CSS v4**: Modern utility-first CSS framework with custom theme configuration
- **Tidewave**: Development-only dependency for enhanced developer experience
- **Bandit**: HTTP server (modern alternative to Cowboy)
- **HeroIcons**: Icon library integrated as compile-time dependency

### Web Layer Organization

```
lib/neptuner_web/
├── controllers/           # HTTP request handlers
├── components/           # Reusable UI components and layouts
├── endpoint.ex          # HTTP endpoint with session and middleware config
├── router.ex            # URL routing with browser/API pipelines
└── telemetry.ex         # Application metrics and monitoring
```

## Font and Styling System

The project includes a comprehensive custom typography system:

- **Haskoy Font Family**: Complete font collection with variable and static weights (100-800)
- **Font Files**: Located in `priv/static/fonts/` with OTF, TTF, and WOFF2 formats
- **Font Configuration**: Defined in `assets/css/fonts.css` and imported into main CSS
- **Tailwind Integration**: Haskoy set as primary `font-sans` family in theme configuration

### CSS Architecture

- `assets/css/app.css`: Main stylesheet with Tailwind imports and theme configuration
- `assets/css/fonts.css`: Font face declarations for Haskoy family
- Custom DaisyUI themes with light/dark mode support
- Shadow utilities with custom elevation classes

## Development Features

### Live Development

- **Live Reload**: Automatic browser refresh on file changes
- **Code Reloading**: Hot code swap in development without restart
- **LiveDashboard**: Available at `/dev/dashboard` for application monitoring
- **Mailbox Preview**: Available at `/dev/mailbox` for email testing

### Database Configuration

- **Development DB**: `neptuner_dev` with postgres/postgres credentials
- **Connection Pool**: 10 connections in development
- **Automatic Setup**: Database created and migrated via `mix setup`

## Production Considerations

The template includes production-ready configurations:

- Asset optimization and compression via `mix assets.deploy`
- Telemetry and monitoring setup
- Session security configurations
- Error handling and logging
- DNS cluster support for distributed deployments

## Current State

- **Template Status**: Basic Phoenix setup with minimal routes (only home page)
- **Git Branch**: Currently on `landing-page` branch
- **Ready for**: Feature development, authentication setup, business logic implementation

## Code Style Guidelines

### Function Design

- **Small, Self-Documented Functions**: Write concise functions with clear, descriptive names that explain their purpose
- **Single Responsibility**: Each function should have one clear responsibility and do it well
- **Highly Testable**: Design functions to be easily unit tested with minimal setup and clear inputs/outputs

### Code Organization

- **Separation of Concerns**: Split functionality across different files and modules where it makes logical sense
- **Logical File Structure**: Group related functions together, separate business logic from presentation logic
- **Module Boundaries**: Respect Phoenix conventions (contexts, controllers, views) and create additional modules as needed

### Documentation

- **No Comments by Default**: Code should be self-explanatory through good naming and structure
- **Comments Only When Necessary**: Add comments only for extremely complicated functionality that cannot be made clear through refactoring
- **Prefer Refactoring**: If code needs comments to be understood, consider breaking it into smaller, clearer functions first

## UI Components Guidelines

### Core Components Usage

- **Check CoreComponents First**: Always examine `lib/neptuner_web/components/core_components.ex` before creating new reusable UI components
- **Use Existing Components**: Leverage existing components like `flash/1`, `button/1`, `input/1`, `header/1`, `table/1`, `list/1`, and `icon/1` for core LiveView functionality
- **Add New Components Here**: Place new reusable UI components in `core_components.ex` to maintain consistency

### Styling Standards

- **DaisyUI Classes**: Use DaisyUI component classes (e.g., `btn`, `input`, `select`, `table`, `alert`) for semantic UI elements
- **Tailwind v4 Utilities**: Leverage Tailwind utility classes for layout, spacing, and responsive design
- **Theme Compliance**: Respect the color theme defined in `assets/css/app.css` with custom light/dark mode configurations
- **Typography**: Components should use the Haskoy font family through existing font-sans classes

### Component Architecture

- **Phoenix.Component**: All components use Phoenix.Component with proper attributes and slots
- **Proper Documentation**: Include @doc strings with examples for complex components
- **Accessible Markup**: Follow accessibility best practices with proper ARIA labels and semantic HTML

## Development Workflow Notes

- Use Tidewave MCP server whenever required to check things are working
- Do not start the server, I will do that
- Use `mix setup` for initial project setup or after pulling changes
- The project uses Phoenix 1.8 pre-release with latest LiveView features
- All asset building is automated through Mix aliases
- Database operations are safe to run repeatedly (idempotent)
- Development server automatically handles code reloading and live reload

## Setup Script Testing Workflow

- The `mix neptuner.setup` script is designed to be run once on a fresh template
- After each test run, the project is reset to its original state before testing again
- This simulates the real user experience of running the setup script on a clean template
- When debugging setup issues, assume the project is in its original clean state
- Any file changes mentioned are from the most recent setup run, not accumulated changes

## Code Style Enforcement

### Automated Formatting

- **Always run `mix format`** before committing code
- Use `.formatter.exs` configuration for consistent formatting across the team
- Configure editor to format on save for seamless development

### Code Quality Standards

- **Function Length**: Keep functions under 20 lines when possible
- **Module Organization**: Group related functions together, separate public and private functions
- **Naming Conventions**: Use descriptive names that explain intent without needing comments
- **Error Handling**: Use pattern matching and `with` statements for clean error handling

## Testing Patterns

### ExUnit Best Practices

```elixir
# Use descriptive test names
test "user registration creates account with valid email" do
  # Given
  valid_attrs = %{email: "test@example.com", password: "password123"}

  # When
  {:ok, user} = Accounts.register_user(valid_attrs)

  # Then
  assert user.email == "test@example.com"
  assert user.confirmed_at == nil
end
```

### ExMachina Factory Patterns

```elixir
# Use factories for consistent test data
def user_factory do
  %Neptuner.Accounts.User{
    email: sequence(:email, &"user#{&1}@example.com"),
    hashed_password: Bcrypt.hash_pwd_salt("password123"),
    confirmed_at: ~N[2023-01-01 10:00:00]
  }
end

# Test with build/insert for different scenarios
test "user with organization membership" do
  user = insert(:user)
  organization = insert(:organization)
  insert(:membership, user: user, organization: organization)

  # Test implementation
end
```

### LiveView Testing Patterns

```elixir
# Test LiveView interactions
test "user registration form submits successfully", %{conn: conn} do
  {:ok, lv, _html} = live(conn, ~p"/users/register")

  result = lv
    |> form("#registration_form", user: %{email: "test@example.com", password: "password123"})
    |> render_submit()

  assert_redirect(lv, ~p"/users/confirm")
end
```

## Performance Optimization Guidelines

### LiveView Performance

- **Minimize assigns**: Only assign data that templates actually use
- **Use temporary assigns**: For large data sets that don't persist between renders
- **Optimize database queries**: Use `preload` and avoid N+1 queries
- **Handle LiveView process lifecycle**: Clean up resources in `terminate/2`

### Database Performance

```elixir
# Use preloads to avoid N+1 queries
users = Repo.all(User) |> Repo.preload(:organization)

# Use select to limit returned fields
users = from(u in User, select: [:id, :email]) |> Repo.all()

# Use indexes for frequently queried fields
create index(:users, [:email])
create index(:users, [:organization_id])
```

### Memory Management

- **Monitor GenServer state**: Keep state minimal and clean up unused data
- **Use ETS for caching**: Cache frequently accessed data in ETS tables
- **Handle file uploads**: Stream large files instead of loading into memory

## Security Best Practices

### Authentication & Authorization

- **Always validate user permissions**: Check authorization in controllers and LiveViews
- **Use secure password hashing**: Bcrypt with appropriate rounds
- **Implement rate limiting**: Protect against brute force attacks
- **Validate all inputs**: Never trust user input, always validate and sanitize

### Data Protection

```elixir
# Use changeset validations
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :password])
  |> validate_required([:email, :password])
  |> validate_email()
  |> validate_length(:password, min: 8)
  |> unique_constraint(:email)
end
```

### API Security

- **Use CSRF protection**: Enable CSRF tokens for all forms
- **Implement proper headers**: Set security headers in endpoint configuration
- **Rate limit API endpoints**: Prevent abuse with rate limiting
- **Log security events**: Track authentication attempts and failures

## Deployment Checklist

### Pre-Deployment

- [ ] Run `mix test` - All tests pass
- [ ] Run `mix format --check-formatted` - Code is properly formatted
- [ ] Run `mix assets.deploy` - Assets are optimized for production
- [ ] Check environment variables are set correctly
- [ ] Verify database migrations are ready
- [ ] Review security configurations

### Production Configuration

- [ ] Set `SECRET_KEY_BASE` to secure random value
- [ ] Configure `DATABASE_URL` for production database
- [ ] Set appropriate `PHX_HOST` for your domain
- [ ] Configure SSL/TLS certificates
- [ ] Set up monitoring and logging
- [ ] Configure backup strategies

### Post-Deployment

- [ ] Verify application starts successfully
- [ ] Check database migrations ran correctly
- [ ] Test critical user flows
- [ ] Monitor application performance
- [ ] Verify email delivery works
- [ ] Check error tracking is active

## Troubleshooting Guide

### Common Development Issues

- **Port already in use**: Kill process with `lsof -ti:4000 | xargs kill -9`
- **Database connection errors**: Check PostgreSQL is running and credentials are correct
- **Asset compilation issues**: Run `mix assets.setup` to reinstall dependencies
- **LiveView not updating**: Check websocket connection and ensure proper assigns

### Performance Issues

- **Slow page loads**: Check database query performance with `Ecto.Adapters.SQL.explain`
- **Memory usage**: Monitor with `:observer.start()` in IEx
- **Process bottlenecks**: Use `:sys.get_state/1` to inspect GenServer state

### Production Troubleshooting

- **Application won't start**: Check logs for configuration errors
- **Database migration failures**: Review migration files and database state
- **Asset loading issues**: Verify assets were compiled with `mix assets.deploy`
- **SSL certificate problems**: Check certificate validity and configuration

## Phoenix Support

## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`. **Never use `else if` or `elseif` in Elixir**, **always\*\* use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you _must_ bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`
- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it

## Ecto Guidelines

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`
- `Ecto.Schema` fields always use the `:string` type, even for `:text`, columns, ie: `field :name, :string`
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such as option is never needed
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct

## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- For "app wide" template imports, you can import/alias into the `my_app_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponent's, and all modules that do `use MyAppWeb, :html` (replace "my_app" by the actual app name)

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you _must_ annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes, **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`)

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>

## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`
- Remember anytime you use `phx-hook="MyHook"` and that js hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Never** write embedded `<script>` tags in HEEx. Instead always write your scripts and hooks in the `assets/js` directory and integrate them with the `assets/js/app.js` file

### LiveView streams

- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:

  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- LiveView streams are _not_ enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # re-fetch the messages based on the filter
        messages = list_messages(filter)

        {:noreply,
        socket
        |> assign(:messages_empty?, messages == [])
        # reset the stream with the new messages
        |> stream(:messages, messages, reset: true)}
      end

- LiveView streams _do not support counting or empty states_. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @stream.tasks} id={id}>
          {task.name}
        </div>
      </div>

  The above only works if the empty state is the only HTML block alongside the stream for-comprehension.

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections

### LiveView tests

- `Phoenix.LiveViewTest` module and `LazyHTML` (included) for making your assertions
- Form tests are driven by `Phoenix.LiveViewTest`'s `render_submit/2` and `render_change/2` functions
- Come up with a step-by-step test plan that splits major test cases into small, isolated files. You may start with simpler tests that verify content exists, gradually add interaction tests
- **Always reference the key element IDs you added in the LiveView templates in your tests** for `Phoenix.LiveViewTest` functions like `element/2`, `has_element/2`, selectors, etc
- **Never** tests again raw HTML, **always** use `element/2`, `has_element/2`, and similar: `assert has_element?(view, "#my-form")`
- Instead of relying on testing text content, which can change, favor testing for the presence of key elements
- Focus on testing outcomes rather than implementation details
- Be aware that `Phoenix.Component` functions like `<.form>` might produce different HTML than expected. Test against the output HTML structure, not your mental model of what you expect it to be
- When facing test failures with element selectors, add debug statements to print the actual HTML, but use `LazyHTML` selectors to limit the output, ie:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Form handling

#### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected to have string keys.

You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`.

In the template, the form form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

#### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always access forms this**:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

And **never** do this:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template as it will cause errors
- **Never** use `<.form let={f} ...>` in the template, instead **always use `<.form for={@form} ...>`**, then drive all form references from the form assign as in `@form[:field]`. The UI should **always** be driven by a `to_form/2` assigned in the LiveView module that is derived from a changeset

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
  custom classes must fully style the input

### JS and CSS guidelines

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates**

### UI/UX & design guidelines

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions

## Authentication

- **Always** handle authentication flow at the router level with proper redirects
- **Always** be mindful of where to place routes. `phx.gen.auth` creates multiple router plugs and `live_session` scopes:
  - A `live_session :current_user` scope - For routes that need the current user but don't require authentication
  - A `live_session :require_authenticated_user` scope - For routes that require authentication
  - In both cases, a `@current_scope` is assigned to the Plug connection and LiveView socket
- **Always let the user know in which router scopes, `live_session`, and pipeline you are placing the route, AND SAY WHY**
- `phx.gen.auth` assigns the `current_scope` assign - it **does not assign the `current_user` assign**.
- To derive/access `current_user`, **always use the `current_scope.user` assign**, never use **`@current_user`** in templates or LiveViews
- **Never** duplicate `live_session` names. A `live_session :current_user` can only be defined **once** in the router, so all routes for the `live_session :current_user` must be grouped in a single block
- Anytime you hit `current_scope` errors or the logged in session isn't displaying the right content, **always double check the router and ensure you are using the correct `live_session` described below**

### Routes that require authentication

LiveViews that require login should **always be placed inside the **existing** `live_session :require_authenticated_user` block**:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
        # phx.gen.auth generated routes
        live "/users/settings", UserSettingsLive, :edit
        live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
        # our own routes that require logged in user
        live "/", MyLiveThatRequiresAuth, :index
      end
    end

### Routes that work with or without authentication

LiveViews that can work with or without authentication, **always use the **existing** `:current_user` scope**, ie:

    scope "/", MyAppWeb do
      pipe_through [:browser]

      live_session :current_user,
        on_mount: [{MyAppWeb.UserAuth, :mount_current_scope}] do
        # our own routes that work with or without authentication
        live "/", PublicLive
      end
    end
