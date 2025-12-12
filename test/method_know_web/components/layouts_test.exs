defmodule MethodKnowWeb.LayoutsTest do
  use MethodKnowWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  import MethodKnowWeb.CoreComponents
  import MethodKnowWeb.Layouts

  test "navbar renders logo and login link when not authenticated" do
    assigns = %{current_scope: nil, hide_navbar: false}

    html =
      rendered_to_string(~H"""
      <.navbar current_scope={@current_scope} hide_navbar={@hide_navbar} />
      """)

    assert html =~ "Method Know"
    assert html =~ "Log in"
    assert html =~ "Register"
    refute html =~ "My Account"
  end

  test "navbar renders user avatar and dropdown when authenticated" do
    user = %MethodKnow.Accounts.User{email: "test@example.com", name: "John Doe"}
    current_scope = %{user: user}
    assigns = %{current_scope: current_scope, hide_navbar: false}

    html =
      rendered_to_string(~H"""
      <.navbar current_scope={@current_scope} hide_navbar={@hide_navbar} />
      """)

    assert html =~ "John"
    assert html =~ "My Account"
    assert html =~ "Settings"
    assert html =~ "Log out"
    refute html =~ "Register"
  end

  test "navbar is hidden when hide_navbar is true" do
    assigns = %{current_scope: nil, hide_navbar: true}

    html =
      rendered_to_string(~H"""
      <.navbar current_scope={@current_scope} hide_navbar={@hide_navbar} />
      """)

    assert html == ""
  end

  test "avatar component renders first name" do
    assigns = %{name: "Jane Doe"}

    html =
      rendered_to_string(~H"""
      <.avatar name={@name} />
      """)

    assert html =~ "Jane"
  end
end
