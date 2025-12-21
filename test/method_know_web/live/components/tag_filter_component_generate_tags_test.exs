defmodule MethodKnowWeb.TagFilterComponent.GenerateTagsTest do
  use MethodKnowWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  defmodule TestLive do
    use MethodKnowWeb, :live_view
    alias MethodKnowWeb.TagFilterComponent

    def render(assigns) do
      ~H"""
      <.live_component
        module={TagFilterComponent}
        id="tag-filter"
        tags={@tags}
        all_tags={@all_tags}
        resource={@resource}
        generating_tags={@generating_tags}
      />
      """
    end

    def mount(_params, _session, socket) do
      {:ok,
       assign(socket,
         tags: [],
         all_tags: ["elixir", "phoenix"],
         resource: %{body: "Elixir and Phoenix"},
         generating_tags: false
       )}
    end

    def handle_info({:tags_generate_start, _resource}, socket) do
      # Simulate async tag generation with a delay
      Process.send_after(self(), {:tags_generated, ["elixir", "phoenix"]}, 50)
      {:noreply, assign(socket, generating_tags: true, tags: [])}
    end

    def handle_info({:tags_generated, tags}, socket) do
      {:noreply, assign(socket, tags: tags, generating_tags: false)}
    end
  end

  describe "Generate Tags button" do
    test "shows loading state and updates tags", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestLive)

      # Click the Generate tags button
      view
      |> element("#generate-tags-btn")
      |> render_click()

      # Should show loading state: button shows 'Generating...'
      html = render(view)
      assert html =~ "Generating..."

      # Wait for the simulated async tag generation
      Process.sleep(60)
      html = render(view)
      assert html =~ "elixir"
      assert html =~ "phoenix"
      refute html =~ "Generating..."
    end
  end
end
