defmodule AppPlanner.Workspaces do
  @moduledoc """
  The Workspaces context.
  """

  import Ecto.Query, warn: false
  alias AppPlanner.Repo

  alias AppPlanner.Accounts.User
  alias AppPlanner.Planner.{Workspace, UserWorkspace}

  @doc """
  Returns the list of workspaces for a user.
  """
  def list_user_workspaces(%User{} = user) do
    user
    |> Ecto.assoc(:user_workspaces)
    |> Repo.all()
    # Preload workspace and its owner
    |> Repo.preload(workspace: :owner)
    |> Enum.map(& &1.workspace)
  end

  def list_workspace_members(%Workspace{id: id}), do: list_workspace_members(id)

  def list_workspace_members(workspace_id) do
    UserWorkspace
    |> where([uw], uw.workspace_id == ^workspace_id)
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.sort_by(&(&1.role != "owner"))
  end

  @doc """
  Returns the list of all workspaces.
  """
  def list_all_workspaces(%User{} = current_user) do
    if AppPlanner.Accounts.super_admin?(current_user) do
      Repo.all(Workspace)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Gets a single workspace.

  Raises `Ecto.NoResultsError` if the Workspace does not exist.
  """
  def get_workspace!(id), do: Repo.get!(Workspace, id) |> Repo.preload(:owner)

  @doc """
  Gets a user workspace by user and workspace.
  """
  def get_user_workspace(%User{} = user, %Workspace{} = workspace) do
    Repo.get_by(UserWorkspace, user_id: user.id, workspace_id: workspace.id)
  end

  @doc """
  Creates a workspace.
  """
  def create_workspace(%User{} = current_user, attrs) do
    # Normalize keys to strings to prevent mixed-key errors in Ecto.cast
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
    owner_email = attrs["owner_email"]

    # A user can only create a workspace where they are the owner.
    # A super_admin can create a workspace for any owner.
    cond do
      # Super admin creating for a specific owner
      AppPlanner.Accounts.super_admin?(current_user) and owner_email ->
        case AppPlanner.Accounts.get_user_by_email(owner_email) do
          nil ->
            {:error, :owner_not_found}

          owner_user ->
            attrs_with_owner_id =
              attrs
              |> Map.delete("owner_email")
              |> Map.put("owner_id", owner_user.id)

            %Workspace{}
            |> Workspace.changeset(attrs_with_owner_id)
            |> Repo.insert()
            |> case do
              {:ok, workspace} ->
                # Add the specified owner to the workspace with 'owner' role
                create_user_workspace(current_user, workspace, owner_user, "owner")
                {:ok, workspace}

              error ->
                error
            end
        end

      # Regular user creating their own workspace
      is_nil(owner_email) ->
        # Use current user as owner
        attrs_with_owner = Map.put(attrs, "owner_id", current_user.id)

        %Workspace{}
        |> Workspace.changeset(attrs_with_owner)
        |> Repo.insert()
        |> case do
          {:ok, workspace} ->
            # CRITICAL: Add the creator as a member of the workspace too!
            # We bypass the permission check here because we are establishing the initial owner.
            %UserWorkspace{}
            |> UserWorkspace.changeset(%{
              user_id: current_user.id,
              workspace_id: workspace.id,
              role: "owner"
            })
            |> Repo.insert()

            {:ok, workspace}

          error ->
            error
        end

      true ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Updates a workspace.
  """
  def update_workspace(%User{} = current_user, %Workspace{} = workspace, attrs) do
    if can_edit?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
      workspace
      |> Workspace.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a workspace.
  """
  def delete_workspace(%User{} = current_user, %Workspace{} = workspace) do
    if can_delete_workspace?(current_user, workspace) or
         AppPlanner.Accounts.super_admin?(current_user) do
      Repo.delete(workspace)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Creates a user workspace entry.
  """
  def create_user_workspace(
        %User{} = current_user,
        %Workspace{} = workspace,
        %User{} = invited_user,
        role
      ) do
    if can_invite?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
      %UserWorkspace{}
      |> UserWorkspace.changeset(%{
        user_id: invited_user.id,
        workspace_id: workspace.id,
        role: role
      })
      |> Repo.insert()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a user workspace entry.
  """
  def update_user_workspace(%UserWorkspace{} = user_workspace, attrs) do
    user_workspace
    |> UserWorkspace.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user workspace entry.
  """
  def delete_user_workspace(%User{} = current_user, %UserWorkspace{} = user_workspace) do
    workspace = get_workspace!(user_workspace.workspace_id)

    cond do
      # Super admin can delete any user workspace
      AppPlanner.Accounts.super_admin?(current_user) ->
        Repo.delete(user_workspace)

      # User deleting their own entry, but not if they are the owner of the workspace
      user_workspace.user_id == current_user.id and can_leave_workspace?(current_user, workspace) ->
        Repo.delete(user_workspace)

      true ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Generates an invitation link for a workspace.
  """
  def generate_invite_link(
        %User{} = current_user,
        %Workspace{} = workspace,
        invited_email,
        invite_url_fun
      )
      when is_function(invite_url_fun, 1) do
    if can_invite?(current_user, workspace) or AppPlanner.Accounts.super_admin?(current_user) do
      {encoded_token, user_token} =
        AppPlanner.Accounts.UserToken.build_workspace_invite_token(
          current_user,
          workspace,
          invited_email
        )

      case Repo.insert(user_token) do
        {:ok, _} -> {:ok, invite_url_fun.(encoded_token)}
        error -> error
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Accepts a workspace invitation link.
  """
  def accept_invite_link(token, %User{} = current_user \\ nil) do
    case AppPlanner.Accounts.UserToken.verify_workspace_invite_token_query(token) do
      {:ok, query} ->
        case Repo.one(query) do
          # Token not found or expired
          nil ->
            {:error, :invalid_or_expired_token}

          %AppPlanner.Accounts.UserToken{workspace: workspace, invited_email: invited_email} =
              user_token ->
            user_to_add =
              cond do
                current_user && current_user.email == invited_email ->
                  # User is logged in and their email matches the invited email
                  current_user

                current_user ->
                  # User is logged in, but their email doesn't match the invited email
                  {:error, :email_mismatch}

                true ->
                  # No user logged in, or current_user is nil, attempt to find by invited_email
                  AppPlanner.Accounts.get_user_by_email(invited_email)
              end

            case user_to_add do
              {:error, _} = error ->
                error

              # User not found, prompt for registration or new user flow
              nil ->
                {:prompt_register, invited_email, workspace}

              %User{} = user ->
                # User exists or was just found, add them to the workspace
                %UserWorkspace{}
                |> UserWorkspace.changeset(%{
                  user_id: user.id,
                  workspace_id: workspace.id,
                  role: "member"
                })
                |> Repo.insert()
                |> case do
                  {:ok, _user_workspace} ->
                    # Delete the token only after successful join
                    Repo.delete!(user_token)
                    {:ok, user, workspace}

                  error ->
                    error
                end
            end
        end

      :error ->
        {:error, :invalid_token_format}
    end
  end

  @doc """
  Checks if a user can invite others to a workspace.
  Only owners can invite.
  """
  def can_invite?(%User{} = user, %Workspace{} = workspace) do
    case get_user_workspace(user, workspace) do
      %UserWorkspace{role: "owner"} -> true
      _ -> false
    end
  end

  @doc """
  Checks if a user can edit / update features in a workspace.
  Owners and editors can edit.
  """
  def can_edit?(%User{} = user, %Workspace{} = workspace) do
    case get_user_workspace(user, workspace) do
      %UserWorkspace{role: "owner"} -> true
      %UserWorkspace{role: "editor"} -> true
      %UserWorkspace{role: "member"} -> true
      _ -> false
    end
  end

  @doc """
  Checks if a user can view features in a workspace.
  Owners, editors, and members can view.
  """
  def can_view?(%User{} = user, %Workspace{} = workspace) do
    case get_user_workspace(user, workspace) do
      %UserWorkspace{role: "owner"} -> true
      %UserWorkspace{role: "editor"} -> true
      %UserWorkspace{role: "member"} -> true
      _ -> false
    end
  end

  @doc """
  Checks if a user can delete a workspace.
  Only owners can delete.
  """
  def can_delete_workspace?(%User{} = user, %Workspace{} = workspace) do
    get_user_workspace(user, workspace)
    |> case do
      %UserWorkspace{role: "owner"} -> true
      _ -> false
    end
  end

  @doc """
  Checks if a user can leave a workspace.
  Users cannot leave their own created workspace (owner).
  """
  def can_leave_workspace?(%User{} = user, %Workspace{} = workspace) do
    case get_user_workspace(user, workspace) do
      %UserWorkspace{role: "owner"} -> false
      %UserWorkspace{} -> true
      _ -> false
    end
  end
end
