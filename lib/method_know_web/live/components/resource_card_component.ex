defmodule MethodKnowWeb.ResourceCardComponent do
  use MethodKnowWeb, :live_component

  alias MethodKnow.Resources

  @doc """
  Renders a resource card.
  Expects assigns:
    - resource: the resource struct
    - current_user: the current user struct (optional, for actions)
    - on_edit: event name for edit (optional)
    - on_delete: event name for delete (optional)
  """
  def render(assigns) do
    ~H"""
    <div
      class="bg-white min-h-70 rounded-xl shadow-md flex flex-col overflow-hidden border border-slate-200 group hover:shadow-lg transition-shadow duration-150"
      id={"resources-#{@resource.id}"}
    >
      <div class="flex items-center justify-between px-4 pt-4 pb-2">
        <.resource_type_badge type={@resource.resource_type} />

        <div class="flex gap-2">
          <%= if @current_user && @resource.user_id == @current_user.id do %>
            <button
              type="button"
              phx-click={@on_edit}
              phx-value-id={@resource.id}
              class="icon-btn"
              title="Edit"
            >
              <Lucide.pencil class="size-5 text-slate-500 hover:text-slate-700" />
            </button>
            <button
              type="button"
              phx-click={@on_delete}
              phx-value-id={@resource.id}
              class="icon-btn"
              title="Delete"
            >
              <Lucide.trash_2 class="size-5 text-slate-500 hover:text-slate-700" />
            </button>
          <% end %>
        </div>
      </div>
      <div class="flex flex-col h-full px-4 pb-2">
        <h3 class="font-semibold text-lg text-slate-900 mb-1 truncate">{@resource.title}</h3>
        <p class="text-slate-700 text-sm mb-2">
          {truncate_description(@resource.description)}
        </p>
        <%= if @resource.author do %>
          <div class="flex items-center gap-2 text-slate-500 text-xs mb-2">
            <Lucide.book_open_text class="size-4" /> by {@resource.author}
          </div>
        <% end %>
        <div class="mt-auto flex flex-wrap gap-1 mb-2">
          <%= for tag <- (@resource.tags || []) do %>
            <span class="badge badge-xs border-neutral-300 bg-transparent text-slate-700 p-2 rounded-full">
              {tag}
            </span>
          <% end %>
        </div>
      </div>
      <footer class="mt-auto flex items-center justify-between px-4 py-3 bg-slate-50 border-t border-slate-100">
        <.avatar name={@resource.user.name} />
        <span class="text-xs text-slate-500">{relative_date(@resource.inserted_at)}</span>
      </footer>
    </div>
    """
  end

  # Resource type badge component
  attr :type, :string, required: true

  def resource_type_badge(assigns) do
    [article, code_snippet, learning_resource] = Resources.resource_types()

    {icon_name, label} =
      case assigns.type do
        ^article -> {"book_open", "Article"}
        ^code_snippet -> {"code_2", "Code Snippet"}
        ^learning_resource -> {"graduation_cap", "Learning Resource"}
        _ -> {"help_circle", String.capitalize(to_string(assigns.type))}
      end

    assigns = assign(assigns, icon_name: icon_name, label: label)

    ~H"""
    <span class="badge badge-sm bg-slate-100 text-slate-900 font-medium px-2 py-1 rounded-full inline-flex items-center">
      <Lucide.render icon={@icon_name} class="size-4 mr-1" />{@label}
    </span>
    """
  end

  defp truncate_description(desc) when is_binary(desc) do
    if String.length(desc) > 250 do
      String.slice(desc, 0, 247) <> "..."
    else
      desc
    end
  end

  defp truncate_description(_), do: ""

  defp relative_date(datetime) do
    # Use Timex or built-in for relative date formatting
    # For now, show as "x days ago"
    days = DateTime.diff(DateTime.utc_now(), datetime, :day)

    cond do
      days == 0 -> "Today"
      days == 1 -> "Yesterday"
      days > 1 -> "#{days} days ago"
      true -> ""
    end
  end
end
