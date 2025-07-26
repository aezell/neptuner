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
               "button[phx-click=\"change_role\"][phx-value-user-id=\"#{member_user.id}\"]"
             )

      assert has_element?(
               view,
               "button[phx-click=\"remove_member\"][phx-value-user-id=\"#{member_user.id}\"]"
             )

      # Should not see action buttons for self
      refute has_element?(
               view,
               "button[phx-click=\"change_role\"][phx-value-user-id=\"#{user.id}\"]"
             )

      refute has_element?(
               view,
               "button[phx-click=\"remove_member\"][phx-value-user-id=\"#{user.id}\"]"
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
      refute has_element?(view, "button[phx-click=\"change_role\"]")
      refute has_element?(view, "button[phx-click=\"remove_member\"]")
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
      assert has_element?(view, "input[name=\"organisation[name]\"]")
    end

    test "can trigger invite member modal", %{conn: conn} do
      user = insert(:user)
      organisation = insert(:organisation, name: "Test Org")
      insert(:organisation_member, user: user, organisation: organisation, role: "owner")

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/organisations/manage")

      view |> element("button", "Invite Member") |> render_click()

      assert render(view) =~ "Invite Team Member"
      assert has_element?(view, "input[name=\"invite[email]\"]")
      assert has_element?(view, "select[name=\"invite[role]\"]")
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
