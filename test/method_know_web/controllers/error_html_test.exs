defmodule MethodKnowWeb.ErrorHTMLTest do
  use MethodKnowWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    assert render_to_string(MethodKnowWeb.ErrorHTML, "404", "html", []) =~ "Lost in Space?"
  end

  test "renders 500.html" do
    html = render_to_string(MethodKnowWeb.ErrorHTML, "500", "html", [])
    assert html =~ "Internal Server Error"
    assert html =~ "Something went wrong on our end."
  end

  test "renders generic error page" do
    assert render_to_string(MethodKnowWeb.ErrorHTML, "403", "html", []) == "Forbidden"
    assert render_to_string(MethodKnowWeb.ErrorHTML, "401", "html", []) == "Unauthorized"
    assert render_to_string(MethodKnowWeb.ErrorHTML, "422", "html", []) == "Unprocessable Content"
    assert render_to_string(MethodKnowWeb.ErrorHTML, "502", "html", []) == "Bad Gateway"
  end
end
