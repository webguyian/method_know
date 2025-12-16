defmodule MethodKnowWeb.FilterPanelComponent do
  use Phoenix.Component

  attr :resource_types, :list, required: true
  attr :selected_types, :list, required: true
  attr :all_tags, :list, required: true
  attr :selected_tags, :list, required: true
  attr :show_mobile_modal, :boolean, default: false
  attr :id, :string, default: "filter-panel"

  def filter_panel(assigns) do
    ~H"""
    <aside
      class={[
        "sticky top-4 z-20 flex flex-col gap-3 col-span-1 bg-white rounded-lg shadow-sm border border-base-200 p-6",
        @show_mobile_modal &&
          "!sticky !top-10 !col-span-1 w-full max-w-md mx-auto mt-6 animate-fade-in"
      ]}
      id={@id}
      phx-click-away={@show_mobile_modal && "toggle_filters"}
    >
      <header class="flex items-center justify-between">
        <h2 class="text-lg font-semibold">Filters</h2>
        <%= if not Enum.empty?(@selected_types) or not Enum.empty?(@selected_tags) do %>
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
        <h3 class="text-base font-normal leading-7 mb-2">Resource Type</h3>
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
                checked={value in @selected_types}
                class="checkbox checkbox-sm"
              />
              <span>{label}</span>
            </label>
          <% end %>
        </form>
      </section>
      <%= unless @all_tags == [] do %>
        <section>
          <h3 class="text-base font-normal leading-7 mb-2">Tags</h3>
          <div class="flex flex-wrap gap-2">
            <%= for tag <- @all_tags do %>
              <button
                type="button"
                phx-click={if @show_mobile_modal, do: "maybe_filter_tag", else: "filter_tag"}
                phx-value-tag={tag}
                class={[
                  "badge rounded-full cursor-pointer ",
                  if(tag in @selected_tags,
                    do: "badge-primary",
                    else: "border-neutral-300 bg-transparent"
                  )
                ]}
              >
                {tag}
              </button>
            <% end %>
          </div>
        </section>
      <% end %>
      <%= if @show_mobile_modal do %>
        <footer class="border-t border-slate-200 pt-4 mt-4 flex justify-end gap-2">
          <button
            type="button"
            class="px-4 py-2 rounded-lg border border-slate-300 bg-white text-slate-700 font-medium hover:bg-slate-50 transition"
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
