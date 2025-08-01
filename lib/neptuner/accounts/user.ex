defmodule Neptuner.Accounts.User do
  use Neptuner.Schema
  import Ecto.Changeset

  alias Neptuner.Organisations.Organisation
  alias Neptuner.Organisations.OrganisationMember
  alias Neptuner.Tasks.Task
  alias Neptuner.Habits.Habit
  alias Neptuner.Connections.ServiceConnection
  alias Neptuner.Calendar.Meeting
  alias Neptuner.Achievements.UserAchievement

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    has_many :organisation_members, OrganisationMember
    many_to_many :organisations, Organisation, join_through: OrganisationMember

    field :is_oauth_user, :boolean, default: false
    field :oauth_provider, :string

    # Neptuner-specific fields
    field :cosmic_perspective_level, Ecto.Enum,
      values: [:skeptical, :resigned, :enlightened],
      default: :skeptical

    field :total_meaningless_tasks_completed, :integer, default: 0

    # Subscription fields
    field :subscription_tier, Ecto.Enum,
      values: [:free, :cosmic_enlightenment, :enterprise],
      default: :free

    field :subscription_status, Ecto.Enum,
      values: [:active, :cancelled, :expired, :trial],
      default: :active

    field :subscription_expires_at, :utc_datetime
    field :lemonsqueezy_customer_id, :string
    field :subscription_features, :map, default: %{}

    # Onboarding fields
    field :onboarding_completed, :boolean, default: false

    field :onboarding_step, Ecto.Enum,
      values: [
        :welcome,
        :cosmic_setup,
        :demo_data,
        :first_connection,
        :first_task,
        :dashboard_tour,
        :completed
      ],
      default: :welcome

    field :demo_data_generated, :boolean, default: false
    field :first_task_created, :boolean, default: false
    field :first_connection_made, :boolean, default: false
    field :dashboard_tour_completed, :boolean, default: false
    field :onboarding_started_at, :utc_datetime
    field :onboarding_completed_at, :utc_datetime
    field :activation_score, :integer, default: 0

    # Neptuner relationships
    has_many :tasks, Task, on_delete: :delete_all
    has_many :habits, Habit, on_delete: :delete_all
    has_many :service_connections, ServiceConnection, on_delete: :delete_all
    has_many :meetings, Meeting, on_delete: :delete_all
    has_many :user_achievements, UserAchievement, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_email` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  A user changeset for OAuth registration.

  It validates the email and oauth_provider fields and sets is_oauth_user to true.
  """
  def oauth_registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :oauth_provider])
    |> validate_required([:email, :oauth_provider])
    |> validate_email(opts)
    |> put_change(:is_oauth_user, true)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Neptuner.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  A user changeset for updating subscription information.
  """
  def subscription_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :subscription_tier,
      :subscription_status,
      :subscription_expires_at,
      :lemonsqueezy_customer_id,
      :subscription_features
    ])
    |> validate_inclusion(:subscription_tier, [:free, :cosmic_enlightenment, :enterprise])
    |> validate_inclusion(:subscription_status, [:active, :cancelled, :expired, :trial])
  end

  @doc """
  A user changeset for updating onboarding progress.
  """
  def onboarding_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :onboarding_completed,
      :onboarding_step,
      :demo_data_generated,
      :first_task_created,
      :first_connection_made,
      :dashboard_tour_completed,
      :onboarding_started_at,
      :onboarding_completed_at,
      :activation_score,
      :cosmic_perspective_level
    ])
    |> validate_inclusion(:onboarding_step, [
      :welcome,
      :cosmic_setup,
      :demo_data,
      :first_connection,
      :first_task,
      :dashboard_tour,
      :completed
    ])
    |> validate_inclusion(:cosmic_perspective_level, [:skeptical, :resigned, :enlightened])
    |> maybe_set_onboarding_timestamps()
  end

  defp maybe_set_onboarding_timestamps(changeset) do
    now = DateTime.utc_now()

    changeset =
      if get_field(changeset, :onboarding_started_at) == nil and
           get_change(changeset, :onboarding_step) do
        put_change(changeset, :onboarding_started_at, now)
      else
        changeset
      end

    if get_change(changeset, :onboarding_completed) == true and
         get_field(changeset, :onboarding_completed_at) == nil do
      put_change(changeset, :onboarding_completed_at, now)
    else
      changeset
    end
  end

  @doc """
  General changeset for user updates including subscription fields.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :cosmic_perspective_level,
      :total_meaningless_tasks_completed,
      :subscription_tier,
      :subscription_status,
      :subscription_expires_at,
      :lemonsqueezy_customer_id,
      :subscription_features,
      :onboarding_completed,
      :onboarding_step,
      :demo_data_generated,
      :first_task_created,
      :first_connection_made,
      :dashboard_tour_completed,
      :onboarding_started_at,
      :onboarding_completed_at,
      :activation_score
    ])
    |> validate_email([])
    |> validate_inclusion(:cosmic_perspective_level, [:skeptical, :resigned, :enlightened])
    |> validate_inclusion(:subscription_tier, [:free, :cosmic_enlightenment, :enterprise])
    |> validate_inclusion(:subscription_status, [:active, :cancelled, :expired, :trial])
    |> validate_inclusion(:onboarding_step, [
      :welcome,
      :cosmic_setup,
      :demo_data,
      :first_connection,
      :first_task,
      :dashboard_tour,
      :completed
    ])
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Neptuner.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
