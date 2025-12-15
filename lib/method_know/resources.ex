defmodule MethodKnow.Resources do
  @moduledoc """
  The Resources context.
  """

  import Ecto.Query, warn: false
  alias MethodKnow.Repo

  alias MethodKnow.Resources.Resource
  alias MethodKnow.Accounts.Scope

  @type_article "article"
  @type_code_snippet "code_snippet"
  @type_learning_resource "learning_resource"

  def type_article, do: @type_article
  def type_code_snippet, do: @type_code_snippet
  def type_learning_resource, do: @type_learning_resource
  def resource_types, do: [@type_article, @type_code_snippet, @type_learning_resource]

  def resource_types_with_labels do
    [
      {"Article", @type_article},
      {"Code Snippet", @type_code_snippet},
      {"Learning Resource", @type_learning_resource}
    ]
  end

  @doc """
  Subscribes to scoped notifications about any resource changes.

  The broadcasted messages match the pattern:

    * {:created, %Resource{}}
    * {:updated, %Resource{}}
    * {:deleted, %Resource{}}

  """
  def subscribe_resources(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(MethodKnow.PubSub, "user:#{key}:resources")
  end

  defp broadcast_resource(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(MethodKnow.PubSub, "user:#{key}:resources", message)
  end

  @doc """
  Returns all resources in the database, preloading the user association.

  ## Examples

      iex> list_all_resources()
      [%Resource{}, ...]
  """
  def list_all_resources do
    Resource
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Returns the list of resources.

  ## Examples

      iex> list_resources(scope)
      [%Resource{}, ...]

  """
  def list_resources(%Scope{} = scope) do
    Resource
    |> where([r], r.user_id == ^scope.user.id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single resource.

  Raises `Ecto.NoResultsError` if the Resource does not exist.

  ## Examples

      iex> get_resource!(id)
      %Resource{}

      iex> get_resource!(scope, 123)
      %Resource{}

      iex> get_resource!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_resource!(id) do
    Resource
    |> Repo.get!(id)
  end

  def get_resource!(%Scope{} = scope, id) do
    Resource
    |> Repo.get_by!(id: id, user_id: scope.user.id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a resource.

  ## Examples

      iex> create_resource(scope, %{field: value})
      {:ok, %Resource{}}

      iex> create_resource(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource(%Scope{} = scope, attrs) do
    with {:ok, resource = %Resource{}} <-
           %Resource{}
           |> Resource.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_resource(scope, {:created, resource})
      {:ok, resource}
    end
  end

  @doc """
  Updates a resource.

  ## Examples

      iex> update_resource(scope, resource, %{field: new_value})
      {:ok, %Resource{}}

      iex> update_resource(scope, resource, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource(%Scope{} = scope, %Resource{} = resource, attrs) do
    true = resource.user_id == scope.user.id

    with {:ok, resource = %Resource{}} <-
           resource
           |> Resource.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_resource(scope, {:updated, resource})
      {:ok, resource}
    end
  end

  @doc """
  Deletes a resource.

  ## Examples

      iex> delete_resource(scope, resource)
      {:ok, %Resource{}}

      iex> delete_resource(scope, resource)
      {:error, %Ecto.Changeset{}}

  """
  def delete_resource(%Scope{} = scope, %Resource{} = resource) do
    true = resource.user_id == scope.user.id

    with {:ok, resource = %Resource{}} <-
           Repo.delete(resource) do
      broadcast_resource(scope, {:deleted, resource})
      {:ok, resource}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource changes.

  ## Examples

      iex> change_resource(scope, resource)
      %Ecto.Changeset{data: %Resource{}}

  """
  def change_resource(%Scope{} = scope, %Resource{} = resource, attrs \\ %{}) do
    # true = resource.user_id == scope.user.id

    Resource.changeset(resource, attrs, scope)
  end

  @doc """
  Creates or updates a resource depending on whether an id is present in attrs.

  ## Examples

      iex> create_or_update_resource(scope, %{id: 123, field: value})
      {:ok, %Resource{}}

      iex> create_or_update_resource(scope, %{field: value})
      {:ok, %Resource{}}
  """
  def create_or_update_resource(%Scope{} = scope, attrs) do
    if Map.get(attrs, "id") do
      resource = get_resource!(scope, attrs["id"])
      update_resource(scope, resource, attrs)
    else
      create_resource(scope, attrs)
    end
  end

  def list_all_tags do
    # Use a subquery to flatten all tags from all resources
    sql = """
    SELECT DISTINCT value
    FROM resources, json_each(tags)
    WHERE json_type(tags, '$') = 'array'
    ORDER BY value
    """

    try do
      result = Repo.query!(sql)
      Enum.map(result.rows, fn [tag] -> tag end)
    rescue
      _ ->
        [
          "advanced",
          "architecture",
          "backend",
          "basics",
          "book",
          "course",
          "design",
          "frontend",
          "performance",
          "storage",
          "systems",
          "web"
        ]
    end
  end
end
