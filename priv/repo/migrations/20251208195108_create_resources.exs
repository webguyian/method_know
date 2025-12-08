defmodule MethodKnow.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources) do
      add :title, :string
      add :description, :text
      add :resource_type, :string
      add :tags, :text
      add :author, :string
      add :code, :text
      add :language, :string
      add :url, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:resources, [:user_id])
  end
end
