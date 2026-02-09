defmodule AppPlanner.Repo.Migrations.FurtherSimplifyAppsTable do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      remove(:pr_link)
      remove(:custom_fields)
    end
  end
end
