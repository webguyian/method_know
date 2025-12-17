defmodule MethodKnowWeb.TagFilterComponentTest do
  use MethodKnowWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias MethodKnowWeb.TagFilterComponent

  defmodule TestLive do
    use MethodKnowWeb, :live_view

    def render(assigns) do
      ~H"""
      <.live_component
        module={TagFilterComponent}
        id="tag-filter"
        tags={@tags}
        all_tags={@all_tags}
      />
      """
    end

    def mount(_params, %{"tags" => tags, "all_tags" => all_tags}, socket) do
      {:ok, assign(socket, tags: tags, all_tags: all_tags)}
    end

    def handle_info({:tags_updated, tags}, socket) do
      {:noreply, Phoenix.Component.assign(socket, :tags, tags)}
    end
  end

  describe "rendering" do
    test "renders initial state with labels and input", %{conn: conn} do
      {:ok, _view, html} =
        live_isolated(conn, TestLive,
          session: %{
            "tags" => [],
            "all_tags" => ["elixir", "phoenix", "tailwind"]
          }
        )

      assert html =~ "Tags"
      assert html =~ "placeholder=\"Add tag\""
      refute html =~ "badge-primary"
    end

    test "renders existing tags", %{conn: conn} do
      {:ok, _view, html} =
        live_isolated(conn, TestLive,
          session: %{
            "tags" => ["elixir", "testing"],
            "all_tags" => ["elixir", "testing", "tailwind"]
          }
        )

      assert html =~ "elixir"
      assert html =~ "testing"
      assert html =~ "aria-label=\"Remove tag\""
    end
  end

  describe "interactions" do
    test "shows dropdown on focus and filters tags", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "tags" => [],
            "all_tags" => ["elixir", "phoenix", "tailwind"]
          }
        )

      # Focus to show dropdown
      view
      |> element("input")
      |> render_focus()

      assert render(view) =~ "elixir"
      assert render(view) =~ "phoenix"
      assert render(view) =~ "tailwind"

      # Type to filter
      view
      |> form("form")
      |> render_change(%{tag_input: "elix"})

      html = render(view)
      assert html =~ "elixir"
      refute html =~ "phoenix"
      refute html =~ "tailwind"
    end

    test "adds tag from dropdown", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "tags" => [],
            "all_tags" => ["elixir", "phoenix"]
          }
        )

      # Show dropdown
      view |> element("input") |> render_focus()

      # Click the button
      view
      |> element("#tag-dropdown button", "elixir")
      |> render_click()

      assert render(view) =~ "badge-primary"
      assert render(view) =~ "elixir"
    end

    test "adds tag by submitting form", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "tags" => [],
            "all_tags" => ["elixir"]
          }
        )

      view
      |> form("form", %{tag_input: "NEW-TAG"})
      |> render_submit()

      # Component downcases submitted tags
      assert render(view) =~ "new-tag"
    end

    test "removes tag", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "tags" => ["elixir"],
            "all_tags" => ["elixir"]
          }
        )

      assert has_element?(view, "span", "elixir")

      view
      |> element("button[phx-value-tag='elixir']")
      |> render_click()

      refute has_element?(view, "span", "elixir")
    end

    test "notifies parent when tag is removed", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestLive,
          session: %{
            "tags" => ["elixir"],
            "all_tags" => ["elixir"]
          }
        )

      view
      |> element("button[phx-value-tag='elixir']")
      |> render_click()

      # Verify the message was sent to the parent (TestLive)
      # which in turn updates the state and re-renders
      refute has_element?(view, "span", "elixir")
    end
  end
end
