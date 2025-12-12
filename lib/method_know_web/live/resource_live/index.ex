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
        <:subtitle>Explore shared knowledge from our community</:subtitle>
      </.header>

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

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Resources.subscribe_resources(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Discover Resources")
     |> assign(:all_tags, Resources.list_all_tags())
     |> assign(:resource_types, Resources.resource_types_with_labels())
     |> assign(:selected_types, [])
     |> assign(:selected_tags, [])
     |> assign(:tags, [])
     |> assign(:tag_input, "")
     |> assign(:show_form, false)
     |> assign(:resource, nil)
     |> stream(:resources, list_resources())}
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:form_title, "Share a resource")
     |> assign(:show_form, true)
     |> assign(:tags, [])}
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

  def handle_event("filter_type", %{"resource_type" => types}, socket) do
    selected_types =
      case types do
        t when is_list(t) -> t
        t when is_binary(t) -> [t]
        _ -> []
      end

    resources = list_resources(selected_types, socket.assigns.selected_tags)

    {:noreply,
     socket
     |> assign(:selected_types, selected_types)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("filter_type", %{"_target" => ["resource_type"]}, socket) do
    selected_types = []
    resources = list_resources(selected_types, socket.assigns.selected_tags)

    {:noreply,
     socket
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

    resources = list_resources(socket.assigns.selected_types, selected_tags)

    {:noreply,
     socket
     |> assign(:selected_tags, selected_tags)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("reset_filters", _params, socket) do
    selected_tags = selected_types = []
    resources = list_resources(selected_types, selected_tags)

    {:noreply,
     socket
     |> assign(:selected_tags, selected_tags)
     |> assign(:selected_types, selected_types)
     |> stream(:resources, resources, reset: true)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    {:ok, _} = Resources.delete_resource(socket.assigns.current_scope, resource)

    {:noreply, stream_delete(socket, :resources, resource)}
  end

  @impl true
  def handle_info({type, %MethodKnow.Resources.Resource{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :resources, list_resources(), reset: true)}
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

  defp list_resources(selected_types \\ [], selected_tags \\ []) do
    Resources.list_all_resources()
    |> Enum.filter(fn resource ->
      cond do
        selected_types == [] and selected_tags == [] ->
          true

        selected_types == [] ->
          Enum.any?(selected_tags, &(&1 in (resource.tags || [])))

        selected_tags == [] ->
          resource.resource_type in selected_types

        true ->
          resource.resource_type in selected_types and
            Enum.any?(selected_tags, &(&1 in (resource.tags || [])))
      end
    end)
  end

  defp show_toast(socket, message, kind \\ :success, timeout \\ 4000) do
    Process.send_after(self(), :clear_flash, timeout)
    put_flash(socket, kind, message)
  end

  defp update_all_tags(socket) do
    assign(socket, :all_tags, Resources.list_all_tags())
  end
end
