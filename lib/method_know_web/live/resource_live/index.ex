defmodule MethodKnowWeb.ResourceLive.Index do
  use MethodKnowWeb, :live_view

  import MethodKnowWeb.FilterPanelComponent

  alias MethodKnow.Resources

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%= if @toast_visible do %>
        <.toast message={@toast_message} />
      <% else %>
        <.header>
          {@page_title}
          <:subtitle>
            <%= if @live_action != :my do %>
              Explore shared knowledge from our community
            <% end %>
          </:subtitle>
        </.header>

        <%= if @resources_empty? and @search == "" do %>
          <div class="w-full flex justify-center items-center my-8">
            <div class="border border-slate-300 bg-white rounded-lg px-8 py-12 text-center shadow-sm max-w-2xl w-full">
              <div class="flex flex-col items-center gap-2">
                <Lucide.info class="size-10 text-slate-400 mb-2" />
                <h3 class="text-lg font-semibold text-slate-700 mb-1">No resources found</h3>
                <p class="text-slate-500 text-base">
                  There are currently no resources to display.
                </p>
              </div>
            </div>
          </div>
        <% else %>
          <div class="flex items-center gap-2 w-full mb-2">
            <div class="flex-1">
              <.search_form search={@search} />
            </div>
            <button
              type="button"
              class="ml-2 flex items-center gap-1 px-3 py-2 -translate-y-1 rounded-lg bg-white border border-slate-300 text-slate-700 font-medium shadow-sm hover:bg-slate-50 transition md:hidden h-full"
              phx-click="toggle_filters"
              id="filters-toggle-btn"
            >
              <Lucide.sliders_horizontal class="size-5 mr-1" /> Filters
            </button>
          </div>
        <% end %>
      <% end %>

      <div class="grid grid-cols-1 md:grid-cols-6 lg:grid-cols-7 xl:grid-cols-8 gap-8 py-4 items-start">
        <%= unless @resources_empty? and @search == "" do %>
          <div
            class="hidden md:block md:col-span-2 lg:col-span-2 xl:col-span-2 order-none"
            id="filters-panel"
          >
            <.filter_panel
              resource_types={@resource_types}
              selected_types={@selected_types}
              all_tags={@all_tags}
              selected_tags={@selected_tags}
            />
          </div>
          <div class="md:col-span-4 lg:col-span-5 xl:col-span-6">
            <.resource_count
              total={@total_resource_count}
              filtered={@filtered_resource_count}
            />
            <div
              class="order-1 grid grid-cols-1 lg:grid-cols-2 gap-6"
              id="resources-grid"
              phx-update="stream"
            >
              <%= for {id, resource} <- @streams.resources do %>
                <.live_component
                  module={MethodKnowWeb.ResourceCardComponent}
                  id={id}
                  resource={resource}
                  current_user={@current_scope && @current_scope.user}
                  on_edit="edit"
                  on_delete="show_delete_modal"
                />
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if @show_filters_on_mobile do %>
          <div class="fixed inset-x-0 top-0 z-40 mx-2 md:hidden flex justify-center">
            <.filter_panel
              resource_types={@resource_types}
              selected_types={@maybe_selected_types || @selected_types}
              all_tags={@all_tags}
              selected_tags={@maybe_selected_tags || @selected_tags}
              show_mobile_modal={true}
            />
          </div>
        <% end %>
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
          form_action={@form_action}
          form_params={@form_params}
        />
      <% end %>

      <.delete_modal
        show={@show_delete_modal}
        id={@delete_resource_id}
        on_cancel="hide_delete_modal"
        on_confirm="confirm_delete"
      />
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

  # Delete confirmation modal component
  attr :show, :boolean, required: true
  attr :id, :string, required: false
  attr :on_cancel, :string, required: true
  attr :on_confirm, :string, required: true

  def delete_modal(assigns) do
    ~H"""
    <%= if @show do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center">
        <div
          class="absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity"
          aria-hidden="true"
        >
        </div>
        <div
          class="relative bg-white rounded-md shadow-2xl max-w-lg w-full mx-4 p-6 animate-fade-in"
          phx-click-away={@on_cancel}
        >
          <h2 class="text-lg font-semibold text-slate-900 text-left leading-7 mb-2">
            Are you sure you want to delete this resource?
          </h2>
          <p class="text-slate-500 mb-6">
            This action cannot be undone. This will permanently delete your resource and remove your data from our servers.
          </p>
          <div class="flex justify-end gap-3 w-full">
            <button
              type="button"
              class="px-4 py-2 rounded-lg border border-slate-300 bg-white text-slate-700 font-medium hover:bg-slate-50 transition"
              id="cancel-delete-btn"
              phx-click={@on_cancel}
              phx-mounted={JS.focus()}
            >
              Cancel
            </button>
            <button
              type="button"
              class="px-4 py-2 rounded-lg bg-primary text-white font-semibold hover:bg-primary-dark transition shadow-sm"
              id="confirm-delete-btn"
              phx-click={@on_confirm}
              phx-value-id={@id}
            >
              Continue
            </button>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # Resource count display component
  attr :total, :integer, required: true
  attr :filtered, :integer, required: true

  def resource_count(assigns) do
    ~H"""
    <p class="mb-4 text-base-content text-base font-normal leading-7" id="resource-count">
      <%= cond do %>
        <% @filtered < @total && @filtered > 0 -> %>
          {"#{@filtered} out of #{@total} resources showing"}
        <% @filtered > 0 -> %>
          {"#{@filtered} resources found"}
        <% true -> %>
          {"No resources found"}
      <% end %>
    </p>
    """
  end

  # Inline toast component
  attr :message, :string, required: true

  def toast(assigns) do
    ~H"""
    <div class="w-full bg-white border border-slate-300 rounded-md flex items-center p-4 mb-4 shadow-sm animate-fade-in">
      <Lucide.check class="size-9 mr-3 flex-shrink-0 text-black" />
      <span class="text-slate-800 text-base font-medium">{@message}</span>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: current_scope}} = socket) do
    if connected?(socket) and current_scope do
      Resources.subscribe_resources(current_scope)
    end

    my_resources? = socket.assigns.live_action == :my
    {filtered_resources, all_resources} = get_resources_pair(socket.assigns, [], [], "")

    resources = get_resources(socket.assigns)

    {:ok,
     socket
     |> assign(
       page_title: if(my_resources?, do: "Your resources", else: "Discover Resources"),
       all_tags: Resources.list_all_tags(),
       delete_resource_id: nil,
       form_action: :new,
       form_params: %{},
       resource: nil,
       resource_types: Resources.resource_types_with_labels(),
       selected_types: [],
       selected_tags: [],
       show_delete_modal: false,
       show_form: false,
       search: "",
       tags: [],
       show_filters_on_mobile: false,
       toast_message: nil,
       toast_visible: false,
       resources_empty?: Enum.empty?(resources),
       total_resource_count: length(all_resources),
       filtered_resource_count: length(filtered_resources)
     )
     |> stream(:resources, filtered_resources)}
  end

  @impl true

  def handle_event("apply_filters", _params, socket) do
    selected_types = socket.assigns.maybe_selected_types || socket.assigns.selected_types
    selected_tags = socket.assigns.maybe_selected_tags || socket.assigns.selected_tags

    {filtered, total} =
      get_resources_pair(socket.assigns, selected_types, selected_tags, socket.assigns.search)

    {:noreply,
     socket
     |> assign(
       maybe_selected_tags: nil,
       maybe_selected_types: nil,
       selected_tags: selected_tags,
       selected_types: selected_types,
       show_filters_on_mobile: false,
       resources_empty?: Enum.empty?(filtered),
       total_resource_count: length(total),
       filtered_resource_count: length(filtered)
     )
     |> stream(:resources, filtered, reset: true)}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    {:ok, _} = Resources.delete_resource(socket.assigns.current_scope, resource)

    {:noreply,
     socket
     |> assign(:show_delete_modal, false)
     |> assign(:delete_resource_id, nil)
     |> stream_delete(:resources, resource)
     |> show_toast("Resource deleted!")}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    # Set form_params to the resource's fields for editing
    form_params = %{
      "resource_type" => resource.resource_type,
      "title" => resource.title,
      "description" => resource.description,
      "url" => resource.url,
      "author" => resource.author,
      "code" => resource.code,
      "language" => resource.language,
      "tags" => resource.tags || []
    }

    {:noreply,
     socket
     |> assign(
       form_action: :edit,
       form_title: "Edit resource",
       resource: resource,
       form_params: form_params,
       show_form: true,
       tags: resource.tags || []
     )}
  end

  def handle_event("filter_reset", _params, socket) do
    selected_tags = []
    selected_types = []

    {filtered, total} =
      get_resources_pair(socket.assigns, selected_types, selected_tags, socket.assigns.search)

    socket =
      if socket.assigns.show_filters_on_mobile do
        socket
        |> assign(maybe_selected_tags: [], maybe_selected_types: [])
      else
        socket
        |> assign(:selected_tags, selected_tags)
        |> assign(:selected_types, selected_types)
        |> assign(:maybe_selected_tags, nil)
        |> assign(:maybe_selected_types, nil)
        |> assign(:resources_empty?, Enum.empty?(filtered))
        |> assign(:total_resource_count, length(total))
        |> assign(:filtered_resource_count, length(filtered))
        |> stream(:resources, filtered, reset: true)
      end

    {:noreply, socket}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    selected_tags =
      if tag in socket.assigns.selected_tags do
        List.delete(socket.assigns.selected_tags, tag)
      else
        [tag | socket.assigns.selected_tags]
      end

    {filtered, total} =
      get_resources_pair(
        socket.assigns,
        socket.assigns.selected_types,
        selected_tags,
        socket.assigns.search
      )

    {:noreply,
     socket
     |> assign(:selected_tags, selected_tags)
     |> assign(:resources_empty?, Enum.empty?(filtered))
     |> assign(:total_resource_count, length(total))
     |> assign(:filtered_resource_count, length(filtered))
     |> stream(:resources, filtered, reset: true)}
  end

  def handle_event("filter_type", %{"resource_type" => types}, socket) do
    selected_types =
      case types do
        t when is_list(t) -> t
        t when is_binary(t) -> [t]
        _ -> []
      end

    {filtered, total} =
      get_resources_pair(
        socket.assigns,
        selected_types,
        socket.assigns.selected_tags,
        socket.assigns.search
      )

    {:noreply,
     socket
     |> assign(:selected_types, selected_types)
     |> assign(:resources_empty?, Enum.empty?(filtered))
     |> assign(:total_resource_count, length(total))
     |> assign(:filtered_resource_count, length(filtered))
     |> stream(:resources, filtered, reset: true)}
  end

  def handle_event("filter_type", %{"_target" => ["resource_type"]}, socket) do
    selected_types = []

    {filtered, total} =
      get_resources_pair(
        socket.assigns,
        selected_types,
        socket.assigns.selected_tags,
        socket.assigns.search
      )

    {:noreply,
     socket
     |> assign(:selected_types, selected_types)
     |> assign(:resources_empty?, Enum.empty?(filtered))
     |> assign(:total_resource_count, length(total))
     |> assign(:filtered_resource_count, length(filtered))
     |> stream(:resources, filtered, reset: true)}
  end

  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_delete_modal, false)
     |> assign(:delete_resource_id, nil)}
  end

  def handle_event("hide_tag_dropdown", _params, socket) do
    # No-op handler after form is hidden
    {:noreply, socket}
  end

  def handle_event("maybe_filter_tag", %{"tag" => tag}, socket) do
    maybe_selected_tags =
      if tag in (socket.assigns.maybe_selected_tags || socket.assigns.selected_tags) do
        List.delete(socket.assigns.maybe_selected_tags || socket.assigns.selected_tags, tag)
      else
        [tag | socket.assigns.maybe_selected_tags || socket.assigns.selected_tags]
      end

    {:noreply, assign(socket, :maybe_selected_tags, maybe_selected_tags)}
  end

  def handle_event("maybe_filter_type", %{"resource_type" => types}, socket) do
    maybe_selected_types =
      case types do
        t when is_list(t) -> t
        t when is_binary(t) -> [t]
        _ -> []
      end

    {:noreply, assign(socket, :maybe_selected_types, maybe_selected_types)}
  end

  def handle_event("maybe_filter_type", %{"_target" => ["resource_type"]}, socket) do
    {:noreply, assign(socket, :maybe_selected_types, [])}
  end

  def handle_event("search", %{"search" => search}, socket) do
    search = String.trim(search || "")

    selected_types = socket.assigns.selected_types
    selected_tags = socket.assigns.selected_tags
    {filtered, total} = get_resources_pair(socket.assigns, selected_types, selected_tags, search)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:resources_empty?, Enum.empty?(filtered))
     |> assign(:total_resource_count, length(total))
     |> assign(:filtered_resource_count, length(filtered))
     |> stream(:resources, filtered, reset: true)}
  end

  def handle_event("show_delete_modal", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:show_delete_modal, true)
     |> assign(:delete_resource_id, id)}
  end

  def handle_event("show_form", _params, socket) do
    {:noreply,
     socket
     |> assign(
       form_action: :new,
       form_title: "Share a resource",
       form_params: %{},
       resource: nil,
       show_form: true,
       tags: []
     )}
  end

  def handle_event("toggle_filters", _params, socket) do
    show = !socket.assigns.show_filters_on_mobile

    socket =
      if show do
        assign(socket,
          show_filters_on_mobile: true,
          maybe_selected_types: socket.assigns.selected_types,
          maybe_selected_tags: socket.assigns.selected_tags
        )
      else
        assign(socket,
          show_filters_on_mobile: false,
          maybe_selected_types: nil,
          maybe_selected_tags: nil
        )
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({type, %MethodKnow.Resources.Resource{}}, socket)
      when type in [:created, :updated, :deleted] do
    resources = get_resources(socket.assigns)

    {:noreply,
     socket
     |> assign(:resources_empty?, Enum.empty?(resources))
     |> stream(:resources, resources, reset: true)}
  end

  def handle_info(:close_drawer, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  def handle_info({:form_params_updated, params}, socket) do
    {:noreply, assign(socket, :form_params, params)}
  end

  def handle_info(:hide_toast, socket) do
    {:noreply, socket |> assign(:toast_visible, false) |> assign(:toast_message, nil)}
  end

  def handle_info({:resource_saved, :created}, socket) do
    socket =
      socket
      |> update_all_tags()
      |> show_toast("New resource successfully added!")

    {:noreply, socket}
  end

  def handle_info({:resource_saved, :updated}, socket) do
    socket =
      socket
      |> update_all_tags()
      |> show_toast("Resource updated!")

    {:noreply, socket}
  end

  def handle_info({:tags_committed, tags}, socket) do
    {:noreply, assign(socket, all_tags: tags)}
  end

  def handle_info({:tags_updated, tags}, socket) do
    # Merge new tags into form_params, preserving all other fields
    form_params = Map.put(socket.assigns.form_params || %{}, "tags", tags)

    {:noreply,
     socket
     |> assign(:tags, tags)
     |> assign(:form_params, form_params)}
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

  defp get_resources_pair(assigns, selected_types, selected_tags, search) do
    my_resources? = assigns.live_action == :my
    current_scope = assigns.current_scope

    if my_resources? and current_scope do
      filtered = list_resources(current_scope, selected_types, selected_tags, search)
      total = list_resources(current_scope, selected_types, selected_tags, "")
      {filtered, total}
    else
      filtered = list_all_resources(selected_types, selected_tags, search)
      total = list_all_resources(selected_types, selected_tags, "")
      {filtered, total}
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

  defp show_toast(socket, message) do
    Process.send_after(self(), :hide_toast, 3000)

    socket
    |> assign(:toast_message, message)
    |> assign(:toast_visible, true)
  end

  defp update_all_tags(socket) do
    assign(socket, :all_tags, Resources.list_all_tags())
  end
end
