defmodule AppPlanner.Repo.Migrations.AddAppMembersAndLastUpdatedBy do
  use Ecto.Migration

  def change do
    create table(:app_members) do
      add :app_id, references(:apps, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "view"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:app_members, [:app_id, :user_id])
    create index(:app_members, [:user_id])

    alter table(:apps) do
      add :last_updated_by_id, references(:users, on_delete: :nilify_all)
    end

    alter table(:features) do
      add :last_updated_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:apps, [:last_updated_by_id])
    create index(:features, [:last_updated_by_id])
  end
end
