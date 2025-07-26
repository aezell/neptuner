defmodule NeptunerWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: NeptunerWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50 text-base-content"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark-solid" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch)
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    base_classes =
      "btn rounded-full border-none transition-all font-normal duration-300 focus:ring-2 h-9 px-4 py-2 text-sm focus:outline-none focus:ring-offset-2"

    variants = %{
      "primary" => "text-white bg-primary hover:bg-primary/90 focus:ring-primary",
      nil => "text-base-content bg-base-300 hover:text-primary focus:ring-base-300"
    }

    assigns =
      assigns
      |> assign(:class, Map.fetch!(variants, assigns[:variant]))
      |> assign(:base_classes, base_classes)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={[@base_classes, @class]} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={[@base_classes, @class]} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <fieldset class="form-control mb-2">
      <label class="label cursor-pointer justify-start gap-3">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="checkbox checkbox-primary"
          {@rest}
        />
        <span class="label-text">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="form-control mb-2">
      <label :if={@label} class="label">
        <span class="label-text">{@label}</span>
      </label>
      <select
        id={@id}
        name={@name}
        class={["select select-bordered w-full focus:select-primary", @errors != [] && "select-error"]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="form-control mb-2">
      <label :if={@label} class="label">
        <span class="label-text">{@label}</span>
      </label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "textarea textarea-bordered w-full focus:textarea-primary",
          @errors != [] && "textarea-error"
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="form-control mb-2">
      <label :if={@label} class="label">
        <span class="label-text">{@label}</span>
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "input transition-all w-full focus:input-primary",
          @errors != [] && "input-error"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <div class="label">
      <span class="label-text-alt text-error flex gap-2 items-center">
        <.icon name="hero-exclamation-circle-mini" class="size-4" />
        {render_slot(@inner_block)}
      </span>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4", @class]}>
      <div>
        <h1 class="text-2xl font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div>
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  attr(:pause_on_hover, :boolean, default: false, doc: "Pause on hover")
  attr(:repeat, :integer, default: 4, doc: "Number of repeats")
  attr(:vertical, :boolean, default: false, doc: "Vertical")
  attr(:reverse, :boolean, default: false, doc: "Reverse")
  attr(:class, :string, default: "", doc: "CSS class for parent div")

  attr(:rest, :global)

  slot(:inner_block, required: true)

  def marquee(assigns) do
    ~H"""
    <div
      :if={@repeat > 0}
      class={[
        "group flex overflow-hidden p-2 [--duration:40s] [--gap:1rem] [gap:var(--gap)]",
        @vertical && "flex-col",
        !@vertical && "flex-row",
        @class
      ]}
      {@rest}
    >
      <%= for _ <- 0..(@repeat - 1) do %>
        <div
          class={[
            "flex shrink-0 justify-around [gap:var(--gap)]",
            @vertical && "animate-marquee-vertical flex-col",
            !@vertical && "animate-marquee flex-row",
            @pause_on_hover && "group-hover:[animation-play-state:paused]"
          ]}
          style={@reverse && "animation-direction: reverse;"}
        >
          {render_slot(@inner_block)}
        </div>
      <% end %>
    </div>
    """
  end

  def product_logo(assigns) do
    ~H"""
    <svg
      id="logo-51"
      width="40"
      height="40"
      viewBox="0 0 40 40"
      fill="none"
      class="size-8"
      alt={Application.get_env(:neptuner, :app_name) <> " logo"}
      aria-label={Application.get_env(:neptuner, :app_name) <> " logo"}
    >
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M8.65417 3.89149C7.22351 4.89185 5.92981 6.0746 4.80676 7.40602C9.39606 6.97995 15.2266 7.67567 21.9958 11.0603C29.2244 14.6745 35.0452 14.7967 39.0962 14.0153C38.7286 12.9024 38.2658 11.8328 37.7177 10.816C33.0804 11.3051 27.1354 10.6577 20.207 7.1936C15.8074 4.9938 11.9292 4.08763 8.65417 3.89149ZM35.0088 6.96027C31.3467 2.86862 26.0248 0.293625 20.1014 0.293625C18.3619 0.293625 16.6741 0.515732 15.0651 0.933105C17.2443 1.52771 19.5593 2.39761 21.9958 3.61589C27.0684 6.15215 31.4478 6.96878 35.0088 6.96027ZM39.9623 17.9217C35.0683 18.8881 28.3102 18.6896 20.207 14.638C12.6314 10.8502 6.60187 10.8979 2.53534 11.8016C2.32544 11.8482 2.12048 11.8972 1.92047 11.9482C1.38806 13.1061 0.963074 14.3237 0.658142 15.5881C0.983826 15.5011 1.32037 15.4184 1.6676 15.3412C6.60101 14.2449 13.5715 14.2925 21.9958 18.5047C29.5715 22.2925 35.601 22.2448 39.6676 21.3411C39.8069 21.3102 39.9442 21.2782 40.0792 21.2452C40.094 20.9299 40.1014 20.6126 40.1014 20.2936C40.1014 19.4911 40.0542 18.6996 39.9623 17.9217ZM39.4262 25.4659C34.5797 26.3132 28.0184 25.988 20.207 22.0824C12.6314 18.2946 6.60187 18.3423 2.53534 19.246C1.63269 19.4465 0.820679 19.6908 0.10437 19.9487C0.102417 20.0634 0.10144 20.1784 0.10144 20.2936C0.10144 31.3393 9.05573 40.2936 20.1014 40.2936C29.3585 40.2936 37.1467 34.0045 39.4262 25.4659Z"
        class="ccustom fill-primary"
      >
      </path>
    </svg>
    """
  end

  attr(:title, :string, doc: "Card title")
  attr(:subheading, :string, doc: "Card subheading")
  attr(:body, :string, doc: "Card body")
  attr(:image, :string, doc: "Card image", required: false)

  attr(:class, :string, default: "", doc: "CSS class for card")
  attr(:rest, :global)

  def card(assigns) do
    ~H"""
    <figure
      class={[
        "relative w-64 cursor-pointer overflow-hidden rounded-xl p-4 transition-all duration-300",
        "bg-base-200 text-base-content hover:bg-base-300 hover:shadow-lg",
        @class
      ]}
      {@rest}
    >
      <div class="flex flex-row items-center gap-2">
        <.avatar name={@title} class="rounded-full" inner_class="rounded-full" />
        <div class="flex flex-col">
          <figcaption class="text-sm font-medium text-base-content">
            {@title}
          </figcaption>
          <p class="text-xs font-medium text-base-content/70">{@subheading}</p>
        </div>
      </div>
      <blockquote class="mt-2 text-sm text-base-content/80">{@body}</blockquote>
    </figure>
    """
  end

  @doc """
  Avatar component using https://avatars.dicebear.com styles.

  Can be overridden by an image URL.

  Styles available:
    Adventurer
    Adventurer Neutral
    Avataaars
    Avataaars Neutral
    Big Ears
    Big Ears Neutral
    Big Smile
    Bottts
    Bottts Neutral
    Croodles
    Croodles Neutral
    Fun Emoji
    Icons
    Identicon
    Initials
    Lorelei
    Lorelei Neutral
    Micah
    Miniavs
    Notionists
    Notionists Neutral
    Open Peeps
    Personas
    Pixel Art
    Pixel Art Neutral
    Rings
    Shapes
    Thumbs
  """

  attr(:name, :string, required: true, doc: "Name for avatar and seed for dicebear API")
  attr(:style, :string, default: "shapes", doc: "Style for dicebear API")
  attr(:img_src, :string, required: false, doc: "Image URL - overrides dicebear API")
  attr(:class, :string, default: "", doc: "CSS class for parent div")
  attr(:inner_class, :string, default: "", doc: "CSS class for inner div")
  attr(:rest, :global)

  def avatar(assigns) do
    image =
      assigns[:img_src] ||
        "https://api.dicebear.com/9.x/#{assigns[:style]}/svg?seed=#{assigns[:name]}"

    assigns = assign(assigns, :image, image)

    ~H"""
    <div class={["flex h-7 w-7 items-center", @class]} {@rest}>
      <img src={@image} alt={"#{@name}"} class={[@inner_class, "h-12 w-12 rounded-lg"]} />
    </div>
    """
  end

  attr :current_scope, :map, required: true
  attr :class, :string, default: nil

  attr :position, :string,
    default: "dropdown-right dropdown-top",
    doc: "Dropdown position classes"

  slot :inner_block, required: false
  attr :rest, :global

  def profile_dropdown(assigns) do
    ~H"""
    <div
      class={[
        "dropdown rounded-full hover:bg-base-300 transition-all p-1",
        @position,
        @class
      ]}
      {@rest}
    >
      <div tabindex="0" role="button" class="">
        <.avatar
          name={@current_scope.user.email}
          class="rounded-full border border-base-200 overflow-hidden bg-base-100 hover:bg-base-200 focus:bg-base-200 transition-colors cursor-pointer"
          inner_class="rounded-full mx-auto"
        />
      </div>
      <ul
        tabindex="0"
        class="menu dropdown-content bg-base-200 rounded-box z-1 mt-4 w-52 p-2 shadow-sm"
      >
        <li class="text-base-500 text-xs py-2 px-4">
          {@current_scope.user.email}
        </li>
        <li>
          <.link navigate="/users/settings" class="text-base-500 hover:text-primary">
            <.icon name="hero-cog-6-tooth" class="w-4 h-4" /> Settings
          </.link>
        </li>
        <li>
          <.link href="/users/log-out" method="delete" class="text-base-500 hover:text-primary">
            <.icon name="hero-arrow-right-on-rectangle" class="w-4 h-4" /> Log out
          </.link>
        </li>
        {render_slot(@inner_block)}
      </ul>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(NeptunerWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(NeptunerWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Translates Backpex strings using gettext.
  """
  def translate_backpex({msg, bindings}) do
    Gettext.dgettext(NeptunerWeb.Gettext, "backpex", msg, bindings)
  end

  def translate_backpex(msg) when is_binary(msg) do
    Gettext.dgettext(NeptunerWeb.Gettext, "backpex", msg)
  end
end
