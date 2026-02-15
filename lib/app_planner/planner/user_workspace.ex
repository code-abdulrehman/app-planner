defmodule AppPlanner.Planner.UserWorkspace do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_workspaces" do
    belongs_to :user, AppPlanner.Accounts.User
    belongs_to :workspace, AppPlanner.Planner.Workspace
    field :role, :string, default: "member"

    timestamps()
  end

  @doc false
  def changeset(user_workspace, attrs) do
    user_workspace
    |> cast(attrs, [:user_id, :workspace_id, :role])
    |> validate_required([:user_id, :workspace_id, :role])
    |> validate_inclusion(:role, ["owner", "editor", "member", "viewer"])
    |> unique_constraint(:user_workspace, name: :user_workspaces_user_id_workspace_id_index)
  end
end
