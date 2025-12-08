defmodule MethodKnowWeb.ResourceLive.Index do
  use MethodKnowWeb, :live_view

  alias MethodKnow.Resources

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Resources
        <:actions>
          <.button variant="primary" navigate={~p"/resources/new"}>
            <.icon name="hero-plus" /> New Resource
          </.button>
        </:actions>
      </.header>

      <.table
        id="resources"
        rows={@streams.resources}
        row_click={fn {_id, resource} -> JS.navigate(~p"/resources/#{resource}") end}
      >
        <:col :let={{_id, resource}} label="Title">{resource.title}</:col>
        <:col :let={{_id, resource}} label="Description">{resource.description}</:col>
        <:col :let={{_id, resource}} label="Resource type">{resource.resource_type}</:col>
        <:col :let={{_id, resource}} label="Tags">{resource.tags}</:col>
        <:col :let={{_id, resource}} label="Author">{resource.author}</:col>
        <:col :let={{_id, resource}} label="Code">{resource.code}</:col>
        <:col :let={{_id, resource}} label="Language">{resource.language}</:col>
        <:col :let={{_id, resource}} label="Url">{resource.url}</:col>
        <:action :let={{_id, resource}}>
          <div class="sr-only">
            <.link navigate={~p"/resources/#{resource}"}>Show</.link>
          </div>
          <.link navigate={~p"/resources/#{resource}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, resource}}>
          <.link
            phx-click={JS.push("delete", value: %{id: resource.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
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
     |> stream(:resources, list_resources(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)
    {:ok, _} = Resources.delete_resource(socket.assigns.current_scope, resource)

    {:noreply, stream_delete(socket, :resources, resource)}
  end

  @impl true
  def handle_info({type, %MethodKnow.Resources.Resource{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :resources, list_resources(socket.assigns.current_scope), reset: true)}
  end

  defp list_resources(current_scope) do
    Resources.list_resources(current_scope)
  end
end
