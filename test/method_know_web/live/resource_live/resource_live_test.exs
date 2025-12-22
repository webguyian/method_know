defmodule MethodKnowWeb.ResourceLiveTest do
  use MethodKnowWeb.ConnCase

  import Phoenix.LiveViewTest
  import MethodKnow.ResourcesFixtures

  @create_attrs %{
    description: "some description",
    title: "some title",
    url: "https://example.com",
    resource_type: "article"
  }
  @update_attrs %{
    code: "some updated code",
    description: "some updated description",
    title: "some updated title",
    language: "some updated language",
    resource_type: "code_snippet",
    tags: "some tag"
  }
  @invalid_attrs %{description: nil, title: nil, resource_type: "article"}

  setup :register_and_log_in_user

  defp create_resource(%{scope: scope}) do
    resource = resource_fixture(scope)
    %{resource: resource}
  end

  describe "CRUD Resources" do
    setup [:create_resource]

    test "mounts and renders with default assigns", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/resources")
      assert html =~ "Discover Resources"
      assert html =~ "Search resource by title or description"
    end

    test "shows empty state when no resources", %{conn: conn} do
      MethodKnow.Repo.delete_all(MethodKnow.Resources.Resource)
      {:ok, _index_live, html} = live(conn, ~p"/resources")
      assert html =~ "No resources found"
    end

    test "lists all resources", %{conn: conn, resource: resource} do
      {:ok, _index_live, html} = live(conn, ~p"/resources")
      assert html =~ "Discover Resources"
      assert html =~ resource.title
    end

    test "saves new resource", %{conn: conn} do
      System.put_env("SHOW_SHARE_BUTTON", "true")
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      assert render_click(element(index_live, "#share-resource-btn")) =~ "Share a resource"

      assert index_live
             |> form("#resource-form", resource: @create_attrs)
             |> render_submit()

      {:ok, index_live, _html} = live(conn, ~p"/resources")
      html = render(index_live)
      assert html =~ @create_attrs.title
    end

    test "updates resource in listing", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      render_click(element(index_live, "button[phx-click='edit'][phx-value-id='#{resource.id}']"))

      assert index_live
             |> form("#resource-form", resource: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#resource-form", resource: %{"resource_type" => "code_snippet"})
             |> render_change()

      assert index_live
             |> form("#resource-form", resource: @update_attrs)
             |> render_submit()

      {:ok, index_live, _html} = live(conn, ~p"/resources")
      html = render(index_live)
      assert html =~ "some updated title"
    end

    test "deletes resource in listing", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      assert render_click(
               element(
                 index_live,
                 "button[phx-click='show_delete_modal'][phx-value-id='#{resource.id}']"
               )
             ) =~ "Are you sure you want to delete"

      html =
        render_click(
          element(
            index_live,
            "button#confirm-delete-btn[phx-click='confirm_delete'][phx-value-id='#{resource.id}']"
          )
        )

      assert html =~ "Resource deleted!"
      refute has_element?(index_live, "#resources-#{resource.id}")
    end
  end

  describe "Filtering (UI events and query params)" do
    setup [:create_resource]

    test "loads filtered resources by type from URL", %{conn: conn, resource: resource} do
      type = resource.resource_type
      {:ok, _index_live, html} = live(conn, "/resources?types=#{type}")
      assert html =~ resource.title
      assert html =~ type
    end

    test "loads filtered resources by tag from URL", %{conn: conn, resource: resource} do
      tag = (resource.tags || ["advanced"]) |> List.first()
      {:ok, _index_live, html} = live(conn, "/resources?tags=#{tag}")
      assert html =~ resource.title
      assert html =~ tag
    end

    test "loads filtered resources by type and tag from URL", %{conn: conn, resource: resource} do
      type = resource.resource_type
      tag = (resource.tags || ["advanced"]) |> List.first()
      {:ok, _index_live, html} = live(conn, "/resources?types=#{type}&tags=#{tag}")
      assert html =~ resource.title
      assert html =~ type
      assert html =~ tag
    end

    test "loads filtered resources by search from URL", %{conn: conn, resource: resource} do
      {:ok, _index_live, html} = live(conn, "/resources?search=#{URI.encode(resource.title)}")
      assert html =~ resource.title
    end

    test "shows empty state for unmatched filter params", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, "/resources?types=notarealtype&tags=notatag")
      assert html =~ "No resources found"
    end

    test "filters resources by type", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      type = resource.resource_type

      html =
        render_click(
          element(
            index_live,
            "button[phx-click='filter_type'][phx-value-resource_type='#{type}']"
          )
        )

      assert html =~ resource.title
    end

    test "filters resources by tag", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      tag = (resource.tags || ["advanced"]) |> List.first()
      card_id = "#resources-#{resource.id}"
      selector = card_id <> " button[phx-click='filter_tag'][phx-value-tag='#{tag}']"
      html = render_click(element(index_live, selector))
      assert html =~ resource.title
    end

    test "searches resources by title", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      html =
        render_change(form(index_live, "form[phx-change='search']", %{search: resource.title}))

      assert html =~ resource.title
    end
  end

  describe "Drawer and Modal (show/hide)" do
    setup [:create_resource]

    test "shows and hides the delete modal", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      html =
        render_click(
          element(
            index_live,
            "button[phx-click='show_delete_modal'][phx-value-id='#{resource.id}']"
          )
        )

      assert html =~ "Are you sure you want to delete"
      html = render_click(element(index_live, "#cancel-delete-btn"))
      refute html =~ "Are you sure you want to delete"
    end

    test "shows and hides mobile filter panel", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      refute render(index_live) =~ "mobile-filter-panel"
      html = render_click(element(index_live, "#filters-toggle-btn"))
      assert html =~ "mobile-filter-panel"
      html = render_click(element(index_live, "#filters-toggle-btn"))
      refute html =~ "mobile-filter-panel"
    end

    test "closes drawer on :close_drawer message", %{conn: conn} do
      System.put_env("SHOW_SHARE_BUTTON", "true")
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      render_click(element(index_live, "#share-resource-btn"))
      assert render(index_live) =~ "Share a resource"
      send(index_live.pid, :close_drawer)
      html = render(index_live)
      refute html =~ "Share a resource"
    end

    test "shows resource in drawer", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      assert index_live
             |> element("button[phx-click='show'][phx-value-id='#{resource.id}']")
             |> render_click() =~ resource.title
    end
  end

  describe "Toasts and Shout Messages" do
    setup [:create_resource]

    test "shows toast on resource creation", %{conn: conn} do
      System.put_env("SHOW_SHARE_BUTTON", "true")
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      render_click(element(index_live, "#share-resource-btn"))
      render_submit(form(index_live, "#resource-form", resource: @create_attrs))
      send(index_live.pid, {:resource_saved, :created})
      html = render(index_live)
      assert html =~ "New resource successfully added!"
    end

    test "shows and fades shout message", %{conn: conn, scope: scope} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      user = scope.user
      send(index_live.pid, {:shout, %{user: user, message: "Hello!"}})
      html = render(index_live)
      assert html =~ "Hello!"
      send(index_live.pid, :shout_message_fade)
      html = render(index_live)
      assert html =~ "fading" or html =~ "opacity-0" or html =~ "fade"
      send(index_live.pid, :shout_message_clear)
      html = render(index_live)
      refute html =~ "Hello!"
    end
  end
end
