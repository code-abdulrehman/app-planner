defmodule AppPlanner.Repo.Migrations.SimplifyFeaturesTable do
  use Ecto.Migration

  def change do
    alter table(:features) do
      remove(:how_to_add)
      remove(:why)
      remove(:pros)
      remove(:cons)
      remove(:implementation_date)
      remove(:how_to_implement)
      remove(:why_need)
      remove(:time_estimate)
      remove(:pr_link)
    end
  end
end
