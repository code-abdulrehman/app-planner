defmodule AppPlanner.Repo.Migrations.CleanupUnusedTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:app_likes)
    drop_if_exists table(:categories)
    drop_if_exists table(:app_members)
  end
end
