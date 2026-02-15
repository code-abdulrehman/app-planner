# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
alias AppPlanner.Repo
alias AppPlanner.Accounts
alias AppPlanner.Planner
alias AppPlanner.Workspaces
import Ecto.Query

# Get or create a seed user
user =
  case Accounts.get_user_by_email("seed@example.com") do
    nil ->
      case Accounts.register_user(%{email: "seed@example.com", password: "seedpassword123"}) do
        {:ok, u} -> u
        {:error, _} -> nil
      end

    u ->
      u
  end

if user do
  # 1. Ensure a Workspace exists
  workspace =
    case Repo.all(from w in AppPlanner.Planner.Workspace, limit: 1) do
      [w | _] ->
        w

      [] ->
        {:ok, w} =
          %AppPlanner.Planner.Workspace{}
          |> AppPlanner.Planner.Workspace.changeset(%{name: "Main Workspace", owner_id: user.id})
          |> Repo.insert()

        # Add owner entry
        %AppPlanner.Planner.UserWorkspace{}
        |> AppPlanner.Planner.UserWorkspace.changeset(%{
          user_id: user.id,
          workspace_id: w.id,
          role: "owner"
        })
        |> Repo.insert()

        w
    end

  # 2. Ensure an App exists
  app_name = "Sample Planner App"

  app =
    case Repo.one(from a in AppPlanner.Planner.App, where: a.name == ^app_name, limit: 1) do
      nil ->
        status_config = %{
          "statuses" => ["Todo", "In Progress", "Done"],
          "colors" => %{
            "Todo" => "#3b82f6",
            "In Progress" => "#f59e0b",
            "Done" => "#10b981"
          }
        }

        {:ok, a} =
          %AppPlanner.Planner.App{}
          |> AppPlanner.Planner.App.changeset(%{
            name: app_name,
            description: "Seed app with standard columns",
            status_config: status_config,
            workspace_id: workspace.id
          })
          |> Repo.insert()

        a

      a ->
        a
    end

  # 3. Ensure a Feature exists
  feature_name = "Core Implementation"

  feature =
    case Repo.one(
           from f in AppPlanner.Planner.Feature,
             where: f.title == ^feature_name and f.app_id == ^app.id,
             limit: 1
         ) do
      nil ->
        {:ok, f} =
          %AppPlanner.Planner.Feature{}
          |> AppPlanner.Planner.Feature.changeset(%{
            title: feature_name,
            description: "Basic board functionality",
            app_id: app.id,
            workspace_id: workspace.id,
            user_id: user.id
          })
          |> Repo.insert()

        f

      f ->
        f
    end

  # 4. Seed some tasks if none exist
  if Repo.one(from t in AppPlanner.Planner.Task, select: count(t.id)) == 0 do
    [
      %{title: "Fix Assignee Re-assignment", status: "Todo", feature_id: feature.id},
      %{title: "Default 3 Column Board", status: "In Progress", feature_id: feature.id},
      %{title: "Dynamic Column Labels", status: "Done", feature_id: feature.id}
    ]
    |> Enum.each(fn attrs ->
      %AppPlanner.Planner.Task{}
      |> AppPlanner.Planner.Task.changeset(attrs)
      |> Repo.insert()
    end)

    IO.puts("Seeded 3 tasks for '#{feature_name}'")
  end

  IO.puts("Seed setup complete!")
end
