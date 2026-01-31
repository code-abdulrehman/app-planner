defmodule AppPlanner.Repo.Migrations.CreateFeatures do
  use Ecto.Migration

  def change do
    create table(:features) do
      add :title, :string
      add :description, :text
      add :how_to_add, :text
      add :why, :text
      add :pros, :text
      add :cons, :text
      add :implementation_date, :date
      add :how_to_implement, :text
      add :why_need, :text
      add :time_estimate, :string
      add :app_id, references(:apps, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:features, [:app_id])
    create index(:features, [:user_id])
  end
end
