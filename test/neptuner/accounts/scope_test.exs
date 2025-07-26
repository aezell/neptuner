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

      scope =
        user
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

      scope =
        user
        |> Scope.for_user()
        |> Scope.put_organisation(org1, "member")
        |> Scope.put_organisation(org2, "owner")

      assert scope.organisation == org2
      assert scope.organisation_role == "owner"
      assert Scope.is_organisation_owner?(scope) == true
    end
  end
end
