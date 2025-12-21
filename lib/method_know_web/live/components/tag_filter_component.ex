defmodule MethodKnowWeb.TagFilterComponent do
  use MethodKnowWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:tags, fn -> [] end)
      |> assign_new(:tag_input, fn -> "" end)
      |> assign(:filtered_tags, assigns[:all_tags] || [])
      |> assign(:show_tag_dropdown, false)

    {:ok, socket}
  end

  @doc """
  Renders the tag filter component.
  """
  attr :all_tags, :list, default: []
  attr :filtered_tags, :list, default: []
  attr :generating_tags, :boolean, default: false
  attr :resource, :map, default: %{}
  attr :show_tag_dropdown, :boolean, default: false
  attr :tag_input, :string, default: ""
  attr :tags, :list, default: []

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  @impl true
  def render(assigns) do
    ~H"""
    <div class="mb-4 relative">
      <label class="label text-xs mb-1">Tags</label>
      <%= if @tags != [] do %>
        <div class="flex flex-wrap gap-2 mb-2">
          <%= for tag <- @tags do %>
            <span class="badge badge-primary badge-sm p-2 rounded-full flex items-center">
              {tag}
              <button
                type="button"
                class="hover:text-white/70"
                phx-click="remove_tag"
                phx-value-tag={tag}
                phx-target={@myself}
                aria-label="Remove tag"
              >
                <Lucide.x class="size-3" />
              </button>
            </span>
          <% end %>
        </div>
      <% end %>
      <form
        phx-submit="submit_tag"
        phx-change="change_tag_input"
        phx-target={@myself}
        class="flex gap-2 w-full"
      >
        <div class="relative w-full">
          <input
            type="text"
            id="tag_input"
            name="tag_input"
            value={@tag_input}
            class="input input-bordered w-full"
            placeholder="Add tag"
            autocomplete="off"
            phx-target={@myself}
            phx-focus="show_tag_dropdown"
            phx-debounce="200"
          />
          <div
            id="tag-dropdown"
            class="absolute left-0 right-0 mt-1 max-h-26 overflow-auto bg-base-100 border border-base-200 rounded shadow z-10 text-base-content"
            style={if @show_tag_dropdown, do: "display: block;", else: "display: none;"}
            phx-capture-click
            phx-stop-propagation
          >
            <% applied_tags = @tags %>
            <%= for tag <- (@filtered_tags) |> Enum.reject(&(&1 in applied_tags)) do %>
              <button
                type="button"
                class="px-3 py-2 w-full text-left cursor-pointer hover:bg-base-200 hover:text-base-content"
                phx-click="add_tag"
                phx-value-tag={tag}
                phx-target={@myself}
              >
                {tag}
              </button>
            <% end %>
          </div>
        </div>
        <button
          type="submit"
          class="btn btn-outline"
          aria-label="Add Tag"
          phx-disable-with="..."
        >
          Add
        </button>
      </form>
      <div class="mt-2 flex w-full">
        <button
          type="button"
          class={[
            "text-primary text-sm font-medium px-0 py-0 bg-transparent border-none hover:underline focus:underline focus:outline-none flex items-center gap-1",
            @generating_tags && "opacity-60 cursor-wait pointer-events-none"
          ]}
          style="min-width: 0;"
          phx-click="generate_tags"
          phx-target={@myself}
          disabled={@generating_tags}
          id="generate-tags-btn"
        >
          <Lucide.sparkles class={[@generating_tags && "animate-spin", "size-4"]} />
          <span>
            <%= if @generating_tags do %>
              Generating...
            <% else %>
              Generate tags
            <% end %>
          </span>
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("show_tag_dropdown", _params, socket) do
    {:noreply, assign(socket, show_tag_dropdown: true)}
  end

  def handle_event("hide_tag_dropdown", _params, socket) do
    {:noreply, assign(socket, show_tag_dropdown: false)}
  end

  def handle_event("change_tag_input", %{"tag_input" => value}, socket) do
    filtered =
      Enum.filter(socket.assigns.all_tags, fn tag ->
        String.contains?(tag, String.downcase(value))
      end)

    {:noreply, assign(socket, filtered_tags: filtered, tag_input: value)}
  end

  def handle_event("add_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)

    if tag != "" do
      new_tags = Enum.uniq([tag | socket.assigns.tags])
      send(self(), {:tags_updated, new_tags})
      {:noreply, assign(socket, tags: new_tags, tag_input: "", show_tag_dropdown: false)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("submit_tag", %{"tag_input" => tag}, socket) do
    tag = String.trim(tag) |> String.downcase()

    if tag != "" do
      new_tags = Enum.uniq([tag | socket.assigns.tags])
      send(self(), {:tags_updated, new_tags})
      {:noreply, assign(socket, tags: new_tags, tag_input: "", show_tag_dropdown: false)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    new_tags = Enum.reject(socket.assigns.tags, &(&1 == tag))
    send(self(), {:tags_updated, new_tags})
    {:noreply, assign(socket, tags: new_tags)}
  end

  def handle_event("generate_tags", _params, socket) do
    send(self(), {:tags_generate_start, socket.assigns.resource})
    {:noreply, socket}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}
end
