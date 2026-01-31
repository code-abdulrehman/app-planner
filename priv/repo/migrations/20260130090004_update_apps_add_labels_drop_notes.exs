defmodule AppPlanner.Repo.Migrations.UpdateAppsAddLabelsDropNotes do
  use Ecto.Migration

  def change do
    # Remove Notes if exists
    drop_if_exists(table(:notes))

    # Add fields to Apps
    alter table(:apps) do
      add(:status, :string, default: "Idea")
      add(:visibility, :string, default: "private")
      add(:custom_fields, :map, default: %{})
      add(:pr_link, :string)
      add(:category, :string)
    end

    # Create Labels table (User scoped)
    create table(:labels) do
      add(:title, :string)
      add(:color, :string)
      add(:description, :text)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps(type: :utc_datetime)
    end

    create(index(:labels, [:user_id]))

    # Join table for Apps <-> Labels
    create table(:apps_labels, primary_key: false) do
      add(:app_id, references(:apps, on_delete: :delete_all))
      add(:label_id, references(:labels, on_delete: :delete_all))
    end

    create(index(:apps_labels, [:app_id]))
    create(index(:apps_labels, [:label_id]))
    create(unique_index(:apps_labels, [:app_id, :label_id]))
  end
end
