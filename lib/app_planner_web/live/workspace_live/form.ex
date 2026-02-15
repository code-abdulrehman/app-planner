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
    # For regular users creating a workspace, inject owner_id if missing
    workspace_params =
      if is_nil(workspace_params["owner_id"]) && is_nil(socket.assigns.workspace.id) &&
           socket.assigns.current_user do
        Map.put(workspace_params, "owner_id", socket.assigns.current_user.id)
      else
        workspace_params
      end

    changeset =
      socket.assigns.workspace
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

  defp assign_form(socket, params, workspace) when is_struct(workspace, Workspace) do
    current_user = params[:current_user] || socket.assigns[:current_user]

    # For a new workspace, workspace.owner will be nil, so owner_email will be nil.
    # For an existing workspace, if owner is loaded, use its email.
    owner_email =
      case workspace.owner do
        %AppPlanner.Accounts.User{email: email} -> email
        _ -> if current_user, do: current_user.email, else: nil
      end

    # Build the form with existing workspace data
    changeset =
      if workspace.id do
        workspace |> Workspace.changeset(%{})
      else
        workspace |> Workspace.changeset(%{owner_id: current_user.id})
      end
      |> Ecto.Changeset.put_change(:owner_email, owner_email)

    socket
    |> assign(:params, params)
    |> assign(:workspace, workspace)
    |> assign(:current_user, current_user)
    |> assign(:page_title, if(workspace.id, do: "Edit Workspace", else: "New Workspace"))
    |> assign(:form, to_form(changeset, as: :workspace))
  end

  defp assign_form(socket, params, %Ecto.Changeset{} = changeset) do
    current_user = params[:current_user] || socket.assigns[:current_user]

    socket
    |> assign(:params, params)
    |> assign(:current_user, current_user)
    |> assign(
      :page_title,
      if(socket.assigns.workspace.id, do: "Edit Workspace", else: "New Workspace")
    )
    |> assign(:form, to_form(changeset, as: :workspace))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-12 px-6">
      <div class="mb-10 flex items-center justify-between">
        <div>
          <div class="flex items-center gap-2 text-[10px] font-black uppercase text-base-content/30 tracking-widest mb-2">
            <.link navigate={~p"/workspaces"} class="hover:text-primary transition-colors">
              Workspaces
            </.link>
            <span>/</span>
            <span class="text-base-content/80">{@page_title}</span>
          </div>
          <h1 class="text-3xl font-black text-base-content tracking-tight">{@page_title}</h1>
        </div>

        <.link
          navigate={~p"/workspaces"}
          class="btn btn-ghost btn-sm rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200"
        >
          Cancel
        </.link>
      </div>

      <.form
        for={@form}
        id="workspace_form"
        phx-change="validate"
        phx-submit="save"
        class="space-y-8"
      >
        <div class="bg-base-50/50 border border-base-200 rounded-xl p-8 space-y-8">
          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Workspace Identity
              </span>
            </label>
            <.input
              field={@form[:name]}
              type="text"
              value={Phoenix.HTML.Form.input_value(@form, :name)}
              placeholder="e.g. Creative Engineering Studio"
              required
              class="input input-bordered w-full rounded-lg bg-base-100 font-bold h-12"
            />
          </div>

          <%= if @current_user.role == "super_admin" and is_nil(@workspace.id) do %>
            <div class="form-control">
              <label class="label">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Primary Owner
                </span>
              </label>
              <.input
                field={@form[:owner_email]}
                type="email"
                placeholder="Enter owner's email address"
                class="input input-bordered w-full rounded-lg bg-base-100 font-bold h-12"
              />
              <p class="mt-2 text-[10px] text-base-content/30 font-medium">
                Administrator access will be granted to this user upon creation.
              </p>
            </div>
          <% end %>

          <div class="divider opacity-20"></div>

          <div class="flex items-center gap-4 text-base-content/40 p-4 bg-base-100/50 rounded-lg border border-dashed border-base-200">
            <div class="w-10 h-10 rounded-full bg-primary/5 flex items-center justify-center text-primary">
              <.icon name="hero-building-office" class="w-5 h-5" />
            </div>
            <div>
              <p class="text-[10px] font-black uppercase tracking-widest">Environment Ready</p>
              <p class="text-[9px] font-medium italic">
                Projects and team members will be isolated within this workspace.
              </p>
            </div>
          </div>
        </div>

        <div class="flex justify-end pt-4">
          <button
            type="submit"
            phx-disable-with="Setting up..."
            class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-12 shadow-lg shadow-primary/20 h-10"
          >
            {if @workspace.id, do: "Update Environment", else: "Launch Workspace"}
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
