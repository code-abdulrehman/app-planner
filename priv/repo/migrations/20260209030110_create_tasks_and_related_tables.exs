defmodule AppPlanner.Repo.Migrations.CreateTasksAndRelatedTables do
  use Ecto.Migration

  def change do
    # Tasks Table
    create table(:tasks) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "Todo", null: false
      add :position, :integer, default: 0, null: false
      add :feature_id, references(:features, on_delete: :delete_all), null: false
      add :assignee_id, references(:users, on_delete: :nothing)
      # For sub-tasks
      add :parent_task_id, references(:tasks, on_delete: :nothing)

      timestamps()
    end

    create index(:tasks, [:feature_id])
    create index(:tasks, [:assignee_id])
    create index(:tasks, [:parent_task_id])

    # Task Comments Table
    create table(:task_comments) do
      add :content, :text, null: false
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:task_comments, [:task_id])
    create index(:task_comments, [:user_id])

    # Workspace Categories Table (for tasks)
    # The existing `labels` table seems user-specific, so creating a new one for workspace-wide categories
    create table(:workspace_categories) do
      add :name, :string, null: false
      # e.g., "#RRGGBB"
      add :color, :string
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false

      timestamps()
    end

    # Category name unique per workspace
    create unique_index(:workspace_categories, [:name, :workspace_id])
    create index(:workspace_categories, [:workspace_id])

    # Join table for Tasks and Workspace Categories
    create table(:task_workspace_categories) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false

      add :workspace_category_id, references(:workspace_categories, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create unique_index(:task_workspace_categories, [:task_id, :workspace_category_id])
    create index(:task_workspace_categories, [:workspace_category_id])

    # Custom Fields Table (for tasks, defined at workspace level)
    create table(:custom_fields) do
      add :name, :string, null: false
      # e.g., "text", "number", "select"
      add :field_type, :string, null: false
      # for select/multi-select fields
      add :options, :map, default: %{}
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false

      timestamps()
    end

    # Custom field name unique per workspace
    create unique_index(:custom_fields, [:name, :workspace_id])
    create index(:custom_fields, [:workspace_id])

    # Task Custom Field Values Table
    create table(:task_custom_field_values) do
      # Can be stringified JSON for complex types
      add :value, :string
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :custom_field_id, references(:custom_fields, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:task_custom_field_values, [:task_id, :custom_field_id])
    create index(:task_custom_field_values, [:custom_field_id])
  end
end
