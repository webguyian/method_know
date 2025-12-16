defmodule MethodKnow.ResourceInteraction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resource_interactions" do
    field :type, :string
    field :payload, :string
    belongs_to :user, MethodKnow.Accounts.User
    belongs_to :resource, MethodKnow.Resources.Resource
    timestamps()
  end

  @doc false
  def changeset(resource_interaction, attrs) do
    resource_interaction
    |> cast(attrs, [:type, :payload, :user_id, :resource_id])
    |> validate_required([:type, :user_id, :resource_id])
    |> unique_constraint([:user_id, :resource_id, :type])
  end
end
