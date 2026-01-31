defmodule AppPlanner.Repo.Migrations.AddFullNameAndRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :full_name, :string
      add :role, :string, default: "user", null: false
    end

    # First user (lowest id) becomes super_admin; others stay user
    execute """
    UPDATE users SET role = 'super_admin'
    WHERE id = (SELECT id FROM users ORDER BY id ASC LIMIT 1)
    """,
    ""
  end
end
