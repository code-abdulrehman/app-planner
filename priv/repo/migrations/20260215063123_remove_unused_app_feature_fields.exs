defmodule AppPlanner.Repo.Migrations.RemoveUnusedAppFeatureFields do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      remove :category
    end

    alter table(:features) do
      remove :status
    end
  end
end
