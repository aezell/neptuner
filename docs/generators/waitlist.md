# Waitlist Generator

> **⚠️ Important Note:** This generator only works with fresh installations of the project or when manually installed using the Igniter function. Installation can only be guaranteed on fresh usage of the project.

## Overview

The Waitlist generator creates a complete waitlist system for your SaaS application, allowing you to collect potential user information before launch. It provides multiple UI components for different use cases and integrates with feature flags to toggle waitlist mode on/off.

## Installation

To generate the waitlist functionality, run:

```bash
mix neptuner.gen.waitlist
```

After generation, you'll need to:

1. Run the migration to create the database table:
```bash
mix ecto.migrate
```

2. Enable the waitlist mode feature flag:
```bash
mix run priv/repo/seeds/waitlist.exs
```

## What It Does

The generator creates and modifies the following files:

### Created Files

1. **`lib/neptuner/waitlist/entry.ex`** - Waitlist entry schema with validations
   - Stores email, name, company, role, use_case, and subscription timestamp
   - Validates email format and uniqueness
   - Automatically sets subscribed_at timestamp

2. **`lib/neptuner_web/components/waitlist_components.ex`** - UI components
   - Three different waitlist form styles
   - Helper functions for feature flag checking
   - CSRF protection integration

3. **`lib/neptuner_web/controllers/waitlist_controller.ex`** - Form submission handler
   - Processes waitlist signups
   - Provides user feedback on success/failure
   - Handles validation errors gracefully

4. **`priv/repo/migrations/[timestamp]_create_waitlist_entries.exs`** - Database migration
   - Creates waitlist_entries table with proper indexes
   - Unique constraint on email field

5. **`priv/repo/seeds/waitlist.exs`** - Feature flag setup
   - Enables waitlist_mode flag by default

### Modified Files

1. **`lib/neptuner_web/router.ex`** - Adds waitlist route
   - `POST /waitlist` route for form submissions

2. **`lib/neptuner_web/page_html.ex`** - Imports waitlist components
   - Makes waitlist components available in page templates

## Configuration

The waitlist system uses the FunWithFlags library for feature flag management:

### Enable/Disable Waitlist Mode

```elixir
# Enable waitlist mode
FunWithFlags.enable(:waitlist_mode)

# Disable waitlist mode  
FunWithFlags.disable(:waitlist_mode)

# Check if waitlist mode is enabled
FunWithFlags.enabled?(:waitlist_mode)
```

### Database Schema

The waitlist_entries table includes:
- `email` (required, unique)
- `name` (optional)
- `company` (optional)
- `role` (optional)
- `use_case` (optional, text field)
- `subscribed_at` (auto-generated)
- `inserted_at` and `updated_at` (timestamps)

## Usage

### Available Components

#### 1. Simple Waitlist Form
Basic email signup form for minimal friction:

```heex
<.simple_waitlist_form 
  title="Join the Waitlist"
  subtitle="Be the first to know when we launch"
  class="my-8"
/>
```

#### 2. Detailed Waitlist Form
Full form with additional fields for more user insights:

```heex
<.detailed_waitlist_form 
  title="Join the Waitlist"
  subtitle="Help us build something amazing for you"
  class="my-8"
/>
```

#### 3. Hero Waitlist CTA
Large, prominent call-to-action for landing pages:

```heex
<.hero_waitlist_cta 
  title="Get Early Access"
  subtitle="Join the waitlist and be among the first to experience our platform"
  class="py-16"
/>
```

### Helper Functions

#### Check Waitlist Mode Status
```elixir
# In your templates or controllers
if waitlist_mode_enabled?() do
  # Show waitlist components
else
  # Show regular content
end
```

### Form Handling

All forms submit to `POST /waitlist` and handle:
- CSRF protection automatically
- Email validation and uniqueness
- Success/error flash messages
- Redirect back to home page

## Examples

### Conditional Content Based on Waitlist Mode

```heex
<%= if waitlist_mode_enabled?() do %>
  <.hero_waitlist_cta 
    title="Coming Soon!"
    subtitle="We're building something amazing. Join the waitlist for early access."
  />
<% else %>
  <!-- Regular application content -->
  <.hero_section title="Welcome to Our SaaS" />
<% end %>
```

### Custom Waitlist Integration

```heex
<!-- In your page template -->
<div class="min-h-screen flex items-center justify-center">
  <div class="max-w-2xl mx-auto text-center">
    <h1 class="text-4xl font-bold mb-4">Revolutionary SaaS Platform</h1>
    <p class="text-xl text-gray-600 mb-8">
      Transform your business with our cutting-edge solution
    </p>
    
    <%= if waitlist_mode_enabled?() do %>
      <.detailed_waitlist_form 
        title="Get Early Access"
        subtitle="Tell us about your needs and we'll prioritize your access"
      />
    <% else %>
      <.button navigate={~p"/register"} variant="primary" size="large">
        Get Started Free
      </.button>
    <% end %>
  </div>
</div>
```

### Managing Waitlist Entries

```elixir
# In IEx or a custom admin interface
alias Neptuner.Waitlist.Entry
alias Neptuner.Repo

# Get all waitlist entries
entries = Repo.all(Entry)

# Get entries by date
recent_entries = 
  Entry
  |> where([e], e.subscribed_at >= ago(7, "day"))
  |> Repo.all()

# Get entries with company info
company_entries = 
  Entry
  |> where([e], not is_nil(e.company))
  |> Repo.all()
```

## Next Steps

After installation and setup:

1. **Customize the forms** - Modify the component attributes to match your brand
2. **Add email notifications** - Set up email alerts when new users join
3. **Create an admin interface** - Build a dashboard to manage waitlist entries
4. **A/B test different forms** - Try different copy and form styles
5. **Export functionality** - Add ability to export waitlist data
6. **Integration with email marketing** - Connect with services like Mailchimp or ConvertKit

### Advanced Customization

```elixir
# Custom validation in the Entry schema
def changeset(entry, attrs) do
  entry
  |> cast(attrs, [:email, :name, :company, :role, :use_case])
  |> validate_required([:email])
  |> validate_email_domain() # Custom validation
  |> validate_company_size() # Custom validation
  |> unique_constraint(:email)
end
```

### Feature Flag Management

```elixir
# Programmatically toggle waitlist mode
defmodule Neptuner.Admin.WaitlistManager do
  def enable_waitlist_mode do
    FunWithFlags.enable(:waitlist_mode)
  end

  def disable_waitlist_mode do
    FunWithFlags.disable(:waitlist_mode)
  end

  def waitlist_status do
    FunWithFlags.enabled?(:waitlist_mode)
  end
end
```

The waitlist system provides a professional, feature-complete solution for collecting user interest before launch, with the flexibility to customize and extend as needed.