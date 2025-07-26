defmodule Neptuner.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `Neptuner.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias Neptuner.Accounts.User
  alias Neptuner.Organisations.Organisation

  defstruct user: nil, organisation: nil, organisation_role: nil

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  def put_organisation(%__MODULE__{} = scope, %Organisation{} = organisation) do
    %{scope | organisation: organisation}
  end

  def put_organisation(%__MODULE__{} = scope, %Organisation{} = _organisation, nil) do
    scope
  end

  def put_organisation(%__MODULE__{} = scope, %Organisation{} = organisation, role)
      when is_binary(role) do
    %{scope | organisation: organisation, organisation_role: role}
  end

  @doc """
  Checks if the current scope can manage the organisation (admin or owner).
  """
  def can_manage_organisation?(%__MODULE__{organisation_role: role})
      when role in ["admin", "owner"],
      do: true

  def can_manage_organisation?(_), do: false

  @doc """
  Checks if the current scope is an organisation owner.
  """
  def is_organisation_owner?(%__MODULE__{organisation_role: "owner"}), do: true
  def is_organisation_owner?(_), do: false

  @doc """
  Checks if the current scope is an organisation admin.
  """
  def is_organisation_admin?(%__MODULE__{organisation_role: "admin"}), do: true
  def is_organisation_admin?(_), do: false

  @doc """
  Checks if the current scope is a regular member.
  """
  def is_organisation_member?(%__MODULE__{organisation_role: "member"}), do: true
  def is_organisation_member?(_), do: false
end
