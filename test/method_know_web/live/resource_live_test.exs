defmodule MethodKnowWeb.ResourceLiveTest do
  use MethodKnowWeb.ConnCase

  import Phoenix.LiveViewTest
  import MethodKnow.ResourcesFixtures

  @create_attrs %{description: "some description", title: "some title", url: "https://example.com", resource_type: "article", tags: "some tag"}
  @update_attrs %{code: "some updated code", description: "some updated description", title: "some updated title", language: "some updated language", resource_type: "code_snippet", tags: "updated tag"}
  @invalid_attrs %{description: nil, title: nil, resource_type: "article", tags: ""}

  setup :register_and_log_in_user

  defp create_resource(%{scope: scope}) do
    resource = resource_fixture(scope)

    %{resource: resource}
  end

  describe "Index" do
    setup [:create_resource]

    test "lists all resources", %{conn: conn, resource: resource} do
      {:ok, _index_live, html} = live(conn, ~p"/resources")

      assert html =~ "Listing Resources"
      assert html =~ resource.title
    end

    test "saves new resource", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Resource")
               |> render_click()
               |> follow_redirect(conn, ~p"/resources/new")

      assert render(form_live) =~ "New Resource"

      assert form_live
             |> form("#resource-form", resource: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#resource-form", resource: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/resources")

      html = render(index_live)
      assert html =~ "Resource created successfully"
      assert html =~ "some title"
    end

    test "updates resource in listing", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#resources-#{resource.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/resources/#{resource}/edit")

      assert render(form_live) =~ "Edit Resource"

      assert form_live
             |> form("#resource-form", resource: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # Switch to code_snippet to reveal code/language inputs
      form_live
      |> form("#resource-form", resource: %{"resource_type" => "code_snippet"})
      |> render_change()

      assert {:ok, index_live, _html} =
               form_live
               |> form("#resource-form", resource: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/resources")

      html = render(index_live)
      assert html =~ "Resource updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes resource in listing", %{conn: conn, resource: resource} do
      {:ok, index_live, _html} = live(conn, ~p"/resources")

      assert index_live |> element("#resources-#{resource.id} a", "Delete") |> render_click()
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
      {:ok, show_live, _html} = live(conn, ~p"/resources/#{resource}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/resources/#{resource}/edit?return_to=show")

      assert render(form_live) =~ "Edit Resource"

      assert form_live
             |> form("#resource-form", resource: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # Switch to code_snippet to reveal code/language inputs
      form_live
      |> form("#resource-form", resource: %{"resource_type" => "code_snippet"})
      |> render_change()

      assert {:ok, show_live, _html} =
               form_live
               |> form("#resource-form", resource: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/resources/#{resource}")

      html = render(show_live)
      assert html =~ "Resource updated successfully"
      assert html =~ "some updated title"
    end
  end
end
