defmodule MethodKnow.Resources.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  @type_article "article"
  @type_code_snippet "code_snippet"
  @type_learning_resource "learning_resource"

  @valid_resource_types [@type_article, @type_code_snippet, @type_learning_resource]

  def resource_types do
    [
      {"Article", @type_article},
      {"Code Snippet", @type_code_snippet},
      {"Learning Resource", @type_learning_resource}
    ]
  end

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

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs, user_scope) do
    resource
    |> cast(attrs, [:title, :description, :resource_type, :tags, :author, :code, :language, :url])
    |> validate_required([:title, :resource_type])
    |> validate_inclusion(:resource_type, @valid_resource_types)
    |> validate_required_by_type()
    |> put_change(:user_id, user_scope.user.id)
  end

  defp validate_required_by_type(changeset) do
    case get_field(changeset, :resource_type) do
      @type_article -> validate_required(changeset, [:url])
      @type_code_snippet -> validate_required(changeset, [:code, :language])
      @type_learning_resource -> validate_required(changeset, [:author, :url])
      _ -> changeset
    end
  end
end
