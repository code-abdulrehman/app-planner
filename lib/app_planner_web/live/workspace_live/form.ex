defmodule AppPlannerWeb.WorkspaceLive.Form do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Workspaces

  alias AppPlanner.Planner.Workspace

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    workspace = Workspaces.get_workspace!(id)
    current_user = socket.assigns.current_scope.user

    if Workspaces.can_edit?(current_user, workspace) or
         AppPlanner.Accounts.super_admin?(current_user) do
      {:ok, assign_form(socket, Map.put(params, :current_user, current_user), workspace)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You do not have permission to edit this workspace.")
       |> push_navigate(to: ~p"/workspaces/#{id}")}
    end
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    {:ok, assign_form(socket, %{current_user: current_user}, %Workspace{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_scope.user

    workspace =
      case params["id"] do
        nil -> %Workspace{}
        id -> Workspaces.get_workspace!(id)
      end

    if (not is_nil(workspace.id) and Workspaces.can_edit?(current_user, workspace)) or
         (is_nil(workspace.id) and not is_nil(current_user)) or
         AppPlanner.Accounts.super_admin?(current_user) do
      {:noreply, assign_form(socket, Map.put(params, :current_user, current_user), workspace)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You do not have permission to access this page.")
       |> push_navigate(to: ~p"/workspaces")}
    end
  end

  @impl true
  def handle_event("validate", %{"workspace" => workspace_params}, socket) do
    changeset =
      %Workspace{}
      |> Workspace.changeset(workspace_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, socket.assigns.params, changeset)}
  end

  @impl true
  def handle_event("save", %{"workspace" => workspace_params}, socket) do
    current_user = socket.assigns.current_user
    workspace = socket.assigns.workspace

    case handle_save(current_user, workspace, workspace_params) do
      {:ok, saved_workspace} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workspace saved successfully!")
         |> push_navigate(to: ~p"/workspaces/#{saved_workspace.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, socket.assigns.params, changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to perform this action.")
         |> push_navigate(to: ~p"/workspaces")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Error saving workspace: #{inspect(reason)}")}
    end
  end

  defp handle_save(current_user, %Workspace{} = workspace, workspace_params) do
    if workspace.id do
      Workspaces.update_workspace(current_user, workspace, workspace_params)
    else
      Workspaces.create_workspace(current_user, workspace_params)
    end
  end

  defp assign_form(socket, params, workspace) do
    # For a new workspace, workspace.owner will be nil, so owner_email will be nil.
    # For an existing workspace, if owner is loaded, use its email.
    # Check if owner is actually loaded (not an Ecto.Association.NotLoaded struct)
    owner_email =
      case workspace.owner do
        %AppPlanner.Accounts.User{email: email} -> email
        _ -> nil
      end

    # When creating a new form, use the workspace struct directly.
    # When validating after an event, params might contain the latest data.
    form =
      workspace
      # Inject owner_email into the struct for form
      |> Map.put(:owner_email, owner_email)
      # Use params for validation, or empty map
      |> Workspace.changeset(params["workspace"] || %{})
      |> to_form(as: :workspace)

    socket
    |> assign(:params, params)
    |> assign(:workspace, workspace)
    |> assign(:form, form)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-12 px-6">
      <div class="mb-10 flex items-center justify-between">
        <div>
           <h1 class="text-3xl font-black text-base-content tracking-tight">
             <%= if @workspace.id, do: "Edit Workspace", else: "New Workspace" %>
           </h1>
           <p class="text-sm text-base-content/40 mt-1 font-medium">
             <%= if @workspace.id, do: "Update your workspace profile", else: "Create a home for your projects" %>
           </p>
        </div>

        <.link navigate={~p"/workspaces"} class="btn btn-ghost btn-sm rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200">
           Cancel
        </.link>
      </div>

      <.form
        for={@form}
        id="workspace_form"
        phx-change="validate"
        phx-submit="save"
        class="bg-base-50/50 border border-base-200 rounded-lg p-8 space-y-8"
      >
        <div class="form-control">
           <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Workspace Name</span></label>
           <.input field={@form[:name]} type="text" placeholder="e.g. Acme Studio" required class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
        </div>

        <%= if @is_super_admin && is_nil(@workspace.id) do %>
          <div class="form-control">
             <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Owner Email</span></label>
             <.input field={@form[:owner_email]} type="email" placeholder="owner@example.com" class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
          </div>
        <% end %>

        <div class="flex justify-end pt-4">
           <button type="submit" class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-10 shadow-lg shadow-primary/20">
             <%= if @workspace.id, do: "Update Workspace", else: "Save Workspace" %>
           </button>
        </div>
      </.form>
    </div>
    """
  end

  defp breadcrumb_items_workspace_form(workspace, current_workspace) do
    if workspace.id do
      [
        %{label: "Workspaces", path: ~p"/workspaces"},
        %{label: current_workspace.name, path: ~p"/workspaces/#{current_workspace}"},
        %{label: "Edit", path: nil}
      ]
    else
      [
        %{label: "Workspaces", path: ~p"/workspaces"},
        %{label: "New", path: nil}
      ]
    end
  end
end
