defmodule MethodKnowWeb.ResourceLive.FormDrawer do
  use MethodKnowWeb, :live_component

  alias MethodKnow.Resources
  alias MethodKnow.Resources.Resource

  @impl true
  def update(assigns, socket) do
    # Only reset form state if resource, form_action, or show_form changed
    resource_changed = Map.get(assigns, :resource) != Map.get(socket.assigns, :resource)
    action_changed = Map.get(assigns, :form_action) != Map.get(socket.assigns, :form_action)
    show_form_changed = Map.get(assigns, :show_form) != Map.get(socket.assigns, :show_form)

    if resource_changed or action_changed or show_form_changed do
      {:ok, reset_form_state(assigns, socket)}
    else
      {:ok, assign(socket, assigns)}
    end
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
      <div class="relative my-auto ml-auto mr-10 h-[85%] translate-y-6 w-full max-w-[490px] bg-white rounded-xl shadow-xl flex flex-col animate-slide-in-right">
        <div class="flex items-start justify-between px-6 pt-4">
          <header>
            <h2 class="text-xl font-semibold text-slate-900">{@title}</h2>
            <p class="text-slate-500 text-sm">
              Contribute to the knowledge base by sharing valuable content
            </p>
          </header>
          <button
            type="button"
            class="icon-btn"
            aria-label="Close"
            phx-click={@on_close}
            phx-target={@myself}
            phx-mounted={JS.focus()}
          >
            <Lucide.x class="size-6 text-slate-400 hover:text-slate-700" />
          </button>
        </div>
        <div class="flex-1 overflow-visible px-6 py-4">
          <.live_component
            module={MethodKnowWeb.ResourceLive.FormComponent}
            id="resource-form-component"
            form={@form}
            on_close={@on_close}
            myself={@myself}
            all_tags={@all_tags}
            tags={@tags}
            form_action={@form_action}
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
    prev_params = socket.assigns[:form_params] || %{}
    merged_params = Map.merge(prev_params, resource_params)
    merged_params = Map.put(merged_params, "tags", socket.assigns.tags)

    resource = socket.assigns[:resource] || %Resource{}
    changeset = Resources.change_resource(socket.assigns.current_scope, resource, merged_params)

    # Send updated params to parent so it can keep form_params in sync
    send(self(), {:form_params_updated, merged_params})

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"resource" => resource_params}, socket) do
    resource_params = normalize_tags(resource_params)
    params = Map.put(resource_params, "tags", socket.assigns.tags)

    # Send updated params to parent so it can keep form_params in sync
    send(self(), {:form_params_updated, params})

    case Resources.create_or_update_resource(socket.assigns.current_scope, params) do
      {:ok, _resource} ->
        action = if resource_params["id"], do: :updated, else: :created
        send(self(), {:resource_saved, action})
        send(self(), :close_drawer)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_info({:tags_updated, new_tags}, socket) do
    changeset =
      Resources.change_resource(
        socket.assigns.current_scope,
        %Resource{},
        Map.put(socket.assigns.form.params || %{}, "tags", new_tags)
      )

    {:noreply,
     socket
     |> assign(:tags, new_tags)
     |> assign(:form, to_form(changeset, action: :validate))}
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

  defp reset_form_state(assigns, socket) do
    resource = assigns[:resource] || %Resource{}
    params = assigns[:form_params] || %{}
    is_new = Map.get(assigns, :form_action) == :new

    # Always clear form state if form_action is :new (Share Resource)
    changeset =
      if is_new do
        Resources.change_resource(assigns.current_scope, %Resource{}, %{})
      else
        Resources.change_resource(assigns.current_scope, resource, params)
      end

    socket
    |> assign(assigns)
    |> assign(:form, to_form(changeset))
  end
end
