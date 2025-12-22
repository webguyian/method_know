defmodule MethodKnowWeb.FilterPanelComponent do
  use Phoenix.Component

  import MethodKnowWeb.CoreComponents

  attr :all_tags, :list, required: true
  attr :filters, :map, required: true
  attr :id, :string, default: "filter-panel"
  attr :resource_types, :list, required: true
  attr :show_mobile_modal, :boolean, default: false

  def filter_panel(assigns) do
    ~H"""
    <aside
      class={[
        "sticky top-4 z-20 flex flex-col gap-3 col-span-1 bg-base-100 rounded-lg shadow-sm border border-base-200 p-6",
        @show_mobile_modal &&
          "!sticky !top-10 !col-span-1 w-full max-w-md mx-auto mt-6 animate-fade-in"
      ]}
      id={@id}
      phx-click-away={@show_mobile_modal && "toggle_filters"}
    >
      <header class="flex items-center justify-between">
        <h2 class="text-lg font-semibold text-base-content">Filters</h2>
        <%= if not Enum.empty?(@filters.types) or not Enum.empty?(@filters.tags) do %>
          <button
            class="text-sm text-base-content underline underline-offset-4 hover:text-base-content/80 hover:no-underline transition-colors"
            id="reset-filters-btn"
            phx-click="filter_reset"
            type="button"
          >
            Reset Filters
          </button>
        <% end %>
      </header>
      <section>
        <h3 class="text-base font-normal leading-7 mb-2 text-base-content">
          Resource Type
        </h3>
        <form
          class="flex flex-col gap-2"
          phx-change={if @show_mobile_modal, do: "maybe_filter_type", else: "filter_type"}
        >
          <%= for {label, value} <- @resource_types do %>
            <label class="flex items-center gap-2">
              <input
                type="checkbox"
                name="resource_type[]"
                value={value}
                checked={value in @filters.types}
                class="checkbox checkbox-sm"
              />
              <span class="text-base-content/80">{label}</span>
            </label>
          <% end %>
        </form>
      </section>
      <%= unless @all_tags == [] do %>
        <section>
          <h3 class="text-base font-normal leading-7 mb-2 text-base-content">
            Tags
          </h3>
          <div class="flex flex-wrap gap-2">
            <%= for tag <- @all_tags do %>
              <.tag_button
                tag={tag}
                active={tag in @filters.tags}
                click={if @show_mobile_modal, do: "maybe_filter_tag", else: "filter_tag"}
              />
            <% end %>
          </div>
        </section>
      <% end %>
      <%= if @show_mobile_modal do %>
        <footer class="border-t border-slate-200 pt-4 mt-4 flex justify-end gap-2">
          <button
            type="button"
            class="btn btn-outline border-base-300 bg-base-100 text-base-content hover:bg-base-200 transition"
            phx-click="toggle_filters"
          >
            Cancel
          </button>
          <button
            type="button"
            class="px-4 py-2 rounded-lg bg-primary text-white font-semibold hover:bg-primary-dark transition shadow-sm"
            phx-click="apply_filters"
          >
            Apply Filters
          </button>
        </footer>
      <% end %>
    </aside>
    """
  end
end
