defmodule MethodKnowWeb.ResourceCardComponentTest do
  use MethodKnowWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias MethodKnowWeb.ResourceCardComponent
  alias MethodKnow.ResourcesFixtures
  alias MethodKnow.AccountsFixtures

  setup do
    user = AccountsFixtures.user_fixture()
    scope = MethodKnow.Accounts.Scope.for_user(user)
    resource = ResourcesFixtures.resource_fixture(scope, %{user_id: user.id})
    %{user: user, scope: scope, resource: resource}
  end

  test "renders resource card items", %{resource: resource} do
    html =
      render_component(ResourceCardComponent, %{
        id: "resource-#{resource.id}",
        resource: resource,
        current_user: nil
      })

    assert html =~ resource.title
    assert html =~ resource.description
    assert html =~ "View details"
  end

  test "renders edit and delete buttons for owner", %{user: user, resource: resource} do
    html =
      render_component(ResourceCardComponent, %{
        id: "resource-#{resource.id}",
        resource: resource,
        current_user: user,
        on_edit: "edit_resource",
        on_delete: "delete_resource"
      })

    assert html =~ "title=\"Edit\""
    assert html =~ "title=\"Delete\""
    assert html =~ "phx-click=\"edit_resource\""
    assert html =~ "phx-click=\"delete_resource\""
  end

  test "does not render edit/delete buttons for non-owner", %{resource: resource} do
    other_user = AccountsFixtures.user_fixture()

    html =
      render_component(ResourceCardComponent, %{
        id: "resource-#{resource.id}",
        resource: resource,
        current_user: other_user
      })

    refute html =~ "title=\"Edit\""
    refute html =~ "title=\"Delete\""
  end

  test "renders code snippet fields", %{scope: scope} do
    resource =
      ResourcesFixtures.resource_fixture(scope, %{
        resource_type: "code_snippet",
        code: "IO.inspect :hello",
        language: "elixir"
      })

    html =
      render_component(ResourceCardComponent, %{
        id: "resource-#{resource.id}",
        resource: resource,
        current_user: nil
      })

    assert html =~ "IO.inspect :hello"
    assert html =~ "elixir"
  end

  test "renders author and url when present", %{scope: scope} do
    resource =
      ResourcesFixtures.resource_fixture(scope, %{
        author: "Jose Valim",
        url: "https://elixir-lang.org"
      })

    html =
      render_component(ResourceCardComponent, %{
        id: "resource-#{resource.id}",
        resource: resource,
        current_user: nil
      })

    assert html =~ "by Jose Valim"
    assert html =~ "href=\"https://elixir-lang.org\""
  end

  test "truncates long descriptions", %{scope: scope} do
    long_desc = String.duplicate("a", 300)
    resource = ResourcesFixtures.resource_fixture(scope, %{description: long_desc})

    html =
      render_component(ResourceCardComponent, %{
        id: "resource-#{resource.id}",
        resource: resource,
        current_user: nil
      })

    assert String.length(long_desc) > 250
    # 247 chars + "..."
    assert html =~ String.slice(long_desc, 0, 247) <> "..."
    refute html =~ long_desc
  end

  test "relative date formatting", %{scope: scope} do
    # Today
    resource = ResourcesFixtures.resource_fixture(scope, %{inserted_at: DateTime.utc_now()})

    html =
      render_component(ResourceCardComponent, %{id: "r1", resource: resource, current_user: nil})

    assert html =~ "Today"

    # Yesterday
    yesterday = DateTime.utc_now() |> DateTime.add(-1, :day)
    resource = %{resource | inserted_at: yesterday}

    html =
      render_component(ResourceCardComponent, %{id: "r2", resource: resource, current_user: nil})

    assert html =~ "Yesterday"

    # X days ago
    three_days_ago = DateTime.utc_now() |> DateTime.add(-3, :day)
    resource = %{resource | inserted_at: three_days_ago}

    html =
      render_component(ResourceCardComponent, %{id: "r3", resource: resource, current_user: nil})

    assert html =~ "3 days ago"
  end

  test "handles nil description", %{resource: resource} do
    resource = %{resource | description: nil}

    html =
      render_component(ResourceCardComponent, %{
        id: "r-nil",
        resource: resource,
        current_user: nil
      })

    # Should not crash and should have empty description area
    assert html =~ "resources-#{resource.id}"
  end
end
