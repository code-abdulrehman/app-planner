defmodule AppPlanner.Repo.Migrations.BackfillAppMemberRolesToViewerEditor do
  use Ecto.Migration

  def change do
    execute(
      "UPDATE app_members SET role = 'viewer' WHERE role = 'view'",
      "UPDATE app_members SET role = 'view' WHERE role = 'viewer'"
    )

    execute(
      "UPDATE app_members SET role = 'editor' WHERE role = 'edit'",
      "UPDATE app_members SET role = 'edit' WHERE role = 'editor'"
    )
  end
end
