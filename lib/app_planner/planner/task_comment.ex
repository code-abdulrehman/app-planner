defmodule AppPlanner.Planner.TaskComment do
  use Ecto.Schema
  import Ecto.Changeset

  alias AppPlanner.Accounts.User
  alias AppPlanner.Planner.Task

  schema "task_comments" do
    field :content, :string

    belongs_to :task, Task
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(task_comment, attrs) do
    task_comment
    |> cast(attrs, [:content, :task_id, :user_id])
    |> validate_required([:content, :task_id, :user_id])
  end
end
