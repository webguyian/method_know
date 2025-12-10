defmodule MethodKnowWeb.ResourceLive.FormDrawer do
  use MethodKnowWeb, :live_component
  alias MethodKnow.Resources
  alias MethodKnow.Resources.Resource

  @impl true
  def update(assigns, socket) do
    changeset = Resources.change_resource(assigns.current_scope, %Resource{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 z-40 flex">
      <div
        class="fixed inset-0 bg-black/30 transition-opacity"
        aria-hidden="true"
        phx-click={@on_close}
        phx-target={@myself}
        phx-stop-propagation
        phx-window-keyup="esc_close"
      >
      </div>
      <div class="relative my-auto ml-auto mr-10 h-[85%] translate-y-6 w-full max-w-md bg-white rounded-xl shadow-xl flex flex-col animate-slide-in-right">
        <div class="flex items-start justify-between px-6 py-4 border-b border-slate-100">
          <div>
            <h2 class="text-xl font-semibold text-slate-900">Share a resource</h2>
            <p class="text-slate-500 text-sm">
              Contribute to the knowledge base by sharing valuable content
            </p>
          </div>
          <button
            type="button"
            class="icon-btn"
            aria-label="Close"
            phx-click={@on_close}
            phx-target={@myself}
          >
            <Lucide.x class="size-6 text-slate-400 hover:text-slate-700" />
          </button>
        </div>
        <div class="flex-1 overflow-y-auto px-6 py-4">
          <.live_component
            module={MethodKnowWeb.ResourceLive.FormComponent}
            id="resource-form-component"
            form={@form}
            on_close={@on_close}
            myself={@myself}
            all_tags={@all_tags}
            tags={@tags}
            tag_input={@tag_input}
          />
        </div>
      </div>
    </div>
    """
  end

  def handle_event("hide_form", _params, socket) do
    send(self(), :close_drawer)
    {:noreply, socket}
  end

  def handle_event("esc_close", %{"key" => "Escape"}, socket) do
    send(self(), :close_drawer)
    {:noreply, socket}
  end

  def handle_event("esc_close", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"resource" => resource_params}, socket) do
    resource_params = normalize_tags(resource_params)

    changeset =
      Resources.change_resource(socket.assigns.current_scope, %Resource{}, resource_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"resource" => resource_params}, socket) do
    resource_params = normalize_tags(resource_params)

    case Resources.create_resource(socket.assigns.current_scope, resource_params) do
      {:ok, _resource} ->
        send(self(), {:resource_created})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

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
