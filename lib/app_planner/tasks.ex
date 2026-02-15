defmodule AppPlanner.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias AppPlanner.Repo

  alias AppPlanner.Accounts.User
  alias AppPlanner.Workspaces
  alias AppPlanner.Planner.{Feature, Task, TaskComment}

  # Tasks
  @doc """
  Returns the list of tasks for a feature.
  """
  def list_feature_tasks(%User{} = current_user, %Feature{} = feature) do
    case get_workspace_from_feature(feature) do
      {:ok, workspace} ->
        if Workspaces.can_view?(current_user, workspace) or
             AppPlanner.Accounts.super_admin?(current_user) do
          feature
          |> Ecto.assoc(:tasks)
          |> Repo.all()
          |> Repo.preload([:assignee, :parent_task, :subtasks])
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.
  """
  def get_task!(%User{} = current_user, id) do
    task = Repo.get!(Task, id)

    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        if Workspaces.can_view?(current_user, workspace) or
             AppPlanner.Accounts.super_admin?(current_user) do
          task |> Repo.preload([:assignee, :parent_task, :subtasks, :comments])
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates a task.
  """
  def create_task(%User{} = current_user, attrs) do
    case Repo.get(Feature, attrs.feature_id) do
      %Feature{} = feature ->
        case get_workspace_from_feature(feature) do
          {:ok, workspace} ->
            if Workspaces.can_edit?(current_user, workspace) or
                 AppPlanner.Accounts.super_admin?(current_user) do
              %Task{}
              |> Task.changeset(attrs)
              |> Repo.insert()
            else
              {:error, :unauthorized}
            end

          {:error, _} ->
            {:error, :feature_not_in_workspace}
        end

      _ ->
        {:error, :feature_not_found}
    end
  end

  @doc """
  Updates a task.
  """
  def update_task(%User{} = current_user, %Task{} = task, attrs) do
    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        if Workspaces.can_edit?(current_user, workspace) or
             AppPlanner.Accounts.super_admin?(current_user) do
          task
          |> Task.changeset(attrs)
          |> Repo.update()
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :task_not_in_workspace}
    end
  end

  @doc """
  Deletes a task.
  """
  def delete_task(%User{} = current_user, %Task{} = task) do
    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        if Workspaces.can_edit?(current_user, workspace) or
             AppPlanner.Accounts.super_admin?(current_user) do
          Repo.delete(task)
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :task_not_in_workspace}
    end
  end

  # Task Comments
  @doc """
  Returns the list of comments for a task.
  """
  def list_task_comments(%User{} = current_user, %Task{} = task) do
    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        if Workspaces.can_view?(current_user, workspace) or
             AppPlanner.Accounts.super_admin?(current_user) do
          task
          |> Ecto.assoc(:comments)
          |> Repo.all()
          |> Repo.preload([:user])
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates a task comment.
  """
  def create_task_comment(%User{} = current_user, %Task{} = task, attrs) do
    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        if Workspaces.can_edit?(current_user, workspace) or
             AppPlanner.Accounts.super_admin?(current_user) do
          %TaskComment{}
          |> TaskComment.changeset(
            Map.put(attrs, :task_id, task.id)
            |> Map.put(:user_id, current_user.id)
          )
          |> Repo.insert()
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a task comment.
  """
  def delete_task_comment(%User{} = current_user, %TaskComment{} = task_comment) do
    case get_workspace_from_task(Repo.preload(task_comment, :task)) do
      {:ok, workspace} ->
        if task_comment.user_id == current_user.id or
             Workspaces.can_edit?(current_user, workspace) or
             AppPlanner.Accounts.super_admin?(current_user) do
          Repo.delete(task_comment)
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :not_found}
    end
  end

  defp get_workspace_from_feature(%AppPlanner.Planner.Feature{} = feature) do
    case Repo.preload(feature, app: :workspace) do
      %AppPlanner.Planner.Feature{app: %AppPlanner.Planner.App{workspace: workspace}} ->
        {:ok, workspace}

      _ ->
        {:error, :workspace_not_found}
    end
  end

  defp get_workspace_from_task(%AppPlanner.Planner.Task{} = task) do
    case Repo.preload(task, feature: [app: :workspace]) do
      %AppPlanner.Planner.Task{
        feature: %AppPlanner.Planner.Feature{app: %AppPlanner.Planner.App{workspace: workspace}}
      } ->
        {:ok, workspace}

      _ ->
        {:error, :workspace_not_found}
    end
  end
end
