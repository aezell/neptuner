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

      {:ok, _view, html} = live(conn, ~p"/invitations/accept/#{invitation.token}")

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

      {:ok, _view, html} = live(conn, ~p"/invitations/accept/#{invitation.token}")

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

      {:ok, _view, html} = live(conn, ~p"/invitations/accept/#{invitation.token}")

      assert html =~ "Invalid Invitation"
      assert html =~ "invalid, expired, or has already been used"
    end

    test "shows error for already accepted invitation", %{conn: conn} do
      invitation = insert(:accepted_invitation)

      {:ok, _view, html} = live(conn, ~p"/invitations/accept/#{invitation.token}")

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

      {:ok, view, _html} = live(conn, ~p"/invitations/accept/#{invitation.token}")

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

      {:ok, view, _html} = live(conn, ~p"/invitations/accept/#{invitation.token}")

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

      {:ok, view, _html} = live(conn, ~p"/invitations/accept/#{invitation.token}")

      view |> element("button", "Accept Invitation") |> render_click()

      assert render(view) =~ "already a member"
      refute_redirected(view)
    end
  end
end
