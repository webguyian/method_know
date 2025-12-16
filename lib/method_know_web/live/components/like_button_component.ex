defmodule MethodKnowWeb.LikeButtonComponent do
  use MethodKnowWeb, :live_component

  alias MethodKnow.Resources

  @doc """
  Renders a like button with count and heart icon.
  Expects assigns:
    - resource: the resource struct
    - current_user: the current user struct (optional)
    - likes_count: integer
    - liked_by_user: boolean
  """
  def render(assigns) do
    ~H"""
    <button
      id={"like-btn-#{@resource.id}"}
      phx-target={@myself}
      phx-click="toggle_like"
      class={[
        "flex items-center gap-1 my-2 text-base-content/70 cursor-pointer hover:text-pink-600 transition-colors",
        @liked_by_user && "text-pink-600"
      ]}
      aria-pressed={@liked_by_user}
      title={(@liked_by_user && "Unlike") || "Like"}
    >
      <Lucide.heart class={[
        "size-5 transition-colors",
        (@liked_by_user &&
           "fill-pink-600 text-pink-600 animate-[pop_0.4s_cubic-bezier(0.175,0.885,0.32,1.27)_forwards]") ||
          ""
      ]} />
      <span class="ml-1 text-sm font-medium">{@likes_count}</span>
    </button>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("toggle_like", _params, socket) do
    resource = socket.assigns.resource
    user = socket.assigns.current_user
    liked = socket.assigns.liked_by_user

    if user do
      if liked do
        Resources.unlike_resource(resource.id, user.id)
      else
        Resources.like_resource(resource.id, user.id)
      end
    end

    likes_count = Resources.count_likes(resource.id)
    liked_by_user = user && Resources.liked_by_user?(resource.id, user.id)

    {:noreply, assign(socket, likes_count: likes_count, liked_by_user: liked_by_user)}
  end
end
