defmodule AppPlanner.Repo.Migrations.AddStatusConfigToApps do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      add :status_config, :map
    end
  end
end
