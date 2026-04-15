defmodule AppPlannerWeb.WorkspaceSelector do
  @moduledoc """
  A function component for workspace selection dropdown.
  Works in both LiveView and regular controller contexts.
  """
  use AppPlannerWeb, :html

  alias AppPlanner.Workspaces
  alias AppPlannerWeb.ScopeFromPath

  def on_mount(:load_current_workspace, params, _session, socket) do
    params = ScopeFromPath.merge_scoped_params(params, nil)

    workspace_id = params["workspace_id"] || params["id"]

    user = socket.assigns.current_scope.user

    case workspace_id do
      nil ->
        {:cont, assign(socket, :current_workspace, nil)}

      id ->
        try do
          workspace = AppPlanner.Workspaces.get_workspace!(id)
          # Only assign if the user is a member
          if AppPlanner.Workspaces.can_view?(user, workspace) or
               AppPlanner.Accounts.super_admin?(user) do
            {:cont, assign(socket, :current_workspace, workspace)}
          else
            {:cont, assign(socket, :current_workspace, nil)}
          end
        rescue
          Ecto.NoResultsError ->
            {:cont, assign(socket, :current_workspace, nil)}
        end
    end
  end

  attr(:current_user, :map, required: true)
  attr(:current_workspace, :map, default: nil)

  def workspace_selector(assigns) do
    user_workspaces =
      if assigns.current_user, do: Workspaces.list_user_workspaces(assigns.current_user), else: []

    assigns = assign(assigns, :user_workspaces, user_workspaces)

    ~H"""
    <div class="dropdown dropdown-end">
      <div
        tabindex="0"
        role="button"
        class="btn btn-ghost btn-sm rounded-lg font-black uppercase tracking-widest text-[9px] border border-base-200 h-8 flex items-center px-4 hover:bg-base-200"
      >
        <%= if @current_workspace do %>
          <div class="flex items-center gap-2">
            <div class="w-4 h-4 rounded-md bg-primary/10 text-primary flex items-center justify-center text-[8px] font-black">
              {String.at(@current_workspace.name, 0) |> String.upcase()}
            </div>
            {@current_workspace.name}
          </div>
        <% else %>
          Select Workspace
        <% end %>
        <.icon name="hero-chevron-down" class="ml-2 size-3 opacity-40" />
      </div>
      <ul
        tabindex="0"
        class="mt-2 z-[50] p-1 shadow-xl menu menu-sm dropdown-content bg-base-100 rounded-lg w-52 border border-base-200"
      >
        <li class="menu-title text-[9px] font-black uppercase tracking-widest text-base-content/30 py-2.5 px-4 border-b border-base-200/50 mb-1">
          Workspaces
        </li>
        <%= for workspace <- @user_workspaces do %>
          <li>
            <.link
              navigate={~p"/workspaces/#{workspace.id}"}
              class={[
                "py-2.5 font-bold text-base-content/70 flex items-center gap-2",
                @current_workspace && @current_workspace.id == workspace.id &&
                  "bg-primary/5 text-primary"
              ]}
            >
              <div class="w-5 h-5 rounded-md bg-base-200 flex items-center justify-center text-[10px] font-black">
                {String.at(workspace.name, 0) |> String.upcase()}
              </div>
              {workspace.name}
            </.link>
          </li>
        <% end %>
        <div class="divider my-0 opacity-10"></div>
        <li>
          <.link navigate={~p"/workspaces/new"} class="py-2.5 font-bold text-base-content/70">
            <.icon name="hero-plus" class="w-4 h-4 mr-2" /> Add Workspace
          </.link>
        </li>
        <li>
          <.link navigate={~p"/workspaces"} class="py-2.5 font-bold text-base-content/70">
            <.icon name="hero-rectangle-stack" class="w-4 h-4 mr-2" /> All Workspaces
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
