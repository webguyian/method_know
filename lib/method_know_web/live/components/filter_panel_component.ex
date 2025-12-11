defmodule MethodKnowWeb.FilterPanelComponent do
  use Phoenix.Component

  attr :resource_types, :list, required: true
  attr :selected_types, :list, required: true
  attr :all_tags, :list, required: true
  attr :selected_tags, :list, required: true

  def filter_panel(assigns) do
    ~H"""
    <aside class="col-span-1 bg-white rounded-lg shadow-sm border border-base-200 p-6 flex flex-col gap-3">
      <h2 class="text-lg font-semibold">Filters</h2>
      <section>
        <h3 class="text-base font-normal leading-7 mb-2">Resource Type</h3>
        <form class="flex flex-col gap-2" phx-change="filter_type">
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
      <section>
        <h3 class="text-base font-normal leading-7 mb-2">Tags</h3>
        <div class="flex flex-wrap gap-2">
          <%= for tag <- @all_tags do %>
            <button
              type="button"
              phx-click="filter_tag"
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
    </aside>
    """
  end
end
