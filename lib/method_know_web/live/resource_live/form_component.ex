defmodule MethodKnowWeb.ResourceLive.FormComponent do
  use MethodKnowWeb, :live_component
  alias MethodKnow.Resources.Resource

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="resource-form"
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
          options={Resource.resource_types()}
        />
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
        <div class="flex justify-end gap-2 mt-8">
          <.button phx-disable-with="Saving..." variant="primary">Share</.button>
          <.button type="button" phx-click={@on_close} phx-target={@myself}>
            Cancel
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
