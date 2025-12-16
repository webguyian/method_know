defmodule MethodKnow.Repo.Migrations.CreateResourceInteractions do
  use Ecto.Migration

  def change do
    create table(:resource_interactions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :resource_id, references(:resources, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :payload, :text
      timestamps()
    end

    create unique_index(:resource_interactions, [:user_id, :resource_id, :type])
    create index(:resource_interactions, [:resource_id, :type])
  end
end
