defmodule MethodKnowWeb.LikeButtonComponentTest do
  use MethodKnowWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias MethodKnow.Resources
  alias MethodKnow.Accounts
  alias MethodKnowWeb.LikeButtonComponent

  setup do
    user_changeset =
      Accounts.User.registration_changeset(%Accounts.User{}, %{
        email: "test@example.com",
        name: "Test User",
        password: "password"
      })

    user = MethodKnow.Repo.insert!(user_changeset)

    resource_changeset =
      MethodKnow.Resources.Resource.changeset(
        %MethodKnow.Resources.Resource{},
        %{title: "Test Resource", resource_type: "article", url: "https://example.com"},
        %{user: %{id: user.id}}
      )

    resource = MethodKnow.Repo.insert!(resource_changeset)
    %{user: user, resource: resource}
  end

  test "renders like button with count and state", %{user: user, resource: resource} do
    likes_count = Resources.count_likes(resource.id)
    liked_by_user = Resources.liked_by_user?(resource.id, user.id)

    html =
      render_component(LikeButtonComponent, %{
        id: "like-btn-#{resource.id}",
        resource: resource,
        current_user: user,
        likes_count: likes_count,
        liked_by_user: liked_by_user
      })

    assert html =~ "like-btn-#{resource.id}"
    assert html =~ Integer.to_string(likes_count)
  end

  test "renders login link for anonymous users", %{resource: resource} do
    html =
      render_component(LikeButtonComponent, %{
        id: "like-btn-#{resource.id}",
        resource: resource,
        current_user: nil,
        likes_count: 5,
        liked_by_user: false
      })

    assert html =~ "Log in to like"
    assert html =~ "href=\"/users/log-in\""
    assert html =~ "5"
  end

  test "user can like and unlike a resource", %{user: user, resource: resource} do
    render_component(LikeButtonComponent, %{
      id: "like-btn-#{resource.id}",
      resource: resource,
      current_user: user,
      likes_count: 0,
      liked_by_user: false
    })

    refute Resources.liked_by_user?(resource.id, user.id)
    assert Resources.count_likes(resource.id) == 0

    # Simulate like
    Resources.like_resource(resource.id, user.id)
    assert Resources.liked_by_user?(resource.id, user.id)
    assert Resources.count_likes(resource.id) == 1

    # Simulate unlike
    Resources.unlike_resource(resource.id, user.id)
    refute Resources.liked_by_user?(resource.id, user.id)
    assert Resources.count_likes(resource.id) == 0
  end

  defmodule TestLive do
    use MethodKnowWeb, :live_view

    def render(assigns) do
      ~H"""
      <.live_component
        module={LikeButtonComponent}
        id="like-button"
        resource={@resource}
        current_user={@current_user}
        likes_count={@likes_count}
        liked_by_user={@liked_by_user}
      />
      """
    end

    def mount(_params, %{"resource" => resource, "user" => user} = session, socket) do
      {:ok,
       assign(socket,
         resource: resource,
         current_user: user,
         likes_count: session["likes_count"] || 0,
         liked_by_user: session["liked_by_user"] || false
       )}
    end
  end

  test "broadcasts PubSub message on like", %{conn: conn, user: user, resource: resource} do
    # Subscribe to the resources topic
    Phoenix.PubSub.subscribe(MethodKnow.PubSub, "resources")

    {:ok, view, _html} =
      live_isolated(conn, TestLive,
        session: %{
          "resource" => resource,
          "user" => user
        }
      )

    # Click the like button
    view
    |> element("#like-button")
    |> render_click()

    # Assert that the PubSub message was broadcast
    resource_id = resource.id
    assert_received {:resource_liked, ^resource_id, 1}
  end

  test "broadcasts PubSub message on unlike", %{conn: conn, user: user, resource: resource} do
    # Pre-like the resource
    Resources.like_resource(resource.id, user.id)
    Phoenix.PubSub.subscribe(MethodKnow.PubSub, "resources")

    {:ok, view, _html} =
      live_isolated(conn, TestLive,
        session: %{
          "resource" => resource,
          "user" => user,
          "likes_count" => 1,
          "liked_by_user" => true
        }
      )

    # Click the like button to unlike
    view
    |> element("#like-button")
    |> render_click()

    # Assert that the PubSub message was broadcast with 0 likes
    resource_id = resource.id
    assert_received {:resource_liked, ^resource_id, 0}
    # Verify DB state
    refute Resources.liked_by_user?(resource.id, user.id)
  end
end
