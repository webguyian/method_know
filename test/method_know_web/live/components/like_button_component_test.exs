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
end
