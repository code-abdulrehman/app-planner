defmodule AppPlanner.Repo.Migrations.AddIconToFeatures do
  use Ecto.Migration

  def change do
    alter table(:features) do
      add :icon, :string
    end
  end
end
