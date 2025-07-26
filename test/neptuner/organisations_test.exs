defmodule Neptuner.OrganisationsTest do
  use Neptuner.DataCase

  alias Neptuner.Organisations
  alias Neptuner.Organisations.{OrganisationMember, OrganisationInvitation}
  alias Neptuner.Repo

  import Neptuner.Factory

  describe "get_by_user_id/1" do
    test "returns the organisation for a user" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation)

      assert Organisations.get_by_user_id(user.id) == organisation
    end

    test "returns nil when user doesn't exist" do
      fake_uuid = Ecto.UUID.generate()
      assert Organisations.get_by_user_id(fake_uuid) == nil
    end

    test "returns nil when user has no organisations" do
      user = insert(:user)
      assert Organisations.get_by_user_id(user.id) == nil
    end
  end

  describe "list_by_user_id/1" do
    test "returns all organisations for a user" do
      user = insert(:user)
      org1 = insert(:organisation, name: "Org 1")
      org2 = insert(:organisation, name: "Org 2")

      insert(:organisation_member, user: user, organisation: org1)
      insert(:organisation_member, user: user, organisation: org2)

      organisations = Organisations.list_by_user_id(user.id)
      assert length(organisations) == 2
      assert org1 in organisations
      assert org2 in organisations
    end

    test "returns empty list when user has no organisations" do
      user = insert(:user)
      assert Organisations.list_by_user_id(user.id) == []
    end
  end

  describe "create_organisation_with_owner/2" do
    test "creates organisation and adds user as owner" do
      user = insert(:user)
      attrs = %{name: "Test Organisation"}

      assert {:ok, organisation} = Organisations.create_organisation_with_owner(attrs, user)
      assert organisation.name == "Test Organisation"

      role = Organisations.get_user_role(organisation, user)
      assert role == "owner"
    end

    test "returns error with invalid organisation data" do
      user = insert(:user)
      attrs = %{name: ""}

      assert {:error, changeset} = Organisations.create_organisation_with_owner(attrs, user)
      assert %Ecto.Changeset{} = changeset
      refute changeset.valid?
    end
  end

  describe "create_organisation/1" do
    test "creates organisation with valid attributes" do
      attrs = %{name: "Test Organisation"}

      assert {:ok, organisation} = Organisations.create_organisation(attrs)
      assert organisation.name == "Test Organisation"
    end

    test "returns error with invalid attributes" do
      attrs = %{name: ""}

      assert {:error, changeset} = Organisations.create_organisation(attrs)
      refute changeset.valid?
    end
  end

  describe "change_organisation/2" do
    test "returns changeset for organisation" do
      organisation = insert(:organisation)
      changeset = Organisations.change_organisation(organisation)
      assert %Ecto.Changeset{} = changeset
    end

    test "returns changeset with attributes" do
      organisation = insert(:organisation)
      attrs = %{name: "New Name"}
      changeset = Organisations.change_organisation(organisation, attrs)
      assert changeset.changes.name == "New Name"
    end
  end

  describe "update_organisation/2" do
    test "updates organisation with valid attributes" do
      organisation = insert(:organisation)
      attrs = %{name: "Updated Name"}

      assert {:ok, updated_org} = Organisations.update_organisation(organisation, attrs)
      assert updated_org.name == "Updated Name"
    end

    test "returns error with invalid attributes" do
      organisation = insert(:organisation)
      attrs = %{name: ""}

      assert {:error, changeset} = Organisations.update_organisation(organisation, attrs)
      refute changeset.valid?
    end
  end

  describe "add_user_to_organisation/3" do
    test "adds user to organisation with default member role" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert {:ok, member} = Organisations.add_user_to_organisation(organisation, user)
      assert member.role == "member"
      assert member.user_id == user.id
      assert member.organisation_id == organisation.id
    end

    test "adds user to organisation with specified role" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert {:ok, member} = Organisations.add_user_to_organisation(organisation, user, "admin")
      assert member.role == "admin"
    end

    test "returns error with invalid role" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert {:error, changeset} =
               Organisations.add_user_to_organisation(organisation, user, "invalid")

      refute changeset.valid?
    end

    test "prevents duplicate membership" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation)

      assert {:error, changeset} = Organisations.add_user_to_organisation(organisation, user)
      refute changeset.valid?
    end
  end

  describe "get_user_role/2" do
    test "returns user role in organisation" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation, role: "admin")

      assert Organisations.get_user_role(organisation, user) == "admin"
    end

    test "returns nil when user is not a member" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert Organisations.get_user_role(organisation, user) == nil
    end
  end

  describe "can_manage_organisation?/2" do
    test "returns true for owner" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation, role: "owner")

      assert Organisations.can_manage_organisation?(organisation, user) == true
    end

    test "returns true for admin" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation, role: "admin")

      assert Organisations.can_manage_organisation?(organisation, user) == true
    end

    test "returns false for member" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation, role: "member")

      assert Organisations.can_manage_organisation?(organisation, user) == false
    end

    test "returns false for non-member" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert Organisations.can_manage_organisation?(organisation, user) == false
    end
  end

  describe "list_organisation_members/1" do
    test "returns all members with their roles and join dates" do
      organisation = insert(:organisation)
      user1 = insert(:user, email: "user1@example.com")
      user2 = insert(:user, email: "user2@example.com")

      member1 =
        insert(:organisation_member, user: user1, organisation: organisation, role: "owner")

      member2 =
        insert(:organisation_member, user: user2, organisation: organisation, role: "admin")

      members = Organisations.list_organisation_members(organisation)

      assert length(members) == 2

      owner_member = Enum.find(members, &(&1.role == "owner"))
      admin_member = Enum.find(members, &(&1.role == "admin"))

      assert owner_member.user.email == "user1@example.com"
      assert owner_member.joined_at == member1.joined_at

      assert admin_member.user.email == "user2@example.com"
      assert admin_member.joined_at == member2.joined_at
    end

    test "returns empty list for organisation with no members" do
      organisation = insert(:organisation)
      assert Organisations.list_organisation_members(organisation) == []
    end
  end

  describe "invite_user_to_organisation/4" do
    test "creates invitation for non-existing user" do
      organisation = insert(:organisation)
      inviter = insert(:user)
      attrs = %{email: "newuser@example.com", role: "member"}

      assert {:ok, invitation} =
               Organisations.invite_user_to_organisation(organisation, inviter, attrs)

      assert invitation.email == "newuser@example.com"
      assert invitation.role == "member"
      assert invitation.organisation_id == organisation.id
      assert invitation.invited_by_id == inviter.id
    end

    test "adds existing user directly to organisation" do
      organisation = insert(:organisation)
      inviter = insert(:user)
      existing_user = insert(:user, email: "existing@example.com")
      attrs = %{email: "existing@example.com", role: "admin"}

      assert {:ok, member} =
               Organisations.invite_user_to_organisation(organisation, inviter, attrs)

      assert %OrganisationMember{} = member
      assert member.user_id == existing_user.id
      assert member.role == "admin"
    end

    test "returns error when user is already a member" do
      organisation = insert(:organisation)
      inviter = insert(:user)
      existing_member = insert(:user, email: "member@example.com")
      insert(:organisation_member, user: existing_member, organisation: organisation)

      attrs = %{email: "member@example.com", role: "admin"}

      assert {:error, :already_member} =
               Organisations.invite_user_to_organisation(organisation, inviter, attrs)
    end

    test "returns error with invalid email" do
      organisation = insert(:organisation)
      inviter = insert(:user)
      attrs = %{email: "invalid-email", role: "member"}

      assert {:error, changeset} =
               Organisations.invite_user_to_organisation(organisation, inviter, attrs)

      refute changeset.valid?
    end

    test "defaults to member role when not specified" do
      organisation = insert(:organisation)
      inviter = insert(:user)
      attrs = %{email: "newuser@example.com"}

      assert {:ok, invitation} =
               Organisations.invite_user_to_organisation(organisation, inviter, attrs)

      assert invitation.role == "member"
    end
  end

  describe "get_invitation_by_token/1" do
    test "returns invitation with valid token" do
      invitation = insert(:organisation_invitation)

      found_invitation = Organisations.get_invitation_by_token(invitation.token)
      assert found_invitation.id == invitation.id
      assert found_invitation.organisation
      assert found_invitation.invited_by
    end

    test "returns nil with invalid token" do
      assert Organisations.get_invitation_by_token("invalid-token") == nil
    end

    test "returns nil with nil token" do
      assert Organisations.get_invitation_by_token(nil) == nil
    end
  end

  describe "accept_invitation/1" do
    test "accepts valid invitation and creates new user" do
      organisation = insert(:organisation)

      invitation =
        insert(:organisation_invitation,
          email: "newuser@example.com",
          role: "admin",
          organisation: organisation
        )

      assert {:ok, user} = Organisations.accept_invitation(invitation.token)
      assert user.email == "newuser@example.com"

      # Verify user was added to organisation
      role = Organisations.get_user_role(organisation, user)
      assert role == "admin"

      # Verify invitation was marked as accepted
      updated_invitation = Repo.get(OrganisationInvitation, invitation.id)
      assert updated_invitation.accepted_at
    end

    test "accepts valid invitation for existing user" do
      organisation = insert(:organisation)
      existing_user = insert(:user, email: "existing@example.com")

      invitation =
        insert(:organisation_invitation,
          email: "existing@example.com",
          role: "member",
          organisation: organisation
        )

      assert {:ok, user} = Organisations.accept_invitation(invitation.token)
      assert user.id == existing_user.id

      # Verify user was added to organisation
      role = Organisations.get_user_role(organisation, user)
      assert role == "member"
    end

    test "returns error for expired invitation" do
      invitation = insert(:expired_invitation)

      assert {:error, :invalid_or_expired} = Organisations.accept_invitation(invitation.token)
    end

    test "returns error for already accepted invitation" do
      invitation = insert(:accepted_invitation)

      assert {:error, :invalid_or_expired} = Organisations.accept_invitation(invitation.token)
    end

    test "returns error for invalid token" do
      assert {:error, :invalid_or_expired} = Organisations.accept_invitation("invalid-token")
    end
  end

  describe "update_user_role/3" do
    test "updates user role successfully" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation, role: "member")

      assert {:ok, updated_member} = Organisations.update_user_role(organisation, user, "admin")
      assert updated_member.role == "admin"
    end

    test "returns error for non-member" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert {:error, :not_a_member} = Organisations.update_user_role(organisation, user, "admin")
    end

    test "returns error with invalid role" do
      user = insert(:user)
      organisation = insert(:organisation)
      insert(:organisation_member, user: user, organisation: organisation, role: "member")

      assert {:error, changeset} = Organisations.update_user_role(organisation, user, "invalid")
      refute changeset.valid?
    end
  end

  describe "remove_user_from_organisation/2" do
    test "removes user from organisation successfully" do
      user = insert(:user)
      organisation = insert(:organisation)
      member = insert(:organisation_member, user: user, organisation: organisation)

      assert {:ok, deleted_member} =
               Organisations.remove_user_from_organisation(organisation, user)

      assert deleted_member.id == member.id

      # Verify member was actually deleted
      refute Repo.get(OrganisationMember, member.id)
    end

    test "returns error for non-member" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert {:error, :not_a_member} =
               Organisations.remove_user_from_organisation(organisation, user)
    end
  end

  describe "get_organisation_member/2" do
    test "returns organisation member for user" do
      user = insert(:user)
      organisation = insert(:organisation)
      member = insert(:organisation_member, user: user, organisation: organisation)

      found_member = Organisations.get_organisation_member(organisation, user)
      assert found_member.id == member.id
    end

    test "returns nil for non-member" do
      user = insert(:user)
      organisation = insert(:organisation)

      assert Organisations.get_organisation_member(organisation, user) == nil
    end
  end
end
