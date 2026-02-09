defmodule AppPlanner.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias AppPlanner.Repo

  alias AppPlanner.Accounts.User
  alias AppPlanner.Workspaces
  alias AppPlanner.Planner.{Feature, Task, TaskComment, WorkspaceCategory, TaskWorkspaceCategory, CustomField, TaskCustomFieldValue}

  # Tasks
  @doc """
  Returns the list of tasks for a feature.
  """
  def list_feature_tasks(%User{} = current_user, %Feature{} = feature) do
    case get_workspace_from_feature(feature) do
      {:ok, workspace} ->
        if Workspaces.can_view?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          feature
          |> Ecto.assoc(:tasks)
          |> Repo.all()
          |> Repo.preload([:assignee, :parent_task, :subtasks, :workspace_categories])
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
        if Workspaces.can_view?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          task |> Repo.preload([:assignee, :parent_task, :subtasks, :comments, :workspace_categories, :custom_field_values])
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
            if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
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
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
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
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
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
        if Workspaces.can_view?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
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
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          %TaskComment{}
          |> TaskComment.changeset(Map.put(attrs, :task_id, task.id) |> Map.put(:user_id, current_user.id))
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
        if task_comment.user_id == current_user.id or Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          Repo.delete(task_comment)
        else
          {:error, :unauthorized}
        end
      {:error, _} ->
        {:error, :not_found}
    end
  end

  # Workspace Categories
  @doc """
  Returns the list of workspace categories for a workspace.
  """
  def list_workspace_categories(%User{} = current_user, workspace_id) do
    case Workspaces.get_workspace!(workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_view?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          Repo.all(from wc in WorkspaceCategory, where: wc.workspace_id == ^workspace_id)
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets a single workspace category.
  """
  def get_workspace_category!(%User{} = current_user, id) do
    category = Repo.get!(WorkspaceCategory, id)
    case Workspaces.get_workspace!(category.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_view?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          category
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates a workspace category.
  """
  def create_workspace_category(%User{} = current_user, attrs) do
    case Workspaces.get_workspace!(attrs.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          %WorkspaceCategory{}
          |> WorkspaceCategory.changeset(attrs)
          |> Repo.insert()
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Updates a workspace category.
  """
  def update_workspace_category(%User{} = current_user, %WorkspaceCategory{} = category, attrs) do
    case Workspaces.get_workspace!(category.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          category
          |> WorkspaceCategory.changeset(attrs)
          |> Repo.update()
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a workspace category.
  """
  def delete_workspace_category(%User{} = current_user, %WorkspaceCategory{} = category) do
    case Workspaces.get_workspace!(category.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          Repo.delete(category)
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  # Task Workspace Categories (for associating tasks with categories)
  @doc """
  Associates a task with a workspace category.
  """
  def associate_task_with_category(%User{} = current_user, %Task{} = task, %WorkspaceCategory{} = category) do
    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        # Ensure category belongs to the same workspace
        if category.workspace_id != workspace.id do
          {:error, :category_workspace_mismatch}
        else
          if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
            %TaskWorkspaceCategory{}
            |> TaskWorkspaceCategory.changeset(%{task_id: task.id, workspace_category_id: category.id})
            |> Repo.insert()
          else
            {:error, :unauthorized}
          end
        end
      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Disassociates a task from a workspace category.
  """
  def disassociate_task_from_category(%User{} = current_user, %Task{} = task, %WorkspaceCategory{} = category) do
    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        # Ensure category belongs to the same workspace
        if category.workspace_id != workspace.id do
          {:error, :category_workspace_mismatch}
        else
          if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
            Repo.delete_all(from twc in TaskWorkspaceCategory, where: twc.task_id == ^task.id and twc.workspace_category_id == ^category.id)
          else
            {:error, :unauthorized}
          end
        end
      {:error, _} ->
        {:error, :not_found}
    end
  end

  # Custom Fields
  @doc """
  Returns the list of custom fields for a workspace.
  """
  def list_custom_fields(%User{} = current_user, workspace_id) do
    case Workspaces.get_workspace!(workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_view?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          Repo.all(from cf in CustomField, where: cf.workspace_id == ^workspace_id)
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets a single custom field.
  """
  def get_custom_field!(%User{} = current_user, id) do
    custom_field = Repo.get!(CustomField, id)
    case Workspaces.get_workspace!(custom_field.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_view?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          custom_field
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Creates a custom field.
  """
  def create_custom_field(%User{} = current_user, attrs) do
    case Workspaces.get_workspace!(attrs.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          %CustomField{}
          |> CustomField.changeset(attrs)
          |> Repo.insert()
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Updates a custom field.
  """
  def update_custom_field(%User{} = current_user, %CustomField{} = custom_field, attrs) do
    case Workspaces.get_workspace!(custom_field.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          custom_field
          |> CustomField.changeset(attrs)
          |> Repo.update()
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a custom field.
  """
  def delete_custom_field(%User{} = current_user, %CustomField{} = custom_field) do
    case Workspaces.get_workspace!(custom_field.workspace_id) do
      %AppPlanner.Planner.Workspace{} = workspace ->
        if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
          Repo.delete(custom_field)
        else
          {:error, :unauthorized}
        end
      _ ->
        {:error, :not_found}
    end
  end

  # Task Custom Field Values
  @doc """
  Gets a single task custom field value.
  """
  def get_task_custom_field_value(%Task{} = task, %CustomField{} = custom_field) do
    Repo.get_by(TaskCustomFieldValue, task_id: task.id, custom_field_id: custom_field.id)
  end

  @doc """
  Creates or updates a task custom field value.
  """
  def put_task_custom_field_value(%User{} = current_user, %Task{} = task, %CustomField{} = custom_field, value) do
    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        # Ensure custom_field belongs to the same workspace
        if custom_field.workspace_id != workspace.id do
          {:error, :custom_field_workspace_mismatch}
        else
          if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
            case get_task_custom_field_value(task, custom_field) do
              nil -> # Create
                %TaskCustomFieldValue{}
                |> TaskCustomFieldValue.changeset(%{task_id: task.id, custom_field_id: custom_field.id, value: value})
                |> Repo.insert()
              tcfv -> # Update
                tcfv
                |> TaskCustomFieldValue.changeset(%{value: value})
                |> Repo.update()
            end
          else
            {:error, :unauthorized}
          end
        end
      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a task custom field value.
  """
  def delete_task_custom_field_value(%User{} = current_user, %TaskCustomFieldValue{} = tcfv) do
    # Preload custom_field to get its workspace_id
    tcfv_with_custom_field = Repo.preload(tcfv, :custom_field)
    custom_field = tcfv_with_custom_field.custom_field

    # Preload task to get its workspace_id
    tcfv_with_task = Repo.preload(tcfv, :task)
    task = tcfv_with_task.task

    case get_workspace_from_task(task) do
      {:ok, workspace} ->
        # Ensure custom_field belongs to the same workspace
        if custom_field.workspace_id != workspace.id do
          {:error, :custom_field_workspace_mismatch}
        else
          if Workspaces.can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
            Repo.delete(tcfv)
          else
            {:error, :unauthorized}
          end
        end
      {:error, _} ->
        {:error, :not_found}
    end
  end

  defp get_workspace_from_feature(%AppPlanner.Planner.Feature{} = feature) do
    case Repo.preload(feature, app: :workspace) do
      %AppPlanner.Planner.Feature{app: %AppPlanner.Planner.App{workspace: workspace}} -> {:ok, workspace}
      _ -> {:error, :workspace_not_found}
    end
  end

  defp get_workspace_from_task(%AppPlanner.Planner.Task{} = task) do
    case Repo.preload(task, feature: [app: :workspace]) do
      %AppPlanner.Planner.Task{feature: %AppPlanner.Planner.Feature{app: %AppPlanner.Planner.App{workspace: workspace}}} -> {:ok, workspace}
      _ -> {:error, :workspace_not_found}
    end
  end
end