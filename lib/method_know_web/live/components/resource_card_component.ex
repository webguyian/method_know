defmodule MethodKnowWeb.ResourceCardComponent do
  use MethodKnowWeb, :live_component

  @doc """
  Renders a resource card.
  Expects assigns:
    - resource: the resource struct
    - current_user: the current user struct (optional, for actions)
    - on_edit: event name for edit (optional)
    - on_delete: event name for delete (optional)
    - on_show: event name for show details (optional)
  """
  def render(assigns) do
    ~H"""
    <div
      class="bg-base-100 min-h-70 rounded-xl shadow-md flex flex-col overflow-hidden border border-base-200 group hover:shadow-lg transition-shadow duration-150"
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
              class="icon-btn text-base-content"
              title="Edit"
            >
              <Lucide.pencil class="size-5 text-base-content/60 hover:text-base-content" />
            </button>
            <button
              type="button"
              phx-click={@on_delete}
              phx-value-id={@resource.id}
              class="icon-btn text-base-content"
              title="Delete"
            >
              <Lucide.trash_2 class="size-5 text-base-content/60 hover:text-base-content" />
            </button>
          <% end %>
        </div>
      </div>
      <div class="flex flex-col h-full px-4 pb-2">
        <h3 class="font-semibold text-lg text-base-content mb-1 truncate">
          {@resource.title}
        </h3>
        <p class="text-base-content/80 text-sm mb-2">
          {truncate_description(@resource.description)}
        </p>
        <%= if @resource.resource_type == "code_snippet" do %>
          <.code_snippet
            class="max-h-[250px]"
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
            <span class="badge badge-sm border-base-content/20 bg-transparent text-base-content/80 p-2 rounded-full">
              {tag}
            </span>
          <% end %>
        </div>
        <.live_component
          module={MethodKnowWeb.LikeButtonComponent}
          id={"like-btn-#{@resource.id}"}
          resource={@resource}
          current_user={@current_user}
          likes_count={MethodKnow.Resources.count_likes(@resource.id)}
          liked_by_user={
            @current_user && MethodKnow.Resources.liked_by_user?(@resource.id, @current_user.id)
          }
        />
      </div>
      <footer class="mt-auto hover:bg-base-200 border-t border-base-200 transition-colors">
        <button
          class="flex items-center justify-between w-full px-4 py-3 cursor-pointer"
          title="View details"
          type="button"
          phx-click={@on_show}
          phx-value-id={@resource.id}
        >
          <.avatar user={@resource.user} />
          <span class="text-xs text-base-content/60">
            {relative_date(@resource.inserted_at)}
          </span>
        </button>
      </footer>
    </div>
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
    days = DateTime.diff(DateTime.utc_now(), datetime, :day)

    cond do
      days == 0 -> "Today"
      days == 1 -> "Yesterday"
      days > 1 -> "#{days} days ago"
      true -> ""
    end
  end
end
