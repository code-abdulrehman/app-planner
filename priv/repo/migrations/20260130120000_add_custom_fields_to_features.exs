defmodule AppPlanner.Repo.Migrations.AddCustomFieldsToFeatures do
  use Ecto.Migration

  def change do
    alter table(:features) do
      add :custom_fields, :map, default: %{}
    end
  end
end
