defmodule AppPlanner.Planner.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workspaces" do
    field(:name, :string)
    field(:visibility, :string, default: "private")
    # For custom Kanban columns
    field(:status_config, :map)
    field(:owner_email, :string, virtual: true)

    belongs_to(:owner, AppPlanner.Accounts.User, foreign_key: :owner_id)

    many_to_many(:users, AppPlanner.Accounts.User,
      join_through: AppPlanner.Planner.UserWorkspace,
      on_delete: :delete_all
    )

    has_many(:apps, AppPlanner.Planner.App, on_delete: :delete_all)

    timestamps()
  end

  @doc false
  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name, :owner_id, :visibility, :status_config])
    |> validate_required([:name, :owner_id])
    |> validate_inclusion(:visibility, ["private", "public"])
    |> unique_constraint(:name)
  end
end
