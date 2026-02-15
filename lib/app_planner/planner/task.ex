defmodule AppPlanner.Planner.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias AppPlanner.Accounts.User
  alias AppPlanner.Planner.{Feature, Task, TaskComment}

  schema "tasks" do
    field(:title, :string)
    field(:description, :string)
    field(:status, :string)
    field(:position, :integer)
    field(:due_date, :date)
    field(:time_estimate, :string)
    field(:git_link, :string)
    field(:user_flow, :string)
    field(:icon, :string)
    field(:rationale, :string)
    field(:strategy, :string)
    field(:pros, :string)
    field(:cons, :string)
    field(:custom_fields, :map, default: %{})
    field(:category, :string)

    belongs_to(:feature, Feature)
    belongs_to(:assignee, User, foreign_key: :assignee_id)
    belongs_to(:parent_task, Task, foreign_key: :parent_task_id)

    has_many(:subtasks, Task, foreign_key: :parent_task_id)
    has_many(:comments, TaskComment, on_delete: :delete_all)

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :status,
      :position,
      :feature_id,
      :assignee_id,
      :parent_task_id,
      :due_date,
      :time_estimate,
      :git_link,
      :user_flow,
      :icon,
      :rationale,
      :strategy,
      :pros,
      :cons,
      :custom_fields,
      :category
    ])
    |> validate_required([:title, :status, :feature_id])
  end
end
