defmodule MethodKnowWeb.ResourceLiveTestFilters do
  use MethodKnowWeb.ConnCase

  import Phoenix.LiveViewTest
  import MethodKnow.ResourcesFixtures

  setup :register_and_log_in_user

  defp create_resources(%{scope: scope}) do
    article =
      resource_fixture(scope, %{
        title: "Elixir Basics",
        resource_type: "article",
        tags: ["basics", "elixir"]
      })

    snippet =
      resource_fixture(scope, %{
        title: "GenServer Pattern",
        resource_type: "code_snippet",
        tags: ["advanced", "process"]
      })

    %{article: article, snippet: snippet}
  end

  describe "Filter Persistence" do
    setup [:create_resources]

    test "loads filters from URL query params", %{conn: conn, article: article, snippet: snippet} do
      # Test search param
      {:ok, index_live, _html} = live(conn, ~p"/?search=basics")
      html = render(index_live)
      assert html =~ article.title
      refute html =~ snippet.title

      # Test type param
      {:ok, index_live, _html} = live(conn, ~p"/?types=code_snippet")
      html = render(index_live)
      refute html =~ article.title
      assert html =~ snippet.title

      # Test tag param
      {:ok, index_live, _html} = live(conn, ~p"/?tags=advanced")
      html = render(index_live)
      refute html =~ article.title
      assert html =~ snippet.title
    end

    test "updates URL when filters are applied (root path)", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      # Apply search
      index_live
      |> form("form[phx-change='search']", search: "GenServer")
      |> render_change()

      assert_patch(index_live, "/?search=GenServer")

      # Apply type filter (simulating the form change or click event depending on implementation)
      # Let's test "filter_type" event which expects list or single value
      render_hook(index_live, "filter_type", %{"resource_type" => ["article"]})

      assert_patch(index_live, "/?search=GenServer&types=article")

      # Apply tag filter
      render_hook(index_live, "filter_tag", %{"tag" => "basics"})

      # Expect comma separated values (URL encoded comma is %2C)
      assert_patch(index_live, "/?search=GenServer&tags=basics&types=article")
    end

    test "updates URL when filters are applied (my resources)", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/my/resources")

      # Apply search
      index_live
      |> form("form[phx-change='search']", search: "MyStuff")
      |> render_change()

      assert_patch(index_live, "/my/resources?search=MyStuff")
    end

    test "omits empty search param", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      # Apply type filter only
      render_hook(index_live, "filter_type", %{"resource_type" => ["article"]})
      assert_patch(index_live, "/?types=article")
    end

    test "reset filters clears URL params (root path)", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/?search=foo&types[]=article")

      render_click(element(index_live, "#reset-filters-btn"))

      # When patching to current_path with no queries, it should just be current_path with a trailing ? if query is empty string, OR cleaned up.
      # Phoenix URI.encode_query([]) returns "" so path?"" -> path?
      # However, push_patch(to: path) usually works.
      # Let's see what the implementation does: "#{path}?#{URI.encode_query(params)}"
      # If params is empty, query is empty string. So "/" => "/?".
      # Wait, reset: push_patch(socket, to: socket.assigns.current_path) - NO query string in reset handler.

      assert_patch(index_live, ~p"/")
    end
  end
end
