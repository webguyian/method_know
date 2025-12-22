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
    <div class="inline-flex my-2">
      <%= if @current_user do %>
        <button
          id={@id}
          phx-target={@myself}
          phx-click="toggle_like"
          phx-hook=".LikeButton"
          class={[
            "flex items-center gap-1 text-base-content/70 cursor-pointer hover:text-pink-600 transition-colors",
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
        <script :type={Phoenix.LiveView.ColocatedHook} name=".LikeButton">
          export default {
          mounted() {
            const animationClass = "animate-[pop_0.4s_cubic-bezier(0.175,0.885,0.32,1.27)_forwards]";
            const fillClass = "fill-pink-600";
            const textClass = "text-pink-600";
            const btnClasses = [fillClass, textClass, animationClass];

            this.handleEvent("resource_liked", ({ resource_id }) => {
              if (this.el.id === `like-btn-${resource_id}`) {
                this.el.classList.add(textClass);
                const heart = this.el.querySelector("svg");
                if (heart) {
                  heart.classList.add(...btnClasses);
                  heart.addEventListener(
                    "animationend",
                    () => {
                      this.el.classList.remove(textClass);
                      heart.classList.remove(...btnClasses);
                    },
                    { once: true }
                  );
                }
              }
            });
          }
          }
        </script>
      <% else %>
        <a
          id={"#{@id}-link"}
          href="/users/log-in"
          class="flex items-center gap-1 my-2 text-base-content/70 cursor-pointer hover:text-pink-600 transition-colors "
          title="Log in to like"
        >
          <Lucide.heart class="size-5 transition-colors " />
          <span class="ml-1 text-sm font-medium">{@likes_count}</span>
        </a>
      <% end %>
    </div>
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

    Phoenix.PubSub.broadcast(
      MethodKnow.PubSub,
      "resources",
      {:resource_liked, resource.id, Resources.count_likes(resource.id)}
    )

    likes_count = Resources.count_likes(resource.id)
    liked_by_user = user && Resources.liked_by_user?(resource.id, user.id)

    {:noreply, assign(socket, likes_count: likes_count, liked_by_user: liked_by_user)}
  end
end
