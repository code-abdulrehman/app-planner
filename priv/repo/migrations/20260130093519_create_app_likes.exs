defmodule AppPlanner.Repo.Migrations.CreateAppLikes do
  use Ecto.Migration

  def change do
    create table(:app_likes) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:app_id, references(:apps, on_delete: :delete_all), null: false)

      timestamps(type: :utc_datetime)
    end

    create(index(:app_likes, [:user_id]))
    create(index(:app_likes, [:app_id]))
    create(unique_index(:app_likes, [:user_id, :app_id]))
  end
end
