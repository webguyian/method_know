defmodule MethodKnowWeb.ResourceLive.Index do
  use MethodKnowWeb, :live_view

  alias MethodKnow.Resources

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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
            current_user={@current_scope.user}
            on_edit="edit"
            on_delete="delete"
          />
        <% end %>
      </div>
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
     |> assign(:page_title, "Listing Resources")
     |> stream(:resources, list_resources())}
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

  defp list_resources do
    Resources.list_all_resources()
  end
end
