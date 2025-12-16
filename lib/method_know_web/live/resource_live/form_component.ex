defmodule MethodKnowWeb.ResourceLive.FormComponent do
  use MethodKnowWeb, :live_component

  alias MethodKnow.Resources

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:type_article, Resources.type_article())
     |> assign(:type_code_snippet, Resources.type_code_snippet())
     |> assign(:type_learning_resource, Resources.type_learning_resource())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-start h-full">
      <.form
        for={@form}
        id="resource-form"
        class="flex flex-col justify-start h-full"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.dropdown_select
          field={@form[:resource_type]}
          options={Resources.resource_types_with_labels()}
          prompt="Select Resource Type"
          change_event="set_resource_type"
          target={@myself}
        />
        <.input
          field={@form[:title]}
          type="text"
          label="Title"
          placeholder="Enter a descriptive title"
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          placeholder="Provide a detailed description"
        />
        <%= if @form[:resource_type].value != @type_code_snippet do %>
          <.input
            field={@form[:url]}
            type="url"
            label="URL"
            placeholder="https://example.com/article"
          />
          <.input
            field={@form[:author]}
            type="text"
            label="Author(s)"
            placeholder="e.g. Jane Doe, John Smith"
          />
        <% end %>
        <%= if @form[:resource_type].value == @type_code_snippet do %>
          <.input
            field={@form[:code]}
            type="textarea"
            label="Code"
            placeholder="Paste your code snippet here"
          />
          <.input
            field={@form[:language]}
            type="text"
            label="Language"
            placeholder="e.g. JavaScript, Python, Elixir"
          />
        <% end %>
        <.live_component
          module={MethodKnowWeb.TagFilterComponent}
          id="tag-filter"
          all_tags={@all_tags}
          tags={@tags}
        />
        <%= if @form[:id].value do %>
          <input type="hidden" name="resource[id]" value={@form[:id].value} />
        <% end %>
        <input type="hidden" name="resource[tags]" value={Enum.join(@tags, ",")} />
        <div class="flex flex-row-reverse justify-end gap-2 mt-auto">
          <.button
            class="w-1/2"
            phx-disable-with="Saving..."
            variant="primary"
            disabled={@form.source.changes == %{}}
          >
            <%= if @form_action == :edit do %>
              Save Changes
            <% else %>
              Share
            <% end %>
          </.button>
          <.button class="w-1/2" type="button" phx-click={@on_close} phx-target={@myself}>
            Cancel
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
