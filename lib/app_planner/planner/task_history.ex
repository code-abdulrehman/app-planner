defmodule AppPlanner.Planner.TaskHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_history" do
    field(:action, :string)
    field(:details, :map)

    belongs_to(:task, AppPlanner.Planner.Task)
    belongs_to(:user, AppPlanner.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(task_history, attrs) do
    task_history
    |> cast(attrs, [:action, :details, :task_id, :user_id])
    |> validate_required([:action, :task_id])
  end
end
