defmodule AppPlanner.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  @default_categories ["Web app", "Mobile", "API", "Desktop", "Library", "Other"]

  def change do
    create table(:categories) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])

    # Seed default categories (reversible: delete by name on rollback)
    names = Enum.map_join(@default_categories, ", ", fn n -> "'#{String.replace(n, "'", "''")}'" end)
    execute(
      "INSERT INTO categories (name, inserted_at, updated_at) SELECT n, NOW(), NOW() FROM unnest(ARRAY[#{names}]::text[]) AS n ON CONFLICT (name) DO NOTHING",
      "DELETE FROM categories WHERE name IN (#{names})"
    )
  end
end
