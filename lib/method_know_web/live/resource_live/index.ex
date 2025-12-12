defmodule MethodKnowWeb.ResourceLive.Index do
  use MethodKnowWeb, :live_view

  import MethodKnowWeb.FilterPanelComponent

  alias MethodKnow.Resources

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>
          <%= if @live_action != :my do %>
            Explore shared knowledge from our community
          <% end %>
        </:subtitle>
      </.header>

      <.search_form search={@search} />

      <div class="grid grid-cols-5 gap-8 py-4 items-start">
        <.filter_panel
          resource_types={@resource_types}
          selected_types={@selected_types}
          all_tags={@all_tags}
          selected_tags={@selected_tags}
        />

        <div
          id="resources-grid"
          class="col-span-4 grid grid-cols-1 sm:grid-cols-2 gap-6"
          phx-update="stream"
        >
          <%= for {id, resource} <- @streams.resources do %>
            <.live_component
              module={MethodKnowWeb.ResourceCardComponent}
              id={id}
              resource={resource}
              current_user={@current_scope && @current_scope.user}
              on_edit="edit"
              on_delete="delete"
            />
          <% end %>
        </div>
      </div>

      <%= if @show_form do %>
        <.live_component
          module={MethodKnowWeb.ResourceLive.FormDrawer}
          id="resource-form-drawer"
          current_scope={@current_scope}
          title={@form_title}
          resource={@resource}
          return_to={~p"/resources"}
          on_close="hide_form"
          all_tags={@all_tags}
          tags={@tags}
          tag_input={@tag_input}
        />
      <% end %>
    </Layouts.app>
    """
  end

  # Search form component
  attr :search, :string, default: ""

  def search_form(assigns) do
    ~H"""
    <form phx-change="search" class="w-full relative">
      <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
        <Lucide.search class="size-5" />
      </span>
      <.input
        name="search"
        value={@search || ""}
        type="text"
        placeholder="Search resource by title or description..."
        class="w-full text-base pl-10 pr-4 py-2 bg-white border border-slate-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-primary"
        autocomplete="off"
      />
    </form>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: current_scope}} = socket) do
    if connected?(socket) and current_scope do
      Resources.subscribe_resources(current_scope)
    end

    my_resources? = socket.assigns.live_action == :my

    {:ok,
     socket
     |> assign(
       page_title: if(my_resources?, do: "Your resources", else: "Discover Resources"),
       all_tags: Resources.list_all_tags(),
       resource_types: Resources.resource_types_with_labels(),
       selected_types: [],
       selected_tags: [],
       tags: [],
       tag_input: "",
       show_form: false,
       search: "",
       resource: nil
     )
     |> stream(:resources, get_resources(socket.assigns))}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)

    {:noreply,
     socket
     |> assign(:resource, resource)
     |> assign(:form_title, "Edit resource")
     |> assign(:tags, resource.tags || [])
     |> assign(:show_form, true)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    {:ok, _} = Resources.delete_resource(socket.assigns.current_scope, resource)

    {:noreply, stream_delete(socket, :resources, resource)}
  end

  def handle_event("filter_reset", _params, socket) do
    selected_tags = selected_types = []
    resources = get_resources(socket.assigns, selected_types, selected_tags)

    {:noreply,
     socket
     |> assign(:selected_tags, selected_tags)
     |> assign(:selected_types, selected_types)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    selected_tags =
      if tag in socket.assigns.selected_tags do
        List.delete(socket.assigns.selected_tags, tag)
      else
        [tag | socket.assigns.selected_tags]
      end

    resources = get_resources(socket.assigns, socket.assigns.selected_types, selected_tags)

    {:noreply,
     socket
     |> assign(:selected_tags, selected_tags)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("filter_type", %{"resource_type" => types}, socket) do
    selected_types =
      case types do
        t when is_list(t) -> t
        t when is_binary(t) -> [t]
        _ -> []
      end

    resources = get_resources(socket.assigns, selected_types, socket.assigns.selected_tags)

    {:noreply,
     socket
     |> assign(:selected_types, selected_types)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("filter_type", %{"_target" => ["resource_type"]}, socket) do
    selected_types = []
    resources = get_resources(socket.assigns, selected_types, socket.assigns.selected_tags)

    {:noreply,
     socket
     |> assign(:selected_types, selected_types)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("search", %{"search" => search}, socket) do
    search = String.trim(search || "")

    resources =
      get_resources(
        socket.assigns,
        socket.assigns.selected_types,
        socket.assigns.selected_tags,
        search
      )

    {:noreply,
     socket
     |> assign(:search, search)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:form_title, "Share a resource")
     |> assign(:show_form, true)
     |> assign(:tags, [])}
  end

  @impl true
  def handle_info({type, %MethodKnow.Resources.Resource{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :resources, get_resources(socket.assigns), reset: true)}
  end

  def handle_info(:close_drawer, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_info({:resource_saved, :created}, socket) do
    socket =
      socket
      |> update_all_tags()
      |> show_toast("Resource created successfully")

    {:noreply, socket}
  end

  def handle_info({:resource_saved, :updated}, socket) do
    socket =
      socket
      |> update_all_tags()
      |> show_toast("Resource updated successfully")

    {:noreply, socket}
  end

  def handle_info({:tags_updated, tags}, socket) do
    {:noreply, assign(socket, tags: tags)}
  end

  def handle_info({:tags_committed, tags}, socket) do
    {:noreply, assign(socket, all_tags: tags)}
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp get_resources(assigns, selected_types \\ [], selected_tags \\ [], search \\ "") do
    my_resources? = assigns.live_action == :my
    current_scope = assigns.current_scope

    cond do
      my_resources? and current_scope ->
        list_resources(current_scope, selected_types, selected_tags, search)

      true ->
        list_all_resources(selected_types, selected_tags, search)
    end
  end

  defp list_all_resources(selected_types, selected_tags, search) do
    Resources.list_all_resources()
    |> Enum.filter(
      &(type_match(&1, selected_types) and
          tag_match(&1, selected_tags) and
          search_match(&1, search))
    )
  end

  defp list_resources(current_scope, selected_types, selected_tags, search) do
    Resources.list_resources(current_scope)
    |> Enum.filter(
      &(type_match(&1, selected_types) and
          tag_match(&1, selected_tags) and
          search_match(&1, search))
    )
  end

  defp type_match(_resource, []), do: true
  defp type_match(resource, selected_types), do: resource.resource_type in selected_types

  defp tag_match(_resource, []), do: true

  defp tag_match(resource, selected_tags),
    do: Enum.any?(selected_tags, &(&1 in (resource.tags || [])))

  defp search_match(_resource, ""), do: true

  defp search_match(resource, search) do
    search = String.downcase(search)

    search_field(resource.title, search) or
      search_field(resource.description, search)
  end

  defp search_field(field, search) do
    field
    |> Kernel.||("")
    |> String.downcase()
    |> String.contains?(search)
  end

  defp show_toast(socket, message, kind \\ :success, timeout \\ 4000) do
    Process.send_after(self(), :clear_flash, timeout)
    put_flash(socket, kind, message)
  end

  defp update_all_tags(socket) do
    assign(socket, :all_tags, Resources.list_all_tags())
  end
end
