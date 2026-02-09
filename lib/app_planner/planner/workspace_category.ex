defmodule AppPlanner.Planner.WorkspaceCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias AppPlanner.Planner.Workspace

  schema "workspace_categories" do
    field :name, :string
    field :color, :string
    belongs_to :workspace, Workspace

    timestamps()
  end

  @doc false
  def changeset(workspace_category, attrs) do
    workspace_category
    |> cast(attrs, [:name, :color, :workspace_id])
    |> validate_required([:name, :workspace_id])
    |> unique_constraint(:name, scope: [:workspace_id])
  end
end
