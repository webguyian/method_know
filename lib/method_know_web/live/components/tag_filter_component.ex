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

  ## Assigns
    - :tags - list of strings (the applied tags)
    - :tag_input - string (current input value)
    - :filtered_tags - list of strings (available tags for dropdown)
    - :show_tag_dropdown - boolean (dropdown visibility)
  """
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
        phx-keyup="filter_tags"
        phx-keydown="maybe_add_tag"
        phx-hook="tagFilter"
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
    """
  end

  @impl true
  def handle_event("show_tag_dropdown", _params, socket) do
    {:noreply, assign(socket, show_tag_dropdown: true)}
  end

  def handle_event("hide_tag_dropdown", _params, socket) do
    {:noreply, assign(socket, show_tag_dropdown: false)}
  end

  def handle_event("filter_tags", %{"value" => value}, socket) do
    filtered =
      Enum.filter(socket.assigns.all_tags, fn tag ->
        String.contains?(tag, String.downcase(value))
      end)

    {:noreply, assign(socket, filtered_tags: filtered)}
  end

  def handle_event("maybe_add_tag", %{"key" => key, "value" => value}, socket) do
    tags = socket.assigns.tags || []

    if key == "Enter" do
      new_tag =
        value
        |> String.trim()
        |> String.downcase()

      new_tags =
        if new_tag != "" do
          Enum.uniq([new_tag | tags])
        else
          tags
        end

      send(self(), {:tags_updated, new_tags})

      {:noreply,
       socket
       |> assign(:tags, new_tags)
       |> assign(:tag_input, "")}
    else
      {:noreply, assign(socket, tag_input: value)}
    end
  end

  def handle_event("add_tag", %{"tag" => tag}, socket) do
    send(self(), {:tags_updated, Enum.uniq([tag | socket.assigns.tags])})

    {:noreply, assign(socket, show_tag_dropdown: false)}
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    send(self(), {:tags_updated, Enum.reject(socket.assigns.tags, &(&1 == tag))})

    {:noreply, socket}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}
end
