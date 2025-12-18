defmodule MethodKnowWeb.CoreComponentsTest do
  use MethodKnowWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias MethodKnowWeb.CoreComponents
  alias MethodKnow.Resources.Resource

  test "avatar/1 renders user name and image" do
    user = %{name: "Jose Valim", email: "jose@elixir-lang.org"}
    html = render_component(&CoreComponents.avatar/1, %{user: user})

    assert html =~ "Jose"
    assert html =~ "https://api.dicebear.com/9.x/notionists/svg?seed="
    assert html =~ "alt=\"avatar\""
  end

  test "avatar/1 renders placeholder when no email" do
    html = render_component(&CoreComponents.avatar/1, %{user: %{name: "Ghost"}})
    # Lucide icon
    assert html =~ "svg"
    assert html =~ "Ghost"
    refute html =~ "img"
  end

  test "avatar/1 can hide name" do
    user = %{name: "Secret User", email: "secret@example.com"}
    html = render_component(&CoreComponents.avatar/1, %{user: user, show_name: false})
    refute html =~ "<span"
    assert html =~ "img"
  end

  test "resource_type_badge/1 renders correct labels" do
    # Article
    html = render_component(&CoreComponents.resource_type_badge/1, %{type: "article"})
    assert html =~ "Article"
    # Icon name
    assert html =~ "newspaper"

    # Code Snippet
    html = render_component(&CoreComponents.resource_type_badge/1, %{type: "code_snippet"})
    assert html =~ "Code Snippet"
    assert html =~ "code_2"

    # Learning Resource
    html = render_component(&CoreComponents.resource_type_badge/1, %{type: "learning_resource"})
    assert html =~ "Learning Resource"
    assert html =~ "graduation_cap"

    # Unknown
    html = render_component(&CoreComponents.resource_type_badge/1, %{type: "weird_stuff"})
    assert html =~ "Weird_stuff"
    assert html =~ "help_circle"
  end

  test "resource_link/1 renders correct text" do
    # Article
    res = %Resource{resource_type: "article", url: "http://example.com/art"}
    html = render_component(&CoreComponents.resource_link/1, %{resource: res})
    assert html =~ "View article"
    assert html =~ "href=\"http://example.com/art\""

    # Learning Resource
    res = %Resource{resource_type: "learning_resource", url: "http://example.com/learn"}
    html = render_component(&CoreComponents.resource_link/1, %{resource: res})
    assert html =~ "View resource"

    # Others
    res = %Resource{resource_type: "code_snippet", url: "http://example.com/code"}
    html = render_component(&CoreComponents.resource_link/1, %{resource: res})
    assert html =~ "View"
    refute html =~ "View article"
  end

  test "code_snippet/1 renders code block" do
    html =
      render_component(&CoreComponents.code_snippet/1, %{
        code: "def hello, do: :world",
        language: "elixir",
        id: "my-code"
      })

    assert html =~ "id=\"my-code\""
    assert html =~ "language-elixir"
    assert html =~ "def hello, do: :world"
  end

  test "tag_button/1 renders active and inactive states" do
    # Inactive
    html =
      render_component(&CoreComponents.tag_button/1, %{
        tag: "elixir",
        active: false,
        click: "filter"
      })

    assert html =~ "elixir"
    assert html =~ "badge"
    refute html =~ "badge-primary"

    # Active
    html =
      render_component(&CoreComponents.tag_button/1, %{
        tag: "phoenix",
        active: true,
        click: "filter"
      })

    assert html =~ "phoenix"
    assert html =~ "badge-primary"
  end

  test "dropdown_select/1 renders options and selected value" do
    options = [{"Option 1", "v1"}, {"Option 2", "v2"}]

    # 1. With selected value (matches "v1")
    html =
      render_component(&CoreComponents.dropdown_select/1, %{
        id: "my-select",
        options: options,
        value: "v1",
        label: "My Label",
        prompt: "Select something",
        change_event: "select_changed",
        target: nil,
        name: "my_field"
      })

    assert html =~ "My Label"
    assert html =~ "Option 1"
    assert html =~ "Option 2"
    # When value matches, the button shows the label of the match ("Option 1"), not the prompt
    refute html =~ "Select something"
    assert html =~ "class=\"active\""

    # 2. Without matching value (shows prompt)
    html =
      render_component(&CoreComponents.dropdown_select/1, %{
        id: "my-select-2",
        options: options,
        value: nil,
        label: nil,
        prompt: "Choose wisely",
        change_event: "select_changed",
        target: nil,
        name: "my_field"
      })

    assert html =~ "Choose wisely"
  end

  test "dropdown_select/1 works with Phoenix.HTML.FormField" do
    options = [{"Option 1", "v1"}, {"Option 2", "v2"}]
    # FormField needs a real Form struct or one that satisfies the FormData protocol
    form = %Phoenix.HTML.Form{id: "f", name: "f", params: %{}}

    field = %Phoenix.HTML.FormField{
      id: "my_id",
      name: "my_name",
      value: "v2",
      errors: [],
      field: :f,
      form: form
    }

    html =
      render_component(&CoreComponents.dropdown_select/1, %{
        id: "my-dropdown",
        field: field,
        options: options,
        change_event: "select_changed",
        target: nil
      })

    assert html =~ "id=\"my-dropdown\""
    assert html =~ "name=\"my_name\""
    assert html =~ "Option 2"
    # Hidden select should have the value
    assert html =~ "value=\"v2\""
  end
end
