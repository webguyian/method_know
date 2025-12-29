defmodule MethodKnowWeb.ResourceLive.Index do
  use MethodKnowWeb, :live_view
  import MethodKnowWeb.FilterPanelComponent
  import MethodKnowWeb.ResourceComponents

  alias MethodKnow.Resources
  alias MethodKnow.Resources.Resource

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: current_scope}} = socket) do
    my_resources? = socket.assigns.live_action == :my
    online_users = fetch_online_users(current_scope, socket)

    {:ok,
     socket
     |> assign(default_assigns(socket, my_resources?, online_users))
     |> stream(:resources, [], reset: true)}
  end

  @impl true
  def handle_params(params, url, socket) do
    search = params["search"] || ""
    types = parse_list_param(params["types"])
    tags = parse_list_param(params["tags"])
    current_path = URI.parse(url).path

    {filtered, total} = get_resources_pair(socket.assigns, types, tags, search)

    {:noreply,
     socket
     |> assign(
       current_path: current_path,
       search: search,
       selected_types: types,
       selected_tags: tags,
       resources_empty?: Enum.empty?(filtered),
       total_resource_count: length(total),
       filtered_resource_count: length(filtered)
     )
     |> stream(:resources, filtered, reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      online_users={@online_users}
      shout={@shout}
    >
      <.resources_header
        live_action={@live_action}
        page_title={@page_title}
        resources_empty?={@resources_empty?}
        search={@search}
        selected_tags={@selected_tags}
        selected_types={@selected_types}
        show_share_button={@show_share_button}
        toast={@toast}
      />

      <div
        class="grid grid-cols-1 md:grid-cols-6 lg:grid-cols-7 xl:grid-cols-8 gap-8 py-4 items-start"
        phx-window-keyup="shout_form_show"
      >
        <%= unless @resources_empty? and @search == "" and Enum.empty?(@selected_tags) and Enum.empty?(@selected_types) do %>
          <div
            class="hidden md:block md:col-span-2 lg:col-span-2 xl:col-span-2 order-none"
            id="filters-panel"
          >
            <.filter_panel
              id="desktop-filter-panel"
              all_tags={@all_tags}
              filters={%{tags: @selected_tags, types: @selected_types}}
              resource_types={@resource_types}
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
                  current_user={@current_scope && @current_scope.user}
                  filters={%{tags: @selected_tags, types: @selected_types}}
                  on_delete="show_delete_modal"
                  on_edit="edit"
                  on_show="show"
                  resource={resource}
                />
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if @show_filters_on_mobile do %>
          <div class="fixed inset-x-0 top-0 z-40 mx-2 md:hidden flex justify-center">
            <.filter_panel
              id="mobile-filter-panel"
              all_tags={@all_tags}
              filters={%{tags: @selected_tags, types: @selected_types}}
              resource_types={@resource_types}
              show_mobile_modal={true}
            />
          </div>
        <% end %>
      </div>

      <.live_component
        module={MethodKnowWeb.ResourceLive.FormDrawer}
        id="resource-form-drawer"
        all_tags={@all_tags}
        current_scope={@current_scope}
        current_user={@current_scope && @current_scope.user}
        form_action={@form_action}
        form_params={@form_params}
        from_drawer={@from_drawer}
        generating_tags={@generating_tags}
        on_close="hide_form"
        resource={@resource}
        return_to={~p"/resources"}
        show_drawer={@show_drawer}
        selected_tags={@selected_tags}
        tags={@tags}
        title={@form_title}
      />

      <.delete_modal
        show={@show_delete_modal}
        id={@delete_resource_id}
        on_cancel="hide_delete_modal"
        on_confirm="confirm_delete"
      />
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("apply_filters", _params, socket) do
    selected_types = socket.assigns.maybe_selected_types || socket.assigns.selected_types
    selected_tags = socket.assigns.maybe_selected_tags || socket.assigns.selected_tags
    search = socket.assigns.search

    {:noreply, patch_with_filters(socket, search, selected_types, selected_tags)}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    {:ok, _} = Resources.delete_resource(socket.assigns.current_scope, resource)

    if socket.assigns.form_action == :show do
      send(self(), :close_drawer)
    end

    {:noreply,
     socket
     |> assign(:show_delete_modal, false)
     |> assign(:delete_resource_id, nil)
     |> stream_delete(:resources, resource)
     |> show_toast("Resource deleted!")}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    form_params = Resources.resource_to_form_params(resource)

    {:noreply,
     socket
     |> assign(
       form_action: :edit,
       form_title: "Edit resource",
       resource: resource,
       form_params: form_params,
       show_drawer: true,
       tags: resource.tags,
       from_drawer: false
     )}
  end

  def handle_event("edit_from_drawer", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    form_params = Resources.resource_to_form_params(resource)

    {:noreply,
     socket
     |> assign(
       form_action: :edit,
       form_params: form_params,
       form_title: "Edit resource",
       from_drawer: true,
       resource: resource,
       tags: resource.tags
     )}
  end

  def handle_event("filter_reset", _params, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.current_path)}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    selected_tags =
      if tag in socket.assigns.selected_tags do
        List.delete(socket.assigns.selected_tags, tag)
      else
        [tag | socket.assigns.selected_tags]
      end

    search = socket.assigns.search
    selected_types = socket.assigns.selected_types

    {:noreply, patch_with_filters(socket, search, selected_types, selected_tags)}
  end

  def handle_event("filter_type", %{"resource_type" => type}, socket) when is_binary(type) do
    selected_types = socket.assigns.selected_types

    new_types =
      if type in selected_types do
        List.delete(selected_types, type)
      else
        [type | selected_types]
      end

    search = socket.assigns.search
    selected_tags = socket.assigns.selected_tags

    {:noreply, patch_with_filters(socket, search, new_types, selected_tags)}
  end

  def handle_event("filter_type", %{"resource_type" => types}, socket) do
    selected_types =
      case types do
        t when is_list(t) -> t
        t when is_binary(t) -> [t]
        _ -> []
      end

    search = socket.assigns.search
    selected_tags = socket.assigns.selected_tags

    {:noreply, patch_with_filters(socket, search, selected_types, selected_tags)}
  end

  def handle_event("filter_type", %{"_target" => ["resource_type"]}, socket) do
    selected_types = []
    search = socket.assigns.search
    selected_tags = socket.assigns.selected_tags

    {:noreply, patch_with_filters(socket, search, selected_types, selected_tags)}
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

  def handle_event("show", %{"id" => id}, socket) do
    resource = Resources.get_resource!(id)

    {:noreply,
     socket
     |> assign(
       form_action: :show,
       form_title: resource.title,
       resource: resource,
       form_params: %{},
       show_drawer: true,
       tags: resource.tags,
       from_drawer: false
     )}
  end

  def handle_event("shout_form_show", %{"key" => "/"}, socket) do
    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:noreply, update(socket, :shout, &Map.put(&1, :show_form, true))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("shout_form_show", %{"key" => _key}, socket) do
    # Ignore other key events
    {:noreply, socket}
  end

  def handle_event("shout_form_show", %{}, socket) do
    handle_event("shout_form_show", %{"key" => "/"}, socket)
  end

  def handle_event("shout_form_close", _params, socket) do
    {:noreply, update(socket, :shout, &Map.put(&1, :show_form, false))}
  end

  def handle_event("shout_form_submit", %{"message" => message}, socket) do
    Phoenix.PubSub.broadcast(
      MethodKnow.PubSub,
      "users:shout",
      {:shout, %{user: socket.assigns.current_scope.user, message: message}}
    )

    handle_event("shout_form_close", %{}, socket)
  end

  def handle_event("esc_close", %{"key" => "Escape"}, socket) do
    handle_event("shout_form_close", %{}, socket)
  end

  def handle_event("esc_close", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("search", %{"search" => search}, socket) do
    search = String.trim(search || "")
    selected_types = socket.assigns.selected_types
    selected_tags = socket.assigns.selected_tags

    {:noreply, patch_with_filters(socket, search, selected_types, selected_tags)}
  end

  def handle_event("show_delete_modal", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:show_delete_modal, true)
     |> assign(:delete_resource_id, id)}
  end

  def handle_event("show_drawer", _params, socket) do
    {:noreply,
     socket
     |> assign(
       form_action: :new,
       form_title: "Share a resource",
       form_params: %{},
       resource: %Resource{},
       show_drawer: true,
       tags: [],
       from_drawer: false
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
    {:noreply,
     socket
     |> push_event("drawer_closed", %{})
     |> assign(:show_drawer, false)}
  end

  def handle_info({:form_params_updated, params}, socket) do
    {:noreply, assign(socket, :form_params, params)}
  end

  def handle_info(:hide_toast, socket) do
    {:noreply,
     socket
     |> assign(:toast, %{
       action: nil,
       message: nil,
       visible: false
     })}
  end

  def handle_info({:resource_saved, :created}, socket) do
    socket =
      socket
      |> update_all_tags()
      |> show_toast("New resource successfully added!", :created)

    {:noreply, socket}
  end

  def handle_info({:resource_saved, :updated}, socket) do
    socket =
      socket
      |> update_all_tags()
      |> show_toast("Resource updated!")

    {:noreply, socket}
  end

  def handle_info({:show_resource, id}, socket) do
    handle_event("show", %{"id" => id}, socket)
  end

  def handle_info({:tags_committed, tags}, socket) do
    {:noreply, assign(socket, all_tags: tags)}
  end

  def handle_info({:tags_generate_start, resource}, socket) do
    socket = assign(socket, generating_tags: true)
    MethodKnow.Tagging.start_tag_extraction(resource, self())
    {:noreply, socket}
  end

  def handle_info({:tags_generated, tags}, socket) do
    {:noreply,
     socket
     |> assign(generating_tags: false)
     |> assign(tags: Enum.uniq(socket.assigns.tags ++ tags))}
  end

  def handle_info({:tags_updated, tags}, socket) do
    # Merge new tags into form_params, preserving all other fields
    form_params = Map.put(socket.assigns.form_params || %{}, "tags", tags)

    {:noreply,
     socket
     |> assign(:tags, tags)
     |> assign(:form_params, form_params)}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "presence_diff", topic: "users:online"},
        socket
      ) do
    online_users =
      MethodKnowWeb.Presence.list("users:online")
      |> Enum.map(fn {_id, %{metas: [meta | _]}} -> meta end)

    {:noreply, assign(socket, online_users: online_users)}
  end

  def handle_info({:shout, %{user: user, message: message}}, socket) do
    socket =
      socket
      |> assign(:shout, %{
        user: user.email,
        message: message,
        fading: false,
        show_form: false
      })

    # After 9 seconds, start fading
    Process.send_after(self(), :shout_message_fade, 9000)
    # After 10 seconds, remove message
    Process.send_after(self(), :shout_message_clear, 10000)

    {:noreply, socket}
  end

  def handle_info(:shout_message_fade, socket) do
    {:noreply, update(socket, :shout, &Map.put(&1, :fading, true))}
  end

  def handle_info(:shout_message_clear, socket) do
    {:noreply,
     assign(socket, :shout, %{user: nil, message: nil, fading: false, show_form: false})}
  end

  def handle_info({:resource_liked, resource_id, new_like_count}, socket) do
    resource =
      Resources.get_resource!(resource_id)
      |> Map.put(:like_count, new_like_count)

    {:noreply,
     socket
     |> stream_insert(:resources, resource)
     |> push_event("resource_liked", %{resource_id: resource_id})}
  end

  defp default_assigns(_socket, my_resources?, online_users) do
    [
      all_tags: Resources.list_all_tags(),
      current_path: nil,
      delete_resource_id: nil,
      filtered_resource_count: 0,
      form_action: :new,
      form_params: %{},
      form_title: "Share a resource",
      from_drawer: false,
      generating_tags: false,
      online_users: online_users,
      page_title: if(my_resources?, do: "Your resources", else: "Discover Resources"),
      resource_types: Resources.resource_types_with_labels(),
      resource: %Resource{},
      resources_empty?: false,
      search: "",
      selected_tags: [],
      selected_types: [],
      shout: %{user: nil, message: nil, fading: false, show_form: false},
      show_delete_modal: false,
      show_drawer: false,
      show_filters_on_mobile: false,
      show_share_button: System.get_env("SHOW_SHARE_BUTTON") == "true",
      tags: [],
      toast: %{action: nil, message: nil, visible: false},
      total_resource_count: 0
    ]
  end

  defp fetch_online_users(current_scope, socket) do
    if connected?(socket) and not is_nil(current_scope) do
      Resources.subscribe_resources(current_scope)
      user = current_scope.user

      {:ok, _} =
        MethodKnowWeb.Presence.track(self(), "users:online", user.id, %{
          name: user.name,
          email: user.email
        })

      Phoenix.PubSub.subscribe(MethodKnow.PubSub, "resources")
      Phoenix.PubSub.subscribe(MethodKnow.PubSub, "users:online")
      Phoenix.PubSub.subscribe(MethodKnow.PubSub, "users:shout")

      MethodKnowWeb.Presence.list("users:online")
      |> Enum.map(fn {_id, %{metas: [meta | _]}} -> meta end)
    else
      []
    end
  end

  defp get_resources(assigns, selected_types \\ [], selected_tags \\ [], search \\ "") do
    my_resources? = assigns.live_action == :my
    current_scope = assigns.current_scope

    cond do
      my_resources? and current_scope ->
        Resources.list_resources_filtered(current_scope, selected_types, selected_tags, search)

      true ->
        Resources.list_all_resources_filtered(selected_types, selected_tags, search)
    end
  end

  defp get_resources_pair(assigns, selected_types, selected_tags, search) do
    my_resources? = assigns.live_action == :my
    current_scope = assigns.current_scope

    if my_resources? and current_scope do
      filtered =
        Resources.list_resources_filtered(current_scope, selected_types, selected_tags, search)

      total = Resources.list_resources_filtered(current_scope, selected_types, selected_tags, "")
      {filtered, total}
    else
      filtered = Resources.list_all_resources_filtered(selected_types, selected_tags, search)
      total = Resources.list_all_resources_filtered(selected_types, selected_tags, "")
      {filtered, total}
    end
  end

  defp show_toast(socket, message, action \\ nil) do
    timeout = if action == :created, do: 6000, else: 3000
    Process.send_after(self(), :hide_toast, timeout)

    socket
    |> assign(:toast, %{action: action, message: message, visible: true})
  end

  defp update_all_tags(socket) do
    assign(socket, :all_tags, Resources.list_all_tags())
  end

  defp patch_with_filters(socket, search, types, tags) do
    params =
      %{
        "search" => if(search != "", do: search),
        "types" => if(types != [], do: Enum.join(types, ",")),
        "tags" => if(tags != [], do: Enum.join(tags, ","))
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    path = socket.assigns.current_path || "/"

    if Enum.empty?(params) do
      push_patch(socket, to: path)
    else
      push_patch(socket, to: "#{path}?#{URI.encode_query(params)}")
    end
  end

  defp parse_list_param(param) do
    case param do
      nil -> []
      "" -> []
      val when is_binary(val) -> String.split(val, ",")
      val when is_list(val) -> val
      _ -> []
    end
  end
end
