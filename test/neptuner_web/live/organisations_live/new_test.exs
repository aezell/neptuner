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
      assert has_element?(view, "input[name=\"organisation[name]\"]")
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
