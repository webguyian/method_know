defmodule MethodKnowWeb.ResourceLive.Form do
  use MethodKnowWeb, :live_view

  alias MethodKnow.Resources
  alias MethodKnow.Resources.Resource

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage resource records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="resource-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:resource_type]} type="select" label="Resource type" options={Resource.resource_types()} />
    <%= if @form[:resource_type].value in ["article", "learning_resource"] do %>
          <.input field={@form[:url]} type="url" label="URL" />
        <% end %>
    <%= if @form[:resource_type].value == "learning_resource" do %>
          <.input field={@form[:author]} type="text" label="Author" />
        <% end %>
    <%= if @form[:resource_type].value == "code_snippet" do %>
          <.input field={@form[:code]} type="textarea" label="Code" />
          <.input field={@form[:language]} type="text" label="Language" />
        <% end %>
        <.input field={@form[:tags]} type="textarea" label="Tags" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Resource</.button>
          <.button navigate={return_path(@current_scope, @return_to, @resource)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    resource = Resources.get_resource!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Resource")
    |> assign(:resource, resource)
    |> assign(:form, to_form(Resources.change_resource(socket.assigns.current_scope, resource)))
  end

  defp apply_action(socket, :new, _params) do
    resource = %Resource{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Resource")
    |> assign(:resource, resource)
    |> assign(:form, to_form(Resources.change_resource(socket.assigns.current_scope, resource)))
  end

  @impl true
  def handle_event("validate", %{"resource" => resource_params}, socket) do
    resource_params = normalize_tags(resource_params)
    changeset = Resources.change_resource(socket.assigns.current_scope, socket.assigns.resource, resource_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"resource" => resource_params}, socket) do
    resource_params = normalize_tags(resource_params)
    save_resource(socket, socket.assigns.live_action, resource_params)
  end

  defp save_resource(socket, :edit, resource_params) do
    case Resources.update_resource(socket.assigns.current_scope, socket.assigns.resource, resource_params) do
      {:ok, resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Resource updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, resource)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_resource(socket, :new, resource_params) do
    case Resources.create_resource(socket.assigns.current_scope, resource_params) do
      {:ok, resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Resource created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, resource)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _resource), do: ~p"/resources"
  defp return_path(_scope, "show", resource), do: ~p"/resources/#{resource}"

  defp normalize_tags(params) do
    if is_binary(params["tags"]) do
      tags =
        params["tags"]
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      Map.put(params, "tags", tags)
    else
      params
    end
  end
end
