defmodule AppPlanner.Planner do
  @moduledoc """
  The Planner context.
  """

  import Ecto.Query, warn: false
  alias AppPlanner.Repo

  alias AppPlanner.Planner.{App, Feature, Task, TaskHistory, TaskComment}
  alias AppPlanner.Workspaces
  alias AppPlanner.Accounts

  # ============================================================================
  # App Context
  # ============================================================================

  def list_workspace_apps(%Accounts.User{} = current_user, workspace_id) do
    case Workspaces.get_workspace!(workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_view?(current_user, workspace) or Accounts.super_admin?(current_user) do
          App
          |> where([a], a.workspace_id == ^workspace_id)
          |> order_by([a], desc: a.inserted_at)
          |> Repo.all()
          |> Repo.preload([:user, :last_updated_by, :features])
        else
          {:error, :unauthorized}
        end

      _ ->
        {:error, :not_found}
    end
  end

  def list_apps(_user, nil), do: []
  def list_apps(user, workspace_id), do: list_workspace_apps(user, workspace_id)

  def get_app(%Accounts.User{} = current_user, app_id, workspace_id) do
    if is_nil(app_id) || is_nil(workspace_id) do
      nil
    else
      case Workspaces.get_workspace!(workspace_id) do
        %AppPlanner.Planner.Workspace{} = workspace ->
          if Workspaces.can_view?(current_user, workspace) or Accounts.super_admin?(current_user) do
            App
            |> where([a], a.id == ^app_id and a.workspace_id == ^workspace_id)
            |> Repo.one()
            |> case do
              nil -> nil
              app -> Repo.preload(app, [:user, :last_updated_by, features: [:last_updated_by]])
            end
          else
            {:error, :unauthorized}
          end

        _ ->
          {:error, :workspace_not_found}
      end
    end
  end

  def get_app!(id, user, workspace_id) when is_binary(id),
    do: get_app!(String.to_integer(id), user, workspace_id)

  def get_app!(id, user, workspace_id) when is_integer(id) do
    case get_app(user, id, workspace_id) do
      app when is_struct(app, App) -> app
      _ -> raise Ecto.NoResultsError, queryable: App
    end
  end

  def create_app(attrs, user, workspace_id) do
    attrs =
      attrs
      |> Map.put("user_id", user.id)
      |> Map.put("last_updated_by_id", user.id)
      |> Map.put("workspace_id", workspace_id)

    %App{}
    |> App.changeset(attrs)
    |> Repo.insert()
  end

  def update_app(%App{} = app, attrs, updated_by \\ nil) do
    attrs = if updated_by, do: Map.put(attrs, "last_updated_by_id", updated_by.id), else: attrs
    app |> App.changeset(attrs) |> Repo.update()
  end

  def delete_app(%App{} = app), do: Repo.delete(app)
  def change_app(%App{} = app, attrs \\ %{}), do: App.changeset(app, attrs)

  def create_example_app(user, workspace_id) do
    # 1. Create Example App
    app_attrs = %{
      "name" => "Example Project",
      "description" => "This is a pre-configured architecture roadmap to show you the system.",
      "category" => "Engineering",
      "status" => "Planned",
      "icon" => "sparkles"
    }

    with {:ok, app} <- create_app(app_attrs, user, workspace_id),
         # 2. Create Example Feature
         feature_attrs <- %{
           "title" => "Core Infrastructure",
           "description" => "Setup basic API and database schemas.",
           "status" => "In Progress",
           "icon" => "cpu-chip",
           "app_id" => app.id
         },
         {:ok, feature} <- create_feature(feature_attrs, user),
         # 3. Create Example Tasks
         _ <-
           create_task(%{
             "title" => "Define Ecto Schemas",
             "status" => "Todo",
             "feature_id" => feature.id,
             "icon" => "document-plus",
             "description" => "Draft initial database structure.",
             "position" => 1
           }),
         _ <-
           create_task(%{
             "title" => "Implement Auth logic",
             "status" => "In Progress",
             "feature_id" => feature.id,
             "icon" => "key",
             "description" => "Secure endpoints with magic links.",
             "position" => 1
           }) do
      {:ok, app}
    end
  end

  # ============================================================================
  # Feature Context
  # ============================================================================

  def list_features(%Accounts.User{} = current_user, app_id \\ nil, workspace_id) do
    cond do
      is_nil(workspace_id) ->
        []

      is_nil(app_id) ->
        Feature
        |> join(:inner, [f], a in App, on: f.app_id == a.id)
        |> where([f, a], a.workspace_id == ^workspace_id)
        |> order_by([f], desc: f.updated_at)
        |> Repo.all()
        |> Repo.preload([:app, :last_updated_by])

      true ->
        case get_app(current_user, app_id, workspace_id) do
          %App{} = app ->
            Feature
            |> where([f], f.app_id == ^app.id)
            |> order_by([f], desc: f.updated_at)
            |> Repo.all()
            |> Repo.preload([:app, :last_updated_by])

          _ ->
            []
        end
    end
  end

  def get_feature!(id, user, workspace_id) do
    feature =
      Feature |> where([f], f.id == ^id) |> Repo.one!() |> Repo.preload([:app, :last_updated_by])

    case get_app(user, feature.app_id, workspace_id) do
      %App{} -> feature
      _ -> raise Ecto.NoResultsError, queryable: Feature
    end
  end

  def create_feature(attrs, user) do
    attrs = attrs |> Map.put("user_id", user.id) |> Map.put("last_updated_by_id", user.id)
    %Feature{} |> Feature.changeset(attrs) |> Repo.insert()
  end

  def update_feature(%Feature{} = feature, attrs, updated_by \\ nil) do
    attrs = if updated_by, do: Map.put(attrs, "last_updated_by_id", updated_by.id), else: attrs
    feature |> Feature.changeset(attrs) |> Repo.update()
  end

  def list_features(app_id) do
    Feature
    |> where([f], f.app_id == ^app_id)
    |> order_by([f], asc: f.inserted_at)
    |> Repo.all()
  end

  def delete_feature(%Feature{} = feature), do: Repo.delete(feature)
  def change_feature(%Feature{} = feature, attrs \\ %{}), do: Feature.changeset(feature, attrs)

  # ============================================================================
  # Task Context
  # ============================================================================

  @default_task_statuses ["Todo", "In Progress", "Done"]
  @default_status_colors %{
    "Todo" => "#3b82f6",
    "In Progress" => "#f59e0b",
    "Done" => "#10b981"
  }

  def task_statuses(app \\ nil, workspace \\ nil) do
    cond do
      app && app.status_config && app.status_config["statuses"] ->
        app.status_config["statuses"]

      workspace && workspace.status_config && workspace.status_config["statuses"] ->
        workspace.status_config["statuses"]

      true ->
        @default_task_statuses
    end
  end

  def status_color(status, app \\ nil, workspace \\ nil) do
    config = (app && app.status_config) || (workspace && workspace.status_config) || %{}
    colors = config["colors"] || %{}
    colors[status] || @default_status_colors[status] || "#94a3b8"
  end

  def list_tasks_by_feature(feature_id) do
    Task
    |> where([t], t.feature_id == ^feature_id and is_nil(t.parent_task_id))
    |> order_by([t], asc: t.position)
    |> Repo.all()
    |> Repo.preload([:assignee, :subtasks, :comments])
  end

  def list_tasks_by_feature_grouped(feature_id, statuses \\ nil) do
    tasks = list_tasks_by_feature(feature_id)
    statuses = statuses || @default_task_statuses

    statuses
    |> Enum.map(fn status -> {status, Enum.filter(tasks, &(&1.status == status))} end)
    |> Enum.into(%{})
  end

  def get_task!(id) do
    Task
    |> Repo.get!(id)
    |> Repo.preload([:feature, :assignee, :subtasks, comments: [:user], parent_task: []])
  end

  def create_task(attrs, user \\ nil) do
    feature_id = attrs["feature_id"] || attrs[:feature_id]
    status = attrs["status"] || attrs[:status] || "Todo"

    max_position =
      Task
      |> where([t], t.feature_id == ^feature_id and t.status == ^status)
      |> select([t], max(t.position))
      |> Repo.one() || 0

    attrs = Map.put(attrs, "position", max_position + 1)

    Repo.transaction(fn ->
      case %Task{} |> Task.changeset(attrs) |> Repo.insert() do
        {:ok, task} ->
          if user, do: create_task_history(task, user, "created", %{title: task.title})
          task

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def reposition_task(%Task{} = task, new_status, new_index) do
    # Ensure indices are 0-based integers
    new_index = if is_binary(new_index), do: String.to_integer(new_index), else: new_index

    # Let's use a simpler implementation:
    Repo.transaction(fn ->
      # 1. Move task to new status if needed
      task =
        if task.status != new_status do
          task |> Task.changeset(%{status: new_status}) |> Repo.update!()
        else
          task
        end

      # 2. Fetch all tasks in that status (including the moved one)
      tasks_in_status =
        Task
        |> where([t], t.feature_id == ^task.feature_id and t.status == ^new_status)
        |> order_by([t], asc: t.position, asc: t.inserted_at)
        |> Repo.all()

      # 3. Remove task from list and re-insert at new_index
      other_tasks = Enum.reject(tasks_in_status, &(&1.id == task.id))
      ordered_tasks = List.insert_at(other_tasks, new_index, task)

      # 4. Update positions
      Enum.with_index(ordered_tasks)
      |> Enum.each(fn {t, idx} ->
        if t.position != idx do
          t |> Task.changeset(%{position: idx}) |> Repo.update!()
        end
      end)
    end)
  end

  def update_task(%Task{} = task, attrs, user \\ nil) do
    Repo.transaction(fn ->
      case task |> Task.changeset(attrs) |> Repo.update() do
        {:ok, updated_task} ->
          if user, do: create_task_history(updated_task, user, "updated", attrs)
          updated_task

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def update_task_status(%Task{} = task, new_status, new_position, user \\ nil) do
    Repo.transaction(fn ->
      Task
      |> where(
        [t],
        t.feature_id == ^task.feature_id and t.status == ^new_status and
          t.position >= ^new_position and t.id != ^task.id
      )
      |> Repo.update_all(inc: [position: 1])

      case task
           |> Task.changeset(%{status: new_status, position: new_position})
           |> Repo.update() do
        {:ok, updated_task} ->
          if user,
            do:
              create_task_history(updated_task, user, "moved", %{
                from: task.status,
                to: new_status
              })

          updated_task

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def delete_task(%Task{} = task), do: Repo.delete(task)
  def change_task(%Task{} = task, attrs \\ %{}), do: Task.changeset(task, attrs)

  def list_subtasks(parent_task_id) do
    Task
    |> where([t], t.parent_task_id == ^parent_task_id)
    |> order_by([t], asc: t.position)
    |> Repo.all()
    |> Repo.preload([:assignee])
  end

  # ============================================================================
  # Task History
  # ============================================================================

  def list_task_history(task_id) do
    TaskHistory
    |> where([h], h.task_id == ^task_id)
    |> order_by([h], desc: h.inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def create_task_history(task, user, action, details) do
    %TaskHistory{}
    |> TaskHistory.changeset(%{
      task_id: task.id,
      user_id: user.id,
      action: action,
      details: details
    })
    |> Repo.insert()
  end

  def can_edit_app?(%Accounts.User{} = user, %AppPlanner.Planner.App{} = app) do
    app.user_id == user.id or Accounts.super_admin?(user)
  end

  # ============================================================================
  # Task Comment Context
  # ============================================================================

  def create_task_comment(attrs) do
    %TaskComment{}
    |> AppPlanner.Planner.TaskComment.changeset(attrs)
    |> Repo.insert()
  end

  def delete_task_comment(%AppPlanner.Planner.TaskComment{} = comment) do
    Repo.delete(comment)
  end
end
