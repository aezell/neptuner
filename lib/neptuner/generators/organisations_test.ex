defmodule Mix.Tasks.Neptuner.Gen.OrganisationsTest do
  @moduledoc """
  Generates comprehensive tests for the organisations functionality created by the organisations generator.

  This task creates:
  - Test files for Organisation, OrganisationMember, and OrganisationInvitation schemas
  - Test files for the Organisations context module
  - Test files for LiveView components (new, manage, invitation)
  - Test files for UserAuth organisation functionality
  - Test files for Scope organisation functionality
  - Updated factory with organisation fixtures
  - Updated registration tests with organisation handling

      $ mix neptuner.gen.organisations_test

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _} = OptionParser.parse!(igniter.args.argv, switches: [yes: :boolean])

    igniter =
      igniter
      # Schema tests
      |> create_organisation_schema_test()
      |> create_organisation_member_schema_test()
      |> create_organisation_invitation_schema_test()
      # Context tests
      |> create_organisations_context_test()
      # LiveView tests
      |> create_organisations_live_new_test()
      |> create_organisations_live_manage_test()
      |> create_organisations_live_invitation_test()
      # Auth tests
      |> create_user_auth_test()
      |> create_scope_test()
      # Factory and fixtures
      |> update_factory()
      |> create_organisations_fixtures()

    if opts[:yes] do
      igniter
    else
      print_completion_notice(igniter)
    end
  end

  # Placeholder functions - will be implemented based on your diffs
  defp create_organisation_schema_test(igniter) do
    # TODO: Implement when you provide the diff
    igniter
  end

  defp create_organisation_member_schema_test(igniter) do
    # TODO: Implement when you provide the diff
    igniter
  end

  defp create_organisation_invitation_schema_test(igniter) do
    # TODO: Implement when you provide the diff
    igniter
  end

  defp create_organisations_context_test(igniter) do
    organisations_test_content = """
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

          assert {:error, changeset} = Organisations.add_user_to_organisation(organisation, user, "invalid")
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

          member1 = insert(:organisation_member, user: user1, organisation: organisation, role: "owner")
          member2 = insert(:organisation_member, user: user2, organisation: organisation, role: "admin")

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

          assert {:ok, invitation} = Organisations.invite_user_to_organisation(organisation, inviter, attrs)
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

          assert {:ok, member} = Organisations.invite_user_to_organisation(organisation, inviter, attrs)
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

          assert {:error, :already_member} = Organisations.invite_user_to_organisation(organisation, inviter, attrs)
        end

        test "returns error with invalid email" do
          organisation = insert(:organisation)
          inviter = insert(:user)
          attrs = %{email: "invalid-email", role: "member"}

          assert {:error, changeset} = Organisations.invite_user_to_organisation(organisation, inviter, attrs)
          refute changeset.valid?
        end

        test "defaults to member role when not specified" do
          organisation = insert(:organisation)
          inviter = insert(:user)
          attrs = %{email: "newuser@example.com"}

          assert {:ok, invitation} = Organisations.invite_user_to_organisation(organisation, inviter, attrs)
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
          invitation = insert(:organisation_invitation,
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
          invitation = insert(:organisation_invitation,
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

          assert {:ok, deleted_member} = Organisations.remove_user_from_organisation(organisation, user)
          assert deleted_member.id == member.id

          # Verify member was actually deleted
          refute Repo.get(OrganisationMember, member.id)
        end

        test "returns error for non-member" do
          user = insert(:user)
          organisation = insert(:organisation)

          assert {:error, :not_a_member} = Organisations.remove_user_from_organisation(organisation, user)
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
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner/organisations_test.exs",
      organisations_test_content
    )
  end

  defp create_organisations_live_new_test(igniter) do
    new_test_content = """
    defmodule NeptunerWeb.OrganisationsLive.NewTest do
      use NeptunerWeb.ConnCase

      import Phoenix.LiveViewTest
      import Neptuner.Factory

      describe "access control" do
        test "requires authentication", %{conn: conn} do
          assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/organisations/new")
        end

        test "loads page for authenticated user", %{conn: conn} do
          user = insert(:user)
          conn = log_in_user(conn, user)

          {:ok, view, html} = live(conn, ~p"/organisations/new")

          assert html =~ "Create your organisation"
          assert html =~ "Organisation Name"
          assert has_element?(view, "input[name=\\"organisation[name]\\"]")
          assert has_element?(view, "button", "Create Organisation")
        end
      end

      describe "form behavior" do
        test "can create organisation with valid data", %{conn: conn} do
          user = insert(:user)
          conn = log_in_user(conn, user)

          {:ok, view, _html} = live(conn, ~p"/organisations/new")

          view
          |> form("#organisation_form", organisation: %{name: "New Organisation"})
          |> render_submit()

          assert_redirected(view, "/dashboard")

          # Verify organisation was created and user is owner
          organisation = Neptuner.Organisations.get_by_user_id(user.id)
          assert organisation.name == "New Organisation"
          assert Neptuner.Organisations.get_user_role(organisation, user) == "owner"
        end

        test "shows validation errors with invalid data", %{conn: conn} do
          user = insert(:user)
          conn = log_in_user(conn, user)

          {:ok, view, _html} = live(conn, ~p"/organisations/new")

          view
          |> form("#organisation_form", organisation: %{name: ""})
          |> render_submit()

          assert render(view) =~ "can&#39;t be blank"
          refute_redirected(view)
        end

        test "validates form on change", %{conn: conn} do
          user = insert(:user)
          conn = log_in_user(conn, user)

          {:ok, view, _html} = live(conn, ~p"/organisations/new")

          view
          |> form("#organisation_form", organisation: %{name: ""})
          |> render_change()

          # Form should still be present for continued editing
          assert has_element?(view, "form#organisation_form")
        end
      end

      describe "edge cases" do
        test "handles unicode characters in organisation name", %{conn: conn} do
          user = insert(:user)
          conn = log_in_user(conn, user)

          {:ok, view, _html} = live(conn, ~p"/organisations/new")

          view
          |> form("#organisation_form", organisation: %{name: "Ørgánisätíon 企业"})
          |> render_submit()

          assert_redirected(view, "/dashboard")

          organisation = Neptuner.Organisations.get_by_user_id(user.id)
          assert organisation.name == "Ørgánisätíon 企业"
        end

        test "handles special characters in organisation name", %{conn: conn} do
          user = insert(:user)
          conn = log_in_user(conn, user)

          {:ok, view, _html} = live(conn, ~p"/organisations/new")

          view
          |> form("#organisation_form", organisation: %{name: "Acme & Co. (2024)"})
          |> render_submit()

          assert_redirected(view, "/dashboard")

          organisation = Neptuner.Organisations.get_by_user_id(user.id)
          assert organisation.name == "Acme & Co. (2024)"
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner_web/live/organisations_live/new_test.exs",
      new_test_content
    )
  end

  defp create_organisations_live_manage_test(igniter) do
    manage_test_content = """
    defmodule NeptunerWeb.OrganisationsLive.ManageTest do
      use NeptunerWeb.ConnCase

      import Phoenix.LiveViewTest
      import Neptuner.Factory

      describe "access control" do
        test "requires authentication", %{conn: conn} do
          assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/organisations/manage")
        end

        test "requires user to have organisation", %{conn: conn} do
          user = insert(:user)
          conn = log_in_user(conn, user)

          assert {:error, {:redirect, %{to: "/organisations/new"}}} =
                   live(conn, ~p"/organisations/manage")
        end

        test "allows organisation members to access", %{conn: conn} do
          user = insert(:user)
          organisation = insert(:organisation, name: "Test Org")
          insert(:organisation_member, user: user, organisation: organisation, role: "member")

          conn = log_in_user(conn, user)
          {:ok, _view, html} = live(conn, ~p"/organisations/manage")

          assert html =~ "Organisation Settings"
          assert html =~ "Test Org"
        end
      end

      describe "role-based display" do
        test "shows management options for owners", %{conn: conn} do
          user = insert(:user)
          organisation = insert(:organisation, name: "Owner Org")
          insert(:organisation_member, user: user, organisation: organisation, role: "owner")

          conn = log_in_user(conn, user)
          {:ok, _view, html} = live(conn, ~p"/organisations/manage")

          assert html =~ "Owner Org"
          assert html =~ "Owner"
          assert html =~ "Edit Organisation"
          assert html =~ "Invite Member"
        end

        test "shows management options for admins", %{conn: conn} do
          user = insert(:user)
          organisation = insert(:organisation, name: "Admin Org")
          insert(:organisation_member, user: user, organisation: organisation, role: "admin")

          conn = log_in_user(conn, user)
          {:ok, _view, html} = live(conn, ~p"/organisations/manage")

          assert html =~ "Admin Org"
          assert html =~ "Admin"
          assert html =~ "Edit Organisation"
          assert html =~ "Invite Member"
        end

        test "hides management options for members", %{conn: conn} do
          user = insert(:user)
          organisation = insert(:organisation, name: "Member Org")
          insert(:organisation_member, user: user, organisation: organisation, role: "member")

          conn = log_in_user(conn, user)
          {:ok, _view, html} = live(conn, ~p"/organisations/manage")

          assert html =~ "Member Org"
          assert html =~ "Member"
          refute html =~ "Edit Organisation"
          refute html =~ "Invite Member"
        end
      end

      describe "team members display" do
        test "displays all organisation members with their roles", %{conn: conn} do
          user = insert(:user, email: "owner@test.com")
          organisation = insert(:organisation)
          member_user = insert(:user, email: "member@test.com")
          admin_user = insert(:user, email: "admin@test.com")

          insert(:organisation_member, user: user, organisation: organisation, role: "owner")
          insert(:organisation_member, user: member_user, organisation: organisation, role: "member")
          insert(:organisation_member, user: admin_user, organisation: organisation, role: "admin")

          conn = log_in_user(conn, user)
          {:ok, _view, html} = live(conn, ~p"/organisations/manage")

          assert html =~ "owner@test.com"
          assert html =~ "member@test.com"
          assert html =~ "admin@test.com"
          assert html =~ "Owner"
          assert html =~ "Member"
          assert html =~ "Admin"
        end

        test "shows action buttons for managers", %{conn: conn} do
          user = insert(:user, email: "owner@test.com")
          organisation = insert(:organisation)
          member_user = insert(:user, email: "member@test.com")

          insert(:organisation_member, user: user, organisation: organisation, role: "owner")
          insert(:organisation_member, user: member_user, organisation: organisation, role: "member")

          conn = log_in_user(conn, user)
          {:ok, view, _html} = live(conn, ~p"/organisations/manage")

          # Should see action buttons for members (but not for self)
          assert has_element?(
                   view,
                   "button[phx-click=\\"change_role\\"][phx-value-user-id=\\"\#{member_user.id}\\"]"
                 )

          assert has_element?(
                   view,
                   "button[phx-click=\\"remove_member\\"][phx-value-user-id=\\"\#{member_user.id}\\"]"
                 )

          # Should not see action buttons for self
          refute has_element?(
                   view,
                   "button[phx-click=\\"change_role\\"][phx-value-user-id=\\"\#{user.id}\\"]"
                 )

          refute has_element?(
                   view,
                   "button[phx-click=\\"remove_member\\"][phx-value-user-id=\\"\#{user.id}\\"]"
                 )
        end

        test "hides action buttons for regular members", %{conn: conn} do
          user = insert(:user, email: "member@test.com")
          organisation = insert(:organisation)
          other_user = insert(:user, email: "other@test.com")

          insert(:organisation_member, user: user, organisation: organisation, role: "member")
          insert(:organisation_member, user: other_user, organisation: organisation, role: "member")

          conn = log_in_user(conn, user)
          {:ok, view, _html} = live(conn, ~p"/organisations/manage")

          # Should not see any action buttons
          refute has_element?(view, "button[phx-click=\\"change_role\\"]")
          refute has_element?(view, "button[phx-click=\\"remove_member\\"]")
        end
      end

      describe "basic interactions" do
        test "can trigger edit organisation modal", %{conn: conn} do
          user = insert(:user)
          organisation = insert(:organisation, name: "Test Org")
          insert(:organisation_member, user: user, organisation: organisation, role: "owner")

          conn = log_in_user(conn, user)
          {:ok, view, _html} = live(conn, ~p"/organisations/manage")

          view |> element("button", "Edit Organisation") |> render_click()

          assert render(view) =~ "Edit Organisation"
          assert has_element?(view, "input[name=\\"organisation[name]\\"]")
        end

        test "can trigger invite member modal", %{conn: conn} do
          user = insert(:user)
          organisation = insert(:organisation, name: "Test Org")
          insert(:organisation_member, user: user, organisation: organisation, role: "owner")

          conn = log_in_user(conn, user)
          {:ok, view, _html} = live(conn, ~p"/organisations/manage")

          view |> element("button", "Invite Member") |> render_click()

          assert render(view) =~ "Invite Team Member"
          assert has_element?(view, "input[name=\\"invite[email]\\"]")
          assert has_element?(view, "select[name=\\"invite[role]\\"]")
        end

        test "member cannot trigger management actions", %{conn: conn} do
          user = insert(:user)
          organisation = insert(:organisation)
          insert(:organisation_member, user: user, organisation: organisation, role: "member")

          conn = log_in_user(conn, user)
          {:ok, view, _html} = live(conn, ~p"/organisations/manage")

          result = view |> render_click("edit_organisation")
          assert result =~ "permission"

          result = view |> render_click("show_invite_modal")
          assert result =~ "permission"
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner_web/live/organisations_live/manage_test.exs",
      manage_test_content
    )
  end

  defp create_organisations_live_invitation_test(igniter) do
    invitation_test_content = """
    defmodule NeptunerWeb.OrganisationsLive.InvitationTest do
      use NeptunerWeb.ConnCase

      import Phoenix.LiveViewTest
      import Neptuner.Factory

      describe "valid invitations" do
        test "displays invitation details for new user", %{conn: conn} do
          organisation = insert(:organisation, name: "Test Org")
          inviter = insert(:user, email: "inviter@test.com")

          invitation =
            insert(:organisation_invitation,
              email: "newuser@test.com",
              role: "member",
              organisation: organisation,
              invited_by: inviter
            )

          {:ok, _view, html} = live(conn, ~p"/invitations/accept/\#{invitation.token}")

          assert html =~ "Test Org"
          assert html =~ "newuser@test.com"
          assert html =~ "inviter@test.com"
          assert html =~ "member"
        end

        test "displays invitation details for existing user", %{conn: conn} do
          _existing_user = insert(:user, email: "existing@test.com")
          organisation = insert(:organisation, name: "Existing Org")
          inviter = insert(:user, email: "inviter@test.com")

          invitation =
            insert(:organisation_invitation,
              email: "existing@test.com",
              role: "admin",
              organisation: organisation,
              invited_by: inviter
            )

          {:ok, _view, html} = live(conn, ~p"/invitations/accept/\#{invitation.token}")

          assert html =~ "Existing Org"
          assert html =~ "existing@test.com"
          assert html =~ "admin"
          assert html =~ "Accept Invitation"
          refute html =~ "Create Account"
        end
      end

      describe "invalid invitations" do
        test "shows error for non-existent token", %{conn: conn} do
          {:ok, _view, html} = live(conn, ~p"/invitations/accept/invalid-token")

          assert html =~ "Invalid Invitation"
          assert html =~ "invalid, expired, or has already been used"
        end

        test "shows error for expired invitation", %{conn: conn} do
          invitation = insert(:expired_invitation)

          {:ok, _view, html} = live(conn, ~p"/invitations/accept/\#{invitation.token}")

          assert html =~ "Invalid Invitation"
          assert html =~ "invalid, expired, or has already been used"
        end

        test "shows error for already accepted invitation", %{conn: conn} do
          invitation = insert(:accepted_invitation)

          {:ok, _view, html} = live(conn, ~p"/invitations/accept/\#{invitation.token}")

          assert html =~ "Invalid Invitation"
          assert html =~ "invalid, expired, or has already been used"
        end
      end

      describe "acceptance flow" do
        test "can accept invitation for new user", %{conn: conn} do
          organisation = insert(:organisation, name: "New User Org")

          invitation =
            insert(:organisation_invitation,
              email: "newuser@test.com",
              role: "admin",
              organisation: organisation
            )

          {:ok, view, _html} = live(conn, ~p"/invitations/accept/\#{invitation.token}")

          view |> element("button", "Accept Invitation") |> render_click()

          assert_redirected(view, "/users/log-in")

          # Verify user was created
          user = Neptuner.Accounts.get_user_by_email("newuser@test.com")
          assert user

          # Verify user was added to organisation with correct role
          role = Neptuner.Organisations.get_user_role(organisation, user)
          assert role == "admin"

          # Verify invitation was marked as accepted
          updated_invitation =
            Neptuner.Repo.get(Neptuner.Organisations.OrganisationInvitation, invitation.id)

          assert updated_invitation.accepted_at
        end

        test "can accept invitation for existing user", %{conn: conn} do
          existing_user = insert(:user, email: "existing@test.com")
          organisation = insert(:organisation, name: "Existing User Org")

          invitation =
            insert(:organisation_invitation,
              email: "existing@test.com",
              role: "member",
              organisation: organisation
            )

          {:ok, view, _html} = live(conn, ~p"/invitations/accept/\#{invitation.token}")

          view |> element("button", "Accept Invitation") |> render_click()

          assert_redirected(view, "/users/log-in")

          # Verify user was added to organisation
          role = Neptuner.Organisations.get_user_role(organisation, existing_user)
          assert role == "member"

          # Verify invitation was marked as accepted
          updated_invitation =
            Neptuner.Repo.get(Neptuner.Organisations.OrganisationInvitation, invitation.id)

          assert updated_invitation.accepted_at
        end

        test "handles user already being a member", %{conn: conn} do
          existing_user = insert(:user, email: "member@test.com")
          organisation = insert(:organisation)
          insert(:organisation_member, user: existing_user, organisation: organisation)

          invitation =
            insert(:organisation_invitation,
              email: "member@test.com",
              organisation: organisation
            )

          {:ok, view, _html} = live(conn, ~p"/invitations/accept/\#{invitation.token}")

          view |> element("button", "Accept Invitation") |> render_click()

          assert render(view) =~ "already a member"
          refute_redirected(view)
        end
      end
    end
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner_web/live/organisations_live/invitation_test.exs",
      invitation_test_content
    )
  end

  defp create_user_auth_test(igniter) do
    Igniter.update_file(igniter, "test/neptuner_web/user_auth_test.exs", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "assign_org_to_scope/2") do
        # UserAuth tests already updated
        source
      else
        # Add Factory import after AccountsFixtures import
        content_with_factory =
          String.replace(
            content,
            "  import Neptuner.AccountsFixtures",
            "  import Neptuner.AccountsFixtures\n  import Neptuner.Factory"
          )

        # Add organisation tests before the final 'end'
        org_tests = """

          describe "assign_org_to_scope/2" do
            test "assigns organisation to scope when user has organisation", %{conn: conn} do
              user = insert(:user)
              organisation = insert(:organisation)
              insert(:organisation_member, user: user, organisation: organisation, role: "admin")

              scope = Scope.for_user(user)
              conn = assign(conn, :current_scope, scope)

              updated_conn = UserAuth.assign_org_to_scope(conn, [])
              updated_scope = updated_conn.assigns.current_scope

              assert updated_scope.organisation.id == organisation.id
              assert updated_scope.organisation_role == "admin"
            end

            test "does not modify scope when user has no organisation", %{conn: conn} do
              user = insert(:user)
              scope = Scope.for_user(user)
              conn = assign(conn, :current_scope, scope)

              updated_conn = UserAuth.assign_org_to_scope(conn, [])
              updated_scope = updated_conn.assigns.current_scope

              assert updated_scope.organisation == nil
              assert updated_scope.organisation_role == nil
            end

            test "does not modify conn when no current_scope", %{conn: conn} do
              conn = assign(conn, :current_scope, nil)
              updated_conn = UserAuth.assign_org_to_scope(conn, [])
              assert updated_conn == conn
            end
          end

          describe "on_mount :assign_org_to_scope" do
            test "assigns organisation to scope in LiveView" do
              user = insert(:user)
              organisation = insert(:organisation)
              insert(:organisation_member, user: user, organisation: organisation, role: "owner")

              scope = Scope.for_user(user)
              socket = %Phoenix.LiveView.Socket{assigns: %{current_scope: scope, __changed__: %{}}}

              {:cont, updated_socket} = UserAuth.on_mount(:assign_org_to_scope, %{}, %{}, socket)
              updated_scope = updated_socket.assigns.current_scope

              assert updated_scope.organisation.id == organisation.id
              assert updated_scope.organisation_role == "owner"
            end

            test "does not modify scope when user has no organisation" do
              user = insert(:user)
              scope = Scope.for_user(user)
              socket = %Phoenix.LiveView.Socket{assigns: %{current_scope: scope, __changed__: %{}}}

              {:cont, updated_socket} = UserAuth.on_mount(:assign_org_to_scope, %{}, %{}, socket)
              updated_scope = updated_socket.assigns.current_scope

              assert updated_scope.organisation == nil
              assert updated_scope.organisation_role == nil
            end

            test "does not modify socket when organisation already assigned" do
              user = insert(:user)
              organisation = insert(:organisation)
              scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")
              socket = %Phoenix.LiveView.Socket{assigns: %{current_scope: scope, __changed__: %{}}}

              {:cont, updated_socket} = UserAuth.on_mount(:assign_org_to_scope, %{}, %{}, socket)

              # Since scope already has organisation, it should remain unchanged
              assert updated_socket.assigns.current_scope == scope
            end
          end

          describe "on_mount :require_organisation" do
            test "continues when user has organisation" do
              user = insert(:user)
              organisation = insert(:organisation)
              scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")
              socket = %Phoenix.LiveView.Socket{assigns: %{current_scope: scope}}

              assert {:cont, ^socket} = UserAuth.on_mount(:require_organisation, %{}, %{}, socket)
            end

            test "halts and redirects when user has no organisation" do
              user = insert(:user)
              scope = Scope.for_user(user)
              socket = %Phoenix.LiveView.Socket{
                endpoint: NeptunerWeb.Endpoint,
                assigns: %{current_scope: scope, __changed__: %{}, flash: %{}}
              }

              {:halt, updated_socket} = UserAuth.on_mount(:require_organisation, %{}, %{}, socket)

              assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
                "You must create or join an organisation to access this page."
              assert {:redirect, %{to: "/organisations/new"}} = updated_socket.redirected
            end
          end

          describe "on_mount :require_organisation_member" do
            test "continues when user is organisation member" do
              user = insert(:user)
              organisation = insert(:organisation)
              insert(:organisation_member, user: user, organisation: organisation, role: "member")

              scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")
              socket = %Phoenix.LiveView.Socket{assigns: %{current_scope: scope}}

              assert {:cont, ^socket} = UserAuth.on_mount(:require_organisation_member, %{}, %{}, socket)
            end

            test "halts and redirects when user has no organisation" do
              user = insert(:user)
              scope = Scope.for_user(user)
              socket = %Phoenix.LiveView.Socket{
                endpoint: NeptunerWeb.Endpoint,
                assigns: %{current_scope: scope, __changed__: %{}, flash: %{}}
              }

              {:halt, updated_socket} = UserAuth.on_mount(:require_organisation_member, %{}, %{}, socket)

              assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) == "Organisation not found."
              assert {:redirect, %{to: "/dashboard"}} = updated_socket.redirected
            end

            test "halts and redirects when user is not a member of the organisation" do
              user = insert(:user)
              organisation = insert(:organisation)
              # Don't create a membership, so get_user_role will return nil
              scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")
              socket = %Phoenix.LiveView.Socket{
                endpoint: NeptunerWeb.Endpoint,
                assigns: %{current_scope: scope, __changed__: %{}, flash: %{}}
              }

              {:halt, updated_socket} = UserAuth.on_mount(:require_organisation_member, %{}, %{}, socket)

              assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
                "You are not a member of this organisation."
              assert {:redirect, %{to: "/dashboard"}} = updated_socket.redirected
            end
          end
        """

        # Add the tests before the final 'end'
        updated_content =
          String.replace(
            content_with_factory,
            ~r/(\n  end\n)$/,
            org_tests <> "\\1"
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_scope_test(igniter) do
    scope_test_content = """
      defmodule Neptuner.Accounts.ScopeTest do
        use Neptuner.DataCase

        alias Neptuner.Accounts.Scope

        import Neptuner.Factory

        describe "for_user/1" do
          test "creates scope for valid user" do
            user = insert(:user)
            scope = Scope.for_user(user)

            assert scope.user == user
            assert scope.organisation == nil
            assert scope.organisation_role == nil
          end

          test "returns nil for nil user" do
            assert Scope.for_user(nil) == nil
          end
        end

        describe "put_organisation/2" do
          test "adds organisation to scope without role" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user)

            updated_scope = Scope.put_organisation(scope, organisation)

            assert updated_scope.user == user
            assert updated_scope.organisation == organisation
            assert updated_scope.organisation_role == nil
          end
        end

        describe "put_organisation/3" do
          test "adds organisation and role to scope" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user)

            updated_scope = Scope.put_organisation(scope, organisation, "admin")

            assert updated_scope.user == user
            assert updated_scope.organisation == organisation
            assert updated_scope.organisation_role == "admin"
          end

          test "handles owner role" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user)

            updated_scope = Scope.put_organisation(scope, organisation, "owner")

            assert updated_scope.organisation_role == "owner"
          end

          test "handles member role" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user)

            updated_scope = Scope.put_organisation(scope, organisation, "member")

            assert updated_scope.organisation_role == "member"
          end
        end

        describe "can_manage_organisation?/1" do
          test "returns true for owner" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "owner")

            assert Scope.can_manage_organisation?(scope) == true
          end

          test "returns true for admin" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "admin")

            assert Scope.can_manage_organisation?(scope) == true
          end

          test "returns false for member" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")

            assert Scope.can_manage_organisation?(scope) == false
          end

          test "returns false for nil role" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, nil)

            assert Scope.can_manage_organisation?(scope) == false
          end

          test "returns false for scope without organisation" do
            user = insert(:user)
            scope = Scope.for_user(user)

            assert Scope.can_manage_organisation?(scope) == false
          end

          test "returns false for nil scope" do
            assert Scope.can_manage_organisation?(nil) == false
          end
        end

        describe "is_organisation_owner?/1" do
          test "returns true for owner" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "owner")

            assert Scope.is_organisation_owner?(scope) == true
          end

          test "returns false for admin" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "admin")

            assert Scope.is_organisation_owner?(scope) == false
          end

          test "returns false for member" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")

            assert Scope.is_organisation_owner?(scope) == false
          end

          test "returns false for nil role" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, nil)

            assert Scope.is_organisation_owner?(scope) == false
          end

          test "returns false for scope without organisation" do
            user = insert(:user)
            scope = Scope.for_user(user)

            assert Scope.is_organisation_owner?(scope) == false
          end

          test "returns false for nil scope" do
            assert Scope.is_organisation_owner?(nil) == false
          end
        end

        describe "is_organisation_admin?/1" do
          test "returns true for admin" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "admin")

            assert Scope.is_organisation_admin?(scope) == true
          end

          test "returns false for owner" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "owner")

            assert Scope.is_organisation_admin?(scope) == false
          end

          test "returns false for member" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")

            assert Scope.is_organisation_admin?(scope) == false
          end

          test "returns false for nil role" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, nil)

            assert Scope.is_organisation_admin?(scope) == false
          end

          test "returns false for scope without organisation" do
            user = insert(:user)
            scope = Scope.for_user(user)

            assert Scope.is_organisation_admin?(scope) == false
          end

          test "returns false for nil scope" do
            assert Scope.is_organisation_admin?(nil) == false
          end
        end

        describe "is_organisation_member?/1" do
          test "returns true for member" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")

            assert Scope.is_organisation_member?(scope) == true
          end

          test "returns false for admin" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "admin")

            assert Scope.is_organisation_member?(scope) == false
          end

          test "returns false for owner" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "owner")

            assert Scope.is_organisation_member?(scope) == false
          end

          test "returns false for nil role" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, nil)

            assert Scope.is_organisation_member?(scope) == false
          end

          test "returns false for scope without organisation" do
            user = insert(:user)
            scope = Scope.for_user(user)

            assert Scope.is_organisation_member?(scope) == false
          end

          test "returns false for nil scope" do
            assert Scope.is_organisation_member?(nil) == false
          end
        end

        describe "role hierarchy" do
          test "owner can manage but is not admin or member" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "owner")

            assert Scope.can_manage_organisation?(scope) == true
            assert Scope.is_organisation_owner?(scope) == true
            assert Scope.is_organisation_admin?(scope) == false
            assert Scope.is_organisation_member?(scope) == false
          end

          test "admin can manage but is not owner or member" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "admin")

            assert Scope.can_manage_organisation?(scope) == true
            assert Scope.is_organisation_owner?(scope) == false
            assert Scope.is_organisation_admin?(scope) == true
            assert Scope.is_organisation_member?(scope) == false
          end

          test "member cannot manage and is not owner or admin" do
            user = insert(:user)
            organisation = insert(:organisation)
            scope = Scope.for_user(user) |> Scope.put_organisation(organisation, "member")

            assert Scope.can_manage_organisation?(scope) == false
            assert Scope.is_organisation_owner?(scope) == false
            assert Scope.is_organisation_admin?(scope) == false
            assert Scope.is_organisation_member?(scope) == true
          end
        end

        describe "scope chaining" do
          test "can chain multiple operations" do
            user = insert(:user)
            organisation = insert(:organisation)

            scope = user
            |> Scope.for_user()
            |> Scope.put_organisation(organisation, "admin")

            assert scope.user == user
            assert scope.organisation == organisation
            assert scope.organisation_role == "admin"
            assert Scope.can_manage_organisation?(scope) == true
          end

          test "can replace organisation in existing scope" do
            user = insert(:user)
            org1 = insert(:organisation, name: "First Org")
            org2 = insert(:organisation, name: "Second Org")

            scope = user
            |> Scope.for_user()
            |> Scope.put_organisation(org1, "member")
            |> Scope.put_organisation(org2, "owner")

            assert scope.organisation == org2
            assert scope.organisation_role == "owner"
            assert Scope.is_organisation_owner?(scope) == true
          end
        end
      end
    """

    Igniter.create_new_file(
      igniter,
      "test/neptuner/accounts/scope_test.exs",
      scope_test_content
    )
  end

  defp update_factory(igniter) do
    Igniter.update_file(igniter, "test/support/factory.ex", fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.contains?(content, "organisation_factory") do
        # Factory already updated
        source
      else
        # Add organisation factories after the use statement
        factory_additions = """

        alias Neptuner.Accounts.User
        alias Neptuner.Organisations.{Organisation, OrganisationMember, OrganisationInvitation}

        def user_factory do
          %User{
            email: sequence(:email, &"user\#{&1}@example.com"),
            confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
          }
        end

        def organisation_factory do
          %Organisation{
            name: sequence(:organisation_name, &"Organisation \#{&1}")
          }
        end

        def organisation_member_factory do
          %OrganisationMember{
            role: "member",
            joined_at: DateTime.utc_now() |> DateTime.truncate(:second),
            user: build(:user),
            organisation: build(:organisation)
          }
        end

        def organisation_invitation_factory do
          token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
          expires_at = DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)

          %OrganisationInvitation{
            email: sequence(:invitation_email, &"invite\#{&1}@example.com"),
            role: "member",
            token: token,
            expires_at: expires_at,
            organisation: build(:organisation),
            invited_by: build(:user)
          }
        end

        def owner_member_factory do
          build(:organisation_member, role: "owner")
        end

        def admin_member_factory do
          build(:organisation_member, role: "admin")
        end

        def expired_invitation_factory do
          expires_at = DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
          build(:organisation_invitation, expires_at: expires_at)
        end

        def accepted_invitation_factory do
          accepted_at = DateTime.utc_now() |> DateTime.truncate(:second)
          build(:organisation_invitation, accepted_at: accepted_at)
        end
        """

        # Add after the use statement
        updated_content =
          String.replace(
            content,
            "  use ExMachina.Ecto, repo: Neptuner.Repo",
            "  use ExMachina.Ecto, repo: Neptuner.Repo" <> factory_additions
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  defp create_organisations_fixtures(igniter) do
    # TODO: Implement when you provide the diff
    igniter
  end

  defp print_completion_notice(igniter) do
    Igniter.add_notice(igniter, """
    Organisation test files have been generated successfully!

    The following test files have been created:
    - test/neptuner/organisations/organisation_test.exs
    - test/neptuner/organisations/organisation_member_test.exs
    - test/neptuner/organisations/organisation_invitation_test.exs
    - test/neptuner/organisations_test.exs
    - test/neptuner_web/live/organisations_live/new_test.exs
    - test/neptuner_web/live/organisations_live/manage_test.exs
    - test/neptuner_web/live/organisations_live/invitation_test.exs
    - test/neptuner_web/user_auth_test.exs (updated)
    - test/neptuner/accounts/scope_test.exs (updated)
    - test/support/factory.ex (updated)
    - test/support/organisations_fixtures.ex

    Run your tests with: mix test
    """)
  end
end
