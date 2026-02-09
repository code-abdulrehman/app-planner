defmodule AppPlanner.Repo.Migrations.BackfillWorkspacesForExistingApps do
  use Ecto.Migration
  import Ecto.Query
      # Import Ecto.Adapters.SQL to use raw query for inserts in migration
    # import Ecto.Adapters.SQL # Not needed for insert_all
  
    def change do
      # Fetch all existing users
      from(u in "users", select: u.id)
      |> AppPlanner.Repo.all()
      |> Enum.each(fn user_id ->
        # Create a default workspace for each user
        workspace_name = "My Workspace"
        {_count, [%{id: workspace_id}]} =
          AppPlanner.Repo.insert_all(
            "workspaces",
            [%{name: workspace_name, owner_id: user_id, inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()}],
            returning: [:id]
          )
  
        # Add the user as an owner of their new workspace
        AppPlanner.Repo.insert_all(
          "user_workspaces",
          [%{user_id: user_id, workspace_id: workspace_id, role: "owner", inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()}]
        )
  
        # Associate all apps owned by this user with their new workspace
        # Ensure there's a user_id on apps table, otherwise this will fail
        # Based on schema investigation, apps do have a user_id (from 20260130074059_create_apps.exs)
        from(a in "apps", where: a.user_id == ^user_id, select: a.id)
        |> AppPlanner.Repo.all()
        |> Enum.each(fn app_id ->
          AppPlanner.Repo.update_all(
            from(a in "apps", where: a.id == ^app_id),
            set: [workspace_id: workspace_id]
          )
        end)
      end)
    end
end