defmodule MethodKnow.ResourcesTest do
  use MethodKnow.DataCase

  alias MethodKnow.Resources

  describe "resources" do
    alias MethodKnow.Resources.Resource

    import MethodKnow.AccountsFixtures, only: [user_scope_fixture: 0]
    import MethodKnow.ResourcesFixtures

    @invalid_attrs %{code: nil, description: nil, title: nil, author: nil, url: nil, language: nil, resource_type: nil, tags: nil}

    test "list_resources/1 returns all scoped resources" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      resource = resource_fixture(scope)
      other_resource = resource_fixture(other_scope)
      assert Resources.list_resources(scope) == [resource]
      assert Resources.list_resources(other_scope) == [other_resource]
    end

    test "get_resource!/2 returns the resource with given id" do
      scope = user_scope_fixture()
      resource = resource_fixture(scope)
      other_scope = user_scope_fixture()
      assert Resources.get_resource!(scope, resource.id) == resource
      assert_raise Ecto.NoResultsError, fn -> Resources.get_resource!(other_scope, resource.id) end
    end

    test "create_resource/2 with valid data creates a resource" do
      valid_attrs = %{code: "some code", description: "some description", title: "some title", author: "some author", url: "https://example.com", language: "some language", resource_type: "article", tags: ["some tag"]}
      scope = user_scope_fixture()

      assert {:ok, %Resource{} = resource} = Resources.create_resource(scope, valid_attrs)
      assert resource.code == "some code"
      assert resource.description == "some description"
      assert resource.title == "some title"
      assert resource.author == "some author"
      assert resource.url == "https://example.com"
      assert resource.language == "some language"
      assert resource.resource_type == "article"
      assert resource.tags == ["some tag"]
      assert resource.user_id == scope.user.id
    end

    test "create_resource/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Resources.create_resource(scope, @invalid_attrs)
    end

    test "update_resource/3 with valid data updates the resource" do
      scope = user_scope_fixture()
      resource = resource_fixture(scope)
      update_attrs = %{code: "some updated code", description: "some updated description", title: "some updated title", author: "some updated author", url: "http://updated.example.com", language: "some updated language", resource_type: "code_snippet", tags: ["updated tag"]}

      assert {:ok, %Resource{} = resource} = Resources.update_resource(scope, resource, update_attrs)
      assert resource.code == "some updated code"
      assert resource.description == "some updated description"
      assert resource.title == "some updated title"
      assert resource.author == "some updated author"
      assert resource.url == "http://updated.example.com"
      assert resource.language == "some updated language"
      assert resource.resource_type == "code_snippet"
      assert resource.tags == ["updated tag"]
    end

    test "update_resource/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      resource = resource_fixture(scope)

      assert_raise MatchError, fn ->
        Resources.update_resource(other_scope, resource, %{})
      end
    end

    test "update_resource/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      resource = resource_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Resources.update_resource(scope, resource, @invalid_attrs)
      assert resource == Resources.get_resource!(scope, resource.id)
    end

    test "delete_resource/2 deletes the resource" do
      scope = user_scope_fixture()
      resource = resource_fixture(scope)
      assert {:ok, %Resource{}} = Resources.delete_resource(scope, resource)
      assert_raise Ecto.NoResultsError, fn -> Resources.get_resource!(scope, resource.id) end
    end

    test "delete_resource/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      resource = resource_fixture(scope)
      assert_raise MatchError, fn -> Resources.delete_resource(other_scope, resource) end
    end

    test "change_resource/2 returns a resource changeset" do
      scope = user_scope_fixture()
      resource = resource_fixture(scope)
      assert %Ecto.Changeset{} = Resources.change_resource(scope, resource)
    end
  end
end
