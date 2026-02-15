defmodule AppPlanner.Repo.Migrations.AddWorkspaceInviteFieldsToUserTokens do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add :workspace_id, references(:workspaces, on_delete: :nothing)
      add :invited_email, :string
    end

    create index(:users_tokens, [:workspace_id])
  end
end
