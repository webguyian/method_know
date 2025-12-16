defmodule MethodKnow.Resources.Resource do
  use Ecto.Schema

  alias MethodKnow.Resources

  import Ecto.Changeset

  schema "resources" do
    field :title, :string
    field :description, :string
    field :resource_type, :string
    field :tags, {:array, :string}
    field :author, :string
    field :code, :string
    field :language, :string
    field :url, :string

    belongs_to :user, MethodKnow.Accounts.User
    has_many :resource_interactions, MethodKnow.ResourceInteraction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs, user_scope) do
    resource
    |> cast(attrs, [:title, :description, :resource_type, :tags, :author, :code, :language, :url])
    |> validate_required([:title, :resource_type])
    |> validate_inclusion(:resource_type, Resources.resource_types())
    |> validate_required_by_type()
    |> maybe_put_user_id(user_scope)
  end

  defp maybe_put_user_id(changeset, nil), do: changeset

  defp maybe_put_user_id(changeset, %{user: %{id: user_id}}),
    do: put_change(changeset, :user_id, user_id)

  defp validate_required_by_type(changeset) do
    [article, code_snippet, learning_resource] = Resources.resource_types()

    case get_field(changeset, :resource_type) do
      ^article -> validate_required(changeset, [:url])
      ^code_snippet -> validate_required(changeset, [:code, :language])
      ^learning_resource -> validate_required(changeset, [:author, :url])
      _ -> changeset
    end
  end
end
