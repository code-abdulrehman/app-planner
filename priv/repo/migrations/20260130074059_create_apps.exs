defmodule AppPlanner.Repo.Migrations.CreateApps do
  use Ecto.Migration

  def change do
    create table(:apps) do
      add :name, :string
      add :icon, :string
      add :description, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :parent_app_id, references(:apps, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:apps, [:user_id])
    create index(:apps, [:parent_app_id])
  end
end
