defmodule MethodKnow.ResourcesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MethodKnow.Resources` context.
  """

  @doc """
  Generate a resource.
  """
  def resource_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        author: "some author",
        code: "some code",
        description: "some description",
        language: "some language",
        resource_type: "article",
        tags: ["some tag"],
        title: "some title",
        url: "https://example.com"
      })

    {:ok, resource} = MethodKnow.Resources.create_resource(scope, attrs)
    resource = MethodKnow.Repo.preload(resource, :user)
    resource
  end
end
