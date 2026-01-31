defmodule AppPlanner.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :heading, :string, null: false
      add :description, :text, null: false
      add :status, :string, default: "active", null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notes, [:user_id])
  end
end
