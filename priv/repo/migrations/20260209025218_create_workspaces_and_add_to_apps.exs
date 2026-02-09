defmodule AppPlanner.Repo.Migrations.CreateWorkspacesAndAddToApps do
  use Ecto.Migration

  def change do
    create table(:workspaces) do
      add :name, :string, null: false
      add :owner_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:workspaces, [:owner_id])

    create table(:user_workspaces) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member" # owner, editor, viewer

      timestamps()
    end

    create unique_index(:user_workspaces, [:user_id, :workspace_id])
    create index(:user_workspaces, [:workspace_id])

    alter table(:apps) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: true
    end

    create index(:apps, [:workspace_id])
  end
end
