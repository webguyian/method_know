defmodule MethodKnowWeb.ResourceLive.Index do
  use MethodKnowWeb, :live_view

  alias MethodKnow.Resources

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.navbar_actions current_scope={@current_scope}>
        <.button variant="primary" phx-click="show_form">Share Resource</.button>
      </.navbar_actions>
      <.header>
        Discover Resources
        <:subtitle>Explore shared knowledge from our community</:subtitle>
      </.header>

      <div
        id="resources-grid"
        class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6 py-4"
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

      <%= if @show_form do %>
        <.live_component
          module={MethodKnowWeb.ResourceLive.FormDrawer}
          id="resource-form-drawer"
          current_scope={@current_scope}
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

    all_tags = [
      "book",
      "course",
      "frontend",
      "backend"
    ]

    {:ok,
     socket
     |> assign(:page_title, "Discover Resources")
     |> assign(:all_tags, all_tags)
     |> assign(:tags, [])
     |> assign(:tag_input, "")
     |> assign(:show_form, false)
     |> stream(:resources, list_resources())}
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/resources/#{id}/edit")}
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

  defp list_resources do
    Resources.list_all_resources()
  end
end
