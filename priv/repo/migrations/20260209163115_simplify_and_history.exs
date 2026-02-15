defmodule AppPlanner.Repo.Migrations.SimplifyAndHistory do
  use Ecto.Migration

  def change do
    alter table(:workspaces) do
      # "private" or "public"
      add(:visibility, :string, default: "private")
      # For custom Kanban columns
      add(:status_config, :map)
    end

    create table(:task_history) do
      add(:action, :string)
      add(:details, :map)
      add(:task_id, references(:tasks, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:task_history, [:task_id]))
    create(index(:task_history, [:user_id]))

    alter table(:apps) do
      remove(:parent_app_id)
      # Moved to workspace level
      remove(:visibility)
    end
  end
end
