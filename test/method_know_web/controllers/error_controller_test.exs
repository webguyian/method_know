defmodule MethodKnowWeb.ErrorControllerTest do
  use MethodKnowWeb.ConnCase, async: true

  import MethodKnow.AccountsFixtures

  describe "404 page" do
    test "renders the custom 404 page for unknown routes", %{conn: conn} do
      conn = get(conn, "/some/non/existent/path")

      assert html_response(conn, 404) =~ "Lost in Space?"
      assert html_response(conn, 404) =~ "Return Home"
    end

    test "includes the navbar and shows login links when unauthenticated", %{conn: conn} do
      conn = get(conn, "/non-existent")

      assert html_response(conn, 404) =~ "Register"
      assert html_response(conn, 404) =~ "Log in"
    end

    test "includes the navbar and shows user info when authenticated", %{conn: conn} do
      user = user_fixture(%{name: "Test User"})
      conn = conn |> log_in_user(user) |> get("/non-existent")

      assert html_response(conn, 404) =~ "Test"
      assert html_response(conn, 404) =~ "Log out"
      # Verify it doesn't show login/register links
      refute html_response(conn, 404) =~ "Register"
    end
  end
end
