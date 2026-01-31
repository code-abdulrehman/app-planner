defmodule AppPlanner.Repo.Migrations.AddPrLinkToFeatures do
  use Ecto.Migration

  def change do
    alter table(:features) do
      add :pr_link, :string
    end
  end
end
