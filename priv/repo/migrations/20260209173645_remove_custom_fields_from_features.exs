defmodule AppPlanner.Repo.Migrations.RemoveCustomFieldsFromFeatures do
  use Ecto.Migration

  def change do
    alter table(:features) do
      remove(:custom_fields)
    end
  end
end
