defmodule MethodKnowWeb.ResourceLive.FormDrawer do
  use MethodKnowWeb, :live_component

  alias MethodKnow.Resources
  alias MethodKnow.Resources.Resource

  @impl true
  def update(assigns, socket) do
    # Only reset form state if resource, form_action, or show_drawer changed
    resource_changed = Map.get(assigns, :resource) != Map.get(socket.assigns, :resource)
    action_changed = Map.get(assigns, :form_action) != Map.get(socket.assigns, :form_action)
    show_drawer_changed = Map.get(assigns, :show_drawer) != Map.get(socket.assigns, :show_drawer)

    if resource_changed or action_changed or show_drawer_changed do
      {:ok, reset_form_state(assigns, socket)}
    else
      {:ok, assign(socket, assigns)}
    end
  end

  attr :all_tags, :list, required: true
  attr :current_scope, :any, required: true
  attr :current_user, :map, required: false
  attr :form_action, :atom, required: true
  attr :form, :any, required: true
  attr :generating_tags, :boolean, required: false, default: false
  attr :on_close, :string, required: true
  attr :resource, :map, required: true
  attr :tags, :list, required: true
  attr :title, :string, required: true
  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-40 flex"
      phx-mounted={JS.add_class("overflow-hidden", to: "body")}
    >
      <div
        class="fixed inset-0 bg-black/30 transition-opacity"
        aria-hidden="true"
        phx-click={@on_close}
        phx-target={@myself}
        phx-stop-propagation
        phx-window-keyup="esc_close"
      >
      </div>
      <div class="w-full h-full rounded-none md:my-auto md:ml-auto md:mr-10 md:h-[85%] md:max-w-[490px] md:rounded-xl bg-base-100 shadow-xl flex flex-col animate-slide-in-right relative md:translate-y-6">
        <div class="flex items-start justify-between p-6 pb-0">
          <header class="w-full">
            <%= if @form_action == :show do %>
              <div class="flex items-center justify-between pb-2">
                <.resource_type_badge type={@resource.resource_type} />
                <div class="flex gap-2 pr-2">
                  <%= if @current_user && @resource.user_id == @current_user.id do %>
                    <button
                      type="button"
                      phx-click="edit_from_drawer"
                      phx-value-id={@resource.id}
                      class="icon-btn text-base-content"
                      title="Edit"
                    >
                      <Lucide.pencil class="size-5 text-base-content/60 hover:text-base-content" />
                    </button>
                    <button
                      type="button"
                      phx-click="show_delete_modal"
                      phx-value-id={@resource.id}
                      class="icon-btn text-base-content"
                      title="Delete"
                    >
                      <Lucide.trash_2 class="size-5 text-base-content/60 hover:text-base-content" />
                    </button>
                  <% end %>
                </div>
              </div>
            <% end %>
            <h2 class="text-xl font-semibold text-base-content">{@title}</h2>
            <%= if @form_action != :show do %>
              <p class="text-base-content/60 text-sm">
                Contribute to the knowledge base by sharing valuable content
              </p>
            <% end %>
          </header>
          <button
            type="button"
            class="icon-btn ml-2"
            aria-label="Close"
            phx-click={@on_close}
            phx-target={@myself}
            phx-mounted={JS.focus()}
          >
            <Lucide.x class="size-6 text-base-content/40 hover:text-base-content" />
          </button>
        </div>
        <div class="flex-1 overflow-y-auto p-6 pt-2">
          <%= if @form_action == :show do %>
            <.resource_display
              resource={@resource}
              current_user={@current_user}
              selected_tags={@tags}
            />
          <% else %>
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
            <.live_component
              module={MethodKnowWeb.TagFilterComponent}
              id="tag-filter"
              all_tags={@all_tags}
              tags={@tags}
              resource={@resource}
              generating_tags={@generating_tags}
            />
          <% end %>
        </div>
        <%= if @form_action != :show do %>
          <.form_actions
            form_action={@form_action}
            from_drawer={@from_drawer}
            on_close={@on_close}
            resource={@resource}
            myself={@myself}
          />
        <% end %>
      </div>
    </div>
    """
  end

  attr :form_action, :atom, required: true
  attr :from_drawer, :boolean, default: false
  attr :on_close, :string, required: true
  attr :resource, :map, required: true
  attr :myself, :any, required: true

  def form_actions(assigns) do
    ~H"""
    <div class="flex flex-row-reverse justify-end gap-2 p-6 border-t border-base-200 mt-auto bg-base-100 shrink-0 z-10">
      <.button
        form="resource-form"
        class="w-1/2"
        phx-disable-with="Saving..."
        variant="primary"
      >
        <%= if @form_action == :edit do %>
          Save Changes
        <% else %>
          Share
        <% end %>
      </.button>
      <.button
        class="w-1/2"
        type="button"
        phx-click={if @from_drawer, do: "show_resource", else: @on_close}
        phx-target={@myself}
        phx-value-id={@resource.id}
      >
        Cancel
      </.button>
    </div>
    """
  end

  attr :resource, :map, required: true
  attr :current_user, :map, required: true
  attr :selected_tags, :list, default: nil

  def resource_display(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <div class="prose max-w-none text-base-content/80">
        {@resource.description}
      </div>
      <%= if @resource.resource_type == "code_snippet" do %>
        <.code_snippet
          code={@resource.code}
          language={@resource.language}
        />
      <% end %>
      <%= if @resource.author do %>
        <div class="flex items-center gap-2 text-base-content/60 text-xs mb-2">
          <Lucide.book_open_text class="size-4" /> by {@resource.author}
        </div>
      <% end %>
      <%= if @resource.url do %>
        <.resource_link resource={@resource} />
      <% end %>
      <div class="mt-4 flex flex-wrap gap-1 mb-2">
        <%= for tag <- (@resource.tags || []) do %>
          <.tag_button
            tag={tag}
            active={assigns[:selected_tags] && tag in assigns.selected_tags}
            click="filter_tag"
          />
        <% end %>
      </div>
      <.live_component
        module={MethodKnowWeb.LikeButtonComponent}
        id={"drawer-like-btn-#{@resource.id}"}
        resource={@resource}
        current_user={@current_user}
        likes_count={MethodKnow.Resources.count_likes(@resource.id)}
        liked_by_user={
          @current_user && MethodKnow.Resources.liked_by_user?(@resource.id, @current_user.id)
        }
      />
    </div>
    """
  end

  @impl true
  def handle_event("esc_close", %{"key" => "Escape"}, socket) do
    send(self(), :close_drawer)
    {:noreply, socket}
  end

  def handle_event("esc_close", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("hide_form", _params, socket) do
    send(self(), :close_drawer)
    {:noreply, socket}
  end

  def handle_event("show_resource", %{"id" => id}, socket) do
    send(self(), {:show_resource, id})
    {:noreply, socket}
  end

  def handle_event("validate", %{"resource" => resource_params}, socket) do
    resource_params = normalize_tags(resource_params)
    prev_params = socket.assigns[:form_params] || %{}
    merged_params = Map.merge(prev_params, resource_params)
    merged_params = Map.put_new(merged_params, "tags", socket.assigns.tags)

    resource = socket.assigns[:resource] || %Resource{}
    changeset = Resources.change_resource(socket.assigns.current_scope, resource, merged_params)

    # Send updated params to parent so it can keep form_params in sync
    send(self(), {:form_params_updated, merged_params})

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"resource" => resource_params}, socket) do
    resource_params = normalize_tags(resource_params)
    params = Map.put_new(resource_params, "tags", socket.assigns.tags)

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

  def handle_event("set_resource_type", %{"value" => type}, socket) do
    # Merge new type into existing params
    params = Map.put(socket.assigns[:form_params] || %{}, "resource_type", type)

    # Send updated params to parent so it can keep form_params in sync
    send(self(), {:form_params_updated, params})

    resource = socket.assigns[:resource] || %Resource{}
    changeset = Resources.change_resource(socket.assigns.current_scope, resource, params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
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
