defmodule AppPlanner.Planner.TaskWorkspaceCategory do
  use Ecto.Schema
  import Ecto.Changeset

  alias AppPlanner.Planner.{Task, WorkspaceCategory}

  schema "task_workspace_categories" do
    belongs_to :task, Task
    belongs_to :workspace_category, WorkspaceCategory

    timestamps()
  end

  @doc false
  def changeset(task_workspace_category, attrs) do
    task_workspace_category
    |> cast(attrs, [:task_id, :workspace_category_id])
    |> validate_required([:task_id, :workspace_category_id])
    |> unique_constraint(:task_workspace_category, name: :task_workspace_categories_task_id_workspace_category_id_index)
  end
end
