defmodule AppPlanner.Planner.TaskCustomFieldValue do
  use Ecto.Schema
  import Ecto.Changeset

  alias AppPlanner.Planner.{Task, CustomField}

  schema "task_custom_field_values" do
    field :value, :string

    belongs_to :task, Task
    belongs_to :custom_field, CustomField

    timestamps()
  end

  @doc false
  def changeset(task_custom_field_value, attrs) do
    task_custom_field_value
    |> cast(attrs, [:value, :task_id, :custom_field_id])
    |> validate_required([:value, :task_id, :custom_field_id])
    |> unique_constraint(:task_custom_field_value, name: :task_custom_field_values_task_id_custom_field_id_index)
  end
end
