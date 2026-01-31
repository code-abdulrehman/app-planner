defmodule AppPlanner.Repo.Migrations.AddStatusToFeatures do
  use Ecto.Migration

  def change do
    alter table(:features) do
      add :status, :string, default: "Planned", null: false
    end
  end
end
