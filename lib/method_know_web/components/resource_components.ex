defmodule MethodKnowWeb.ResourceComponents do
  use Phoenix.Component

  import MethodKnowWeb.CoreComponents

  alias Phoenix.LiveView.JS

  # Resources header component
  attr :live_action, :atom, required: true
  attr :page_title, :string, required: true
  attr :resources_empty?, :boolean, default: false
  attr :search, :string, default: ""
  attr :selected_tags, :list, default: []
  attr :selected_types, :list, default: []
  attr :show_share_button, :boolean, default: false
  attr :toast, :map, default: %{action: nil, message: nil, visible: false}

  def resources_header(assigns) do
    ~H"""
    <%= if @toast.visible do %>
      <.toast message={@toast.message} action={@toast.action} />
    <% else %>
      <.header>
        {@page_title}
        <:subtitle>
          <%= if @live_action != :my do %>
            Explore shared knowledge from our community
          <% end %>
        </:subtitle>
        <:actions>
          <%= if @show_share_button do %>
            <.button
              id="share-resource-btn"
              class="lg:px-10 lg:py-2"
              variant="primary"
              phx-click="show_drawer"
            >
              Share Resource
            </.button>
          <% end %>
        </:actions>
      </.header>

      <%= if @resources_empty? and @search == "" and Enum.empty?(@selected_tags) and Enum.empty?(@selected_types) do %>
        <.resource_empty_state />
      <% else %>
        <div class="flex items-center gap-2 w-full mb-2">
          <div class="flex-1">
            <.search_form search={@search} />
          </div>
          <button
            type="button"
            class="ml-2 btn btn-md btn-outline bg-base-100 border-base-300 text-base-content/80 font-medium shadow-sm hover:bg-base-200 transition md:hidden h-full flex items-center gap-1 px-3 py-2 -translate-y-1 rounded-lg"
            phx-click="toggle_filters"
            id="filters-toggle-btn"
          >
            <Lucide.sliders_horizontal class="size-5 mr-1" /> Filters
          </button>
        </div>
      <% end %>
    <% end %>
    """
  end

  # Search form component
  attr :search, :string, default: ""

  def search_form(assigns) do
    ~H"""
    <form phx-change="search" class="w-full relative">
      <span class="absolute left-3 top-1/2 -translate-y-1/2 text-base-content/50 pointer-events-none z-10">
        <Lucide.search class="size-5" />
      </span>
      <.input
        name="search"
        value={@search || ""}
        type="text"
        placeholder="Search resource by title or description..."
        class="w-full text-base input input-bordered bg-base-100 text-base-content shadow-sm focus:outline-none focus:ring-2 focus:ring-primary pl-10 pr-4 rounded-md h-10 py-2"
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

  def resource_empty_state(assigns) do
    ~H"""
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
    """
  end

  # Inline toast component
  attr :message, :string, required: true
  attr :action, :atom, default: nil

  def toast(assigns) do
    ~H"""
    <div
      id="toast-message"
      tabindex="-1"
      phx-mounted={JS.focus()}
      class="w-full bg-white border border-slate-300 rounded-md flex items-center justify-between p-4 mb-4 shadow-sm animate-fade-in outline-none"
    >
      <div class="flex items-center">
        <Lucide.check class="size-9 mr-3 flex-shrink-0 text-black" />
        <span class="text-slate-800 text-base font-medium">{@message}</span>
      </div>
      <%= if @action == :created do %>
        <.link navigate="/my/resources" class="btn btn-primary">
          View Your Resources
        </.link>
      <% end %>
    </div>
    """
  end
end
