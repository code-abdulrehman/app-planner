defmodule AppPlanner.Repo.Migrations.SimplifyTaskInfrastructure do
  use Ecto.Migration

  def change do
    drop table(:task_workspace_categories)
    drop table(:workspace_categories)
    drop table(:task_custom_field_values)
    drop table(:custom_fields)
  end
end
