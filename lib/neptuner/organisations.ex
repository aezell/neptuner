defmodule Neptuner.Organisations do
  @moduledoc """
  The Organisations context.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo

  alias Neptuner.Accounts.User
  alias Neptuner.Organisations.Organisation
  alias Neptuner.Organisations.OrganisationMember
  alias Neptuner.Organisations.OrganisationInvitation
  alias Neptuner.Accounts.UserNotifier

  @doc """
  Gets the primary organisation for a user by user ID.

  Returns the first organisation that the specified user belongs to.
  Returns `nil` if the user doesn't exist or doesn't belong to any organisation.

  ## Examples

    iex> get_by_user_id(123)
    %Organisation{id: 1, name: "Acme Corp"}

    iex> get_by_user_id(999)
    nil

  """
  def get_by_user_id(user_id) do
    from(o in Organisation,
      join: om in OrganisationMember,
      on: o.id == om.organisation_id,
      where: om.user_id == ^user_id,
      order_by: [desc: om.inserted_at],
      limit: 1,
      select: o
    )
    |> Repo.one()
  end

  @doc """
  Gets all organisations for a user by user ID.

  Returns a list of organisations that the specified user belongs to.
  Returns an empty list if the user doesn't exist or doesn't belong to any organisation.

  ## Examples

    iex> list_by_user_id(123)
    [%Organisation{id: 1, name: "Acme Corp"}, %Organisation{id: 2, name: "Beta Inc"}]

    iex> list_by_user_id(999)
    []

  """
  def list_by_user_id(user_id) do
    from(o in Organisation,
      join: om in OrganisationMember,
      on: o.id == om.organisation_id,
      where: om.user_id == ^user_id,
      order_by: [desc: om.inserted_at],
      select: o
    )
    |> Repo.all()
  end

  @doc """
  Creates an organisation and adds the user as the owner.

  ## Examples

    iex> create_organisation_with_owner(%{name: "Acme Corp"}, user)
    {:ok, %Organisation{}}

    iex> create_organisation_with_owner(%{name: ""}, user)
    {:error, %Ecto.Changeset{}}

  """
  def create_organisation_with_owner(attrs, user) do
    Repo.transaction(fn ->
      with {:ok, organisation} <- create_organisation(attrs),
           {:ok, _member} <- add_user_to_organisation(organisation, user, "owner") do
        organisation
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates an organisation.

  ## Examples

    iex> create_organisation(%{name: "Acme Corp"})
    {:ok, %Organisation{}}

    iex> create_organisation(%{name: ""})
    {:error, %Ecto.Changeset{}}

  """
  def create_organisation(attrs \\ %{}) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organisation changes.

  ## Examples

    iex> change_organisation(organisation)
    %Ecto.Changeset{data: %Organisation{}}

  """
  def change_organisation(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end

  @doc """
  Updates an organisation.

  ## Examples

    iex> update_organisation(organisation, %{name: "New Name"})
    {:ok, %Organisation{}}

    iex> update_organisation(organisation, %{name: ""})
    {:error, %Ecto.Changeset{}}

  """
  def update_organisation(%Organisation{} = organisation, attrs) do
    organisation
    |> Organisation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Adds a user to an organisation with a specified role.

  ## Examples

    iex> add_user_to_organisation(organisation, user, "member")
    {:ok, %OrganisationMember{}}

    iex> add_user_to_organisation(organisation, user, "invalid_role")
    {:error, %Ecto.Changeset{}}

  """
  def add_user_to_organisation(organisation, user, role \\ "member") do
    %OrganisationMember{}
    |> OrganisationMember.changeset(%{
      organisation_id: organisation.id,
      user_id: user.id,
      role: role
    })
    |> Repo.insert()
  end

  @doc """
  Gets the user's role in an organisation.

  Returns the role string or nil if the user is not a member.

  ## Examples

    iex> get_user_role(organisation, user)
    "owner"

    iex> get_user_role(organisation, non_member_user)
    nil

  """
  def get_user_role(organisation, user) do
    from(om in OrganisationMember,
      where: om.organisation_id == ^organisation.id and om.user_id == ^user.id,
      select: om.role
    )
    |> Repo.one()
  end

  @doc """
  Checks if a user can manage an organisation (admin or owner role).

  ## Examples

    iex> can_manage_organisation?(organisation, owner_user)
    true

    iex> can_manage_organisation?(organisation, member_user)
    false

  """
  def can_manage_organisation?(organisation, user) do
    role = get_user_role(organisation, user)
    role in ["admin", "owner"]
  end

  @doc """
  Gets all members of an organisation with their roles.

  ## Examples

    iex> list_organisation_members(organisation)
    [%{user: %User{}, role: "owner", joined_at: ~U[...]}]

  """
  def list_organisation_members(organisation) do
    from(om in OrganisationMember,
      join: u in User,
      on: om.user_id == u.id,
      where: om.organisation_id == ^organisation.id,
      order_by: [desc: om.inserted_at],
      select: %{user: u, role: om.role, joined_at: om.joined_at}
    )
    |> Repo.all()
  end

  ## Organisation Invitations

  @doc """
  Creates an organisation invitation and sends an email.

  ## Examples

    iex> invite_user_to_organisation(organisation, inviter, %{email: "user@example.com", role: "member"}, url_fun)
    {:ok, %OrganisationInvitation{}}

    iex> invite_user_to_organisation(organisation, inviter, %{email: "invalid", role: "member"}, url_fun)
    {:error, %Ecto.Changeset{}}

  """
  def invite_user_to_organisation(organisation, inviter, attrs, url_fun \\ nil) do
    # Check if user is already a member
    case get_user_by_email(attrs["email"] || attrs[:email]) do
      %User{} = user ->
        if get_user_role(organisation, user) do
          {:error, :already_member}
        else
          # User exists but not a member, add them directly
          add_user_to_organisation(organisation, user, attrs["role"] || attrs[:role] || "member")
        end

      nil ->
        # User doesn't exist, create invitation
        create_and_send_invitation(organisation, inviter, attrs, url_fun)
    end
  end

  defp get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  defp get_user_by_email(_), do: nil

  defp create_and_send_invitation(organisation, inviter, attrs, url_fun) do
    invitation_attrs =
      attrs
      |> Map.put(:organisation_id, organisation.id)
      |> Map.put(:invited_by_id, inviter.id)

    changeset = OrganisationInvitation.changeset(%OrganisationInvitation{}, invitation_attrs)

    case Repo.insert(changeset) do
      {:ok, invitation} ->
        # Send invitation email if url_fun is provided
        if url_fun do
          UserNotifier.deliver_organisation_invitation(
            invitation,
            organisation,
            inviter,
            url_fun
          )
        end

        {:ok, invitation}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Gets an organisation invitation by token.

  ## Examples

    iex> get_invitation_by_token("valid_token")
    %OrganisationInvitation{}

    iex> get_invitation_by_token("invalid_token")
    nil

  """
  def get_invitation_by_token(token) when is_binary(token) do
    from(i in OrganisationInvitation,
      where: i.token == ^token,
      preload: [:organisation, :invited_by]
    )
    |> Repo.one()
  end

  def get_invitation_by_token(_), do: nil

  @doc """
  Accepts an organisation invitation and creates/adds the user.

  ## Examples

    iex> accept_invitation("valid_token")
    {:ok, %User{}}

    iex> accept_invitation("expired_token")
    {:error, :invalid_or_expired}

  """
  def accept_invitation(token) when is_binary(token) do
    case get_invitation_by_token(token) do
      %OrganisationInvitation{} = invitation ->
        if OrganisationInvitation.valid?(invitation) do
          process_invitation_acceptance(invitation)
        else
          {:error, :invalid_or_expired}
        end

      nil ->
        {:error, :invalid_or_expired}
    end
  end

  defp process_invitation_acceptance(invitation) do
    Repo.transaction(fn ->
      # Check if user already exists
      case get_user_by_email(invitation.email) do
        %User{} = user ->
          # User exists, just add to organisation
          case add_user_to_organisation(invitation.organisation, user, invitation.role) do
            {:ok, _member} ->
              mark_invitation_accepted(invitation)
              user

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        nil ->
          # User doesn't exist, create them
          case create_user_from_invitation(invitation) do
            {:ok, user} ->
              case add_user_to_organisation(invitation.organisation, user, invitation.role) do
                {:ok, _member} ->
                  mark_invitation_accepted(invitation)
                  user

                {:error, changeset} ->
                  Repo.rollback(changeset)
              end

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
      end
    end)
  end

  defp create_user_from_invitation(invitation) do
    # Create user with no password set (follows the magic link pattern)
    %User{}
    |> User.email_changeset(%{email: invitation.email})
    |> Repo.insert()
  end

  defp mark_invitation_accepted(invitation) do
    invitation
    |> OrganisationInvitation.accept_changeset()
    |> Repo.update!()
  end

  @doc """
  Updates a user's role in an organisation.

  ## Examples

    iex> update_user_role(organisation, user, "admin")
    {:ok, %OrganisationMember{}}

    iex> update_user_role(organisation, user, "invalid_role")
    {:error, %Ecto.Changeset{}}

  """
  def update_user_role(organisation, user, new_role) do
    case get_organisation_member(organisation, user) do
      %OrganisationMember{} = member ->
        member
        |> OrganisationMember.changeset(%{role: new_role})
        |> Repo.update()

      nil ->
        {:error, :not_a_member}
    end
  end

  @doc """
  Removes a user from an organisation.

  ## Examples

    iex> remove_user_from_organisation(organisation, user)
    {:ok, %OrganisationMember{}}

    iex> remove_user_from_organisation(organisation, non_member_user)
    {:error, :not_a_member}

  """
  def remove_user_from_organisation(organisation, user) do
    case get_organisation_member(organisation, user) do
      %OrganisationMember{} = member ->
        Repo.delete(member)

      nil ->
        {:error, :not_a_member}
    end
  end

  @doc """
  Gets the organisation member record for a user.

  ## Examples

    iex> get_organisation_member(organisation, user)
    %OrganisationMember{}

    iex> get_organisation_member(organisation, non_member_user)
    nil

  """
  def get_organisation_member(organisation, user) do
    from(om in OrganisationMember,
      where: om.organisation_id == ^organisation.id and om.user_id == ^user.id
    )
    |> Repo.one()
  end
end
