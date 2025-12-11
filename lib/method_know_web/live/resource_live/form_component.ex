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
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:resource_type]}
          type="select"
          label="Resource type"
          options={Resources.resource_types_with_labels()}
        />
        <%= if @form[:resource_type].value != @type_code_snippet do %>
          <.input field={@form[:url]} type="url" label="URL" />
          <.input field={@form[:author]} type="text" label="Author" />
        <% end %>
        <%= if @form[:resource_type].value == @type_code_snippet do %>
          <.input field={@form[:code]} type="textarea" label="Code" />
          <.input field={@form[:language]} type="text" label="Language" />
        <% end %>
        <.live_component
          module={MethodKnowWeb.TagFilterComponent}
          id="tag-filter"
          all_tags={@all_tags}
          tags={@tags}
          tag_input={@tag_input}
        />
        <%= if @form[:id].value do %>
          <input type="hidden" name="resource[id]" value={@form[:id].value} />
        <% end %>
        <input type="hidden" name="resource[tags]" value={Enum.join(@tags, ",")} />
        <div class="flex flex-row-reverse justify-end gap-2 mt-auto">
          <.button class="w-1/2" phx-disable-with="Saving..." variant="primary">Share</.button>
          <.button class="w-1/2" type="button" phx-click={@on_close} phx-target={@myself}>
            Cancel
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
