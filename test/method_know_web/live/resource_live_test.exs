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

  describe "Index" do
    setup [:create_resource]

    test "lists all resources", %{conn: conn, resource: resource} do
      {:ok, _index_live, html} = live(conn, ~p"/resources")

      assert html =~ "Discover Resources"
      assert html =~ resource.title
    end

    test "saves new resource", %{conn: conn} do
      System.put_env("SHOW_SHARE_BUTTON", "true")
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      # Open the new resource form
      assert render_click(element(index_live, "#share-resource-btn")) =~ "Share a resource"

      # Fill out the form with @create_attrs and submit
      assert index_live
             |> form("#resource-form", resource: @create_attrs)
             |> render_submit()

      # After submit, re-fetch the index_live handle to check the new resource is listed
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      html = render(index_live)
      assert html =~ @create_attrs.title
    end

    test "updates resource in listing", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      # Open the edit drawer for the resource
      render_click(element(index_live, "button[phx-click='edit'][phx-value-id='#{resource.id}']"))

      # Interact with the form while it is open
      assert index_live
             |> form("#resource-form", resource: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#resource-form", resource: %{"resource_type" => "code_snippet"})
             |> render_change()

      # Submit valid data and do not interact with the form after submit
      assert index_live
             |> form("#resource-form", resource: @update_attrs)
             |> render_submit()

      # After submit, re-fetch the index_live handle to check the updated content
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      html = render(index_live)
      assert html =~ "some updated title"
    end

    test "deletes resource in listing", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      # Open the delete modal for the resource
      assert render_click(
               element(
                 index_live,
                 "button[phx-click='show_delete_modal'][phx-value-id='#{resource.id}']"
               )
             ) =~ "Are you sure you want to delete"

      # Confirm delete (update selector as needed)
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

  describe "Show" do
    setup [:create_resource]

    test "displays resource", %{conn: conn, resource: resource} do
      {:ok, _show_live, html} = live(conn, ~p"/resources/#{resource}")

      assert html =~ "Show Resource"
      assert html =~ resource.title
    end

    test "updates resource and returns to show", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      # Open the edit drawer for the resource
      render_click(element(index_live, "button[phx-click='edit'][phx-value-id='#{resource.id}']"))

      # Interact with the form while it is open
      assert index_live
             |> form("#resource-form", resource: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#resource-form", resource: %{"resource_type" => "code_snippet"})
             |> render_change()

      # Submit valid data and do not interact with the form after submit
      assert index_live
             |> form("#resource-form", resource: @update_attrs)
             |> render_submit()

      # After submit, re-fetch the index_live handle to check the updated content
      {:ok, index_live, _html} = live(conn, ~p"/resources")
      html = render(index_live)
      assert html =~ "some updated title"
    end
  end
end
