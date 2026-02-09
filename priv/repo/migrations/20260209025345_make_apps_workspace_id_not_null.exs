defmodule AppPlanner.Repo.Migrations.MakeAppsWorkspaceIdNotNull do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      modify :workspace_id, :bigint, null: false
    end
  end
end
