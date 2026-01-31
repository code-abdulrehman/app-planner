defmodule AppPlanner.Repo.Migrations.AddUniqueIndexLabelsUserIdTitle do
  use Ecto.Migration

  def change do
    create(unique_index(:labels, [:user_id, :title]))
  end
end
