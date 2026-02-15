defmodule AppPlannerWeb.WorkspaceLive.Show do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Workspaces
  alias AppPlanner.Planner

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:invite_link, nil)
     |> assign(:invite_form, to_form(%{"invited_email" => ""}))}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    current_user = socket.assigns.current_scope.user
    workspace = Workspaces.get_workspace!(id)

    if Workspaces.can_view?(current_user, workspace) or
         AppPlanner.Accounts.super_admin?(current_user) do
      # Fetch apps for the current workspace
      apps =
        case Planner.list_workspace_apps(current_user, workspace.id) do
          apps_list when is_list(apps_list) -> apps_list
          {:error, _} -> []
        end

      {:noreply,
       socket
       |> assign(:workspace, workspace)
       |> assign(:apps, apps)
       |> assign(
         :can_edit,
         Workspaces.can_edit?(current_user, workspace) ||
           AppPlanner.Accounts.super_admin?(current_user)
       )
       |> assign(
         :can_invite,
         Workspaces.can_invite?(current_user, workspace) ||
           AppPlanner.Accounts.super_admin?(current_user)
       )
       |> assign(
         :is_owner,
         workspace.owner_id == current_user.id ||
           AppPlanner.Accounts.super_admin?(current_user)
       )
       |> assign(:workspace_members, Workspaces.list_workspace_members(workspace.id))}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You do not have permission to view this workspace.")
       |> push_navigate(to: ~p"/workspaces")}
    end
  end

  @impl true
  def handle_event(
        "generate_invite_link",
        %{"invited_email" => invited_email},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    workspace = socket.assigns.workspace

    case Workspaces.generate_invite_link(current_user, workspace, invited_email, fn token ->
           url(~p"/invite/#{token}")
         end) do
      {:ok, invite_link} ->
        {:noreply,
         socket
         |> put_flash(:info, "Invitation link generated")
         |> assign(:invite_link, invite_link)
         |> assign(:invite_form, to_form(%{"invited_email" => ""}))}

      {:error, :unauthorized} ->
        {:noreply,
         socket |> put_flash(:error, "You are not authorized to invite users to this workspace.")}

      {:error, reason} ->
        {:noreply,
         socket |> put_flash(:error, "Failed to generate invite link: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("delete_workspace", _, socket) do
    current_user = socket.assigns.current_scope.user
    workspace = socket.assigns.workspace

    case Workspaces.delete_workspace(current_user, workspace) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workspace deleted successfully")
         |> push_navigate(to: ~p"/workspaces")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Could not delete workspace")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-12 px-6">
      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-8 mb-16">
        <div>
          <div class="flex items-center gap-3 mb-2">
            <span class="text-[10px] font-black uppercase tracking-widest text-primary bg-primary/5 px-2 py-0.5 rounded border border-primary/10">
              Active Workspace
            </span>
          </div>
          <h1 class="text-4xl font-black tracking-tight text-base-content leading-tight">
            {@workspace.name}
          </h1>
          <p class="text-sm text-base-content/40 font-medium italic mt-2">
            Owned by {@workspace.owner.full_name || @workspace.owner.email}
          </p>
        </div>

        <div class="flex items-center gap-3">
          <.link
            navigate={~p"/workspaces/#{@workspace.id}/board"}
            class="btn btn-ghost rounded-lg px-6 uppercase text-[10px] font-black tracking-widest border border-base-200"
          >
            <.icon name="hero-view-columns" class="w-4 h-4 mr-2" /> Board
          </.link>

          <%= if @is_owner do %>
            <div class="dropdown dropdown-end">
              <button
                tabindex="0"
                class="btn btn-primary btn-square rounded-lg shadow-lg shadow-primary/20"
              >
                <.icon name="hero-ellipsis-vertical" class="w-5 h-5" />
              </button>
              <ul
                tabindex="0"
                class="dropdown-content z-[2] menu p-2 shadow-2xl bg-base-100 rounded-xl border border-base-200 w-52 mt-2"
              >
                <li>
                  <.link
                    navigate={~p"/workspaces/#{@workspace.id}/edit"}
                    class="flex items-center gap-3 py-3 text-[10px] font-black uppercase tracking-widest hover:bg-primary/5 hover:text-primary transition-all rounded-lg"
                  >
                    <.icon name="hero-pencil-square" class="w-4 h-4" /> Edit Workspace
                  </.link>
                </li>
                <li>
                  <button
                    phx-click="delete_workspace"
                    data-confirm="Are you sure you want to shut down this workspace? All apps and tasks will be permanently erased."
                    class="flex items-center gap-3 py-3 text-[10px] font-black uppercase tracking-widest text-error hover:bg-error/5 transition-all rounded-lg"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" /> Delete Workspace
                  </button>
                </li>
              </ul>
            </div>
          <% end %>
          <%= if @can_edit do %>
            <.link
              navigate={~p"/workspaces/#{@workspace.id}/apps/new"}
              class="btn btn-primary rounded-lg px-8 font-bold text-[10px] uppercase tracking-widest shadow-lg shadow-primary/20"
            >
              <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New Project
            </.link>
          <% end %>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-12">
        <div class="lg:col-span-2 space-y-12">
          <section>
            <div class="flex items-center justify-between mb-8">
              <h2 class="text-[10px] font-black uppercase text-base-content/40 tracking-widest">
                Workspace Projects
              </h2>
              <span class="text-[9px] font-black text-primary px-2 py-0.5 rounded bg-primary/5">
                {length(@apps)} Total
              </span>
            </div>

            <%= if Enum.empty?(@apps) do %>
              <div class="bg-base-50/50 rounded-xl border-2 border-dashed border-base-200 p-16 text-center">
                <div class="w-16 h-16 bg-base-100 rounded-full flex items-center justify-center mx-auto mb-6">
                  <.icon name="hero-square-3-stack-3d" class="w-8 h-8 text-base-content/10" />
                </div>
                <h3 class="text-xl font-black tracking-tight mb-2">No projects yet</h3>
                <p class="text-sm text-base-content/40 font-medium max-w-xs mx-auto mb-8 italic">
                  Every great invention starts with a single blueprint. Create your first project to get started.
                </p>
                <.link
                  navigate={~p"/workspaces/#{@workspace.id}/apps/new"}
                  class="btn btn-primary btn-sm rounded-lg px-8 text-[10px] font-black uppercase tracking-widest"
                >
                  New Project
                </.link>
              </div>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <%= for app <- @apps do %>
                  <.link
                    navigate={~p"/workspaces/#{@workspace.id}/board?app_id=#{app.id}"}
                    class="group bg-base-200 p-6 rounded-xl border border-base-50 hover:border-primary hover:shadow-xl hover:shadow-primary/5 transition-all"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <div class="w-12 h-12 rounded-lg bg-base-50 border border-base-200 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white group-hover:border-primary transition-all">
                        <.icon
                          name={if app.icon, do: "hero-#{app.icon}", else: "hero-cube"}
                          class="w-6 h-6"
                        />
                      </div>
                      <div class="flex-1 min-w-0">
                        <h4 class="text-lg font-black tracking-tight group-hover:text-primary transition-colors truncate">
                          {app.name}
                        </h4>
                        <p class="text-[9px] font-black uppercase text-base-content/20 tracking-widest">
                          Architectural Draft
                        </p>
                      </div>
                    </div>
                    <div class="flex items-center justify-between pt-4 border-t border-base-50">
                      <span class="text-[9px] font-black uppercase tracking-widest text-base-content/30 italic">
                        Active Scope
                      </span>
                      <.icon
                        name="hero-arrow-right"
                        class="w-3.5 h-3.5 text-base-content/10 group-hover:text-primary group-hover:translate-x-1 transition-all"
                      />
                    </div>
                  </.link>
                <% end %>
              </div>
            <% end %>
          </section>
        </div>

        <aside class="space-y-12">
          <%= if @can_invite do %>
            <section class="bg-base-50/50 rounded-xl border border-base-200 p-8 space-y-8">
              <div>
                <h3 class="text-[10px] font-black uppercase text-base-content/40 tracking-widest mb-2">
                  Team Expansion
                </h3>
                <p class="text-xs text-base-content/40 font-medium italic leading-relaxed">
                  Collaborate by inviting visionaries to your workspace environment.
                </p>
              </div>

              <.form for={@invite_form} phx-submit="generate_invite_link" class="space-y-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                      Collaborator Email
                    </span>
                  </label>
                  <.input
                    field={@invite_form[:invited_email]}
                    type="email"
                    placeholder="Enter email address"
                    required
                    class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
                  />
                </div>
                <button
                  type="submit"
                  class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20"
                >
                  Generate Magic Link
                </button>
              </.form>

              <%= if @invite_link do %>
                <div class="p-4 bg-base-100/50 rounded-xl border border-primary/20 shadow-sm">
                  <div class="flex flex-col gap-1 mb-3">
                    <span class="text-[8px] font-black uppercase text-base-content/30 tracking-widest">
                      Workspace Invitation Link
                    </span>
                    <div class="flex items-center gap-2">
                      <input
                        type="text"
                        readonly
                        value={@invite_link}
                        class="input input-xs bg-base-100 w-full font-mono text-[9px] border-primary/20 h-8 rounded-lg"
                        id="invite-link-input"
                      />
                      <button
                        class="btn btn-primary btn-xs h-8 rounded-lg"
                        onclick="document.getElementById('invite-link-input').select(); document.execCommand('copy');"
                        title="Copy to clipboard"
                      >
                        <.icon name="hero-clipboard-document-check" class="w-3.5 h-3.5" />
                      </button>
                    </div>
                    <p class="text-[9px] font-medium text-base-content/40 mt-1">
                      Anyone with this link can join the workspace. Keep it secure.
                    </p>
                  </div>
                </div>
              <% end %>
            </section>
          <% end %>

          <section class="bg-base-100 rounded-xl border border-base-200 p-8 shadow-sm">
            <h3 class="text-[10px] font-black uppercase text-base-content/20 tracking-widest mb-6">
              Workspace Members
            </h3>
            <div class="space-y-4">
              <%= for member <- @workspace_members do %>
                <div class="flex items-center gap-3">
                  <div class="w-8 h-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-[10px] font-black uppercase ring-1 ring-base-200 shadow-sm">
                    {String.at(member.user.email, 0) |> String.upcase()}
                  </div>
                  <div class="flex flex-col min-w-0">
                    <span class="text-xs font-black text-base-content truncate">
                      {member.user.email}
                    </span>
                    <span class="text-[8px] font-bold text-base-content/30 uppercase tracking-widest">
                      {member.role}
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          </section>

          <section class="bg-base-100 rounded-xl border border-base-200 p-8 shadow-sm">
            <h3 class="text-[10px] font-black uppercase text-base-content/20 tracking-widest mb-6">
              Environment Signature
            </h3>
            <div class="space-y-4">
              <div class="flex flex-col border-l-2 border-base-200 pl-4 py-1">
                <span class="text-[8px] font-black uppercase text-base-content/20 leading-none mb-1">
                  Unique Identifier
                </span>
                <span class="text-[10px] font-mono font-bold text-base-content/60 truncate">
                  {@workspace.id}
                </span>
              </div>
              <div class="flex flex-col border-l-2 border-base-200 pl-4 py-1">
                <span class="text-[8px] font-black uppercase text-base-content/20 leading-none mb-1">
                  Created At
                </span>
                <span class="text-[10px] font-bold text-base-content/60">
                  {@workspace.inserted_at |> Calendar.strftime("%b %d, %Y")}
                </span>
              </div>
            </div>
          </section>
        </aside>
      </div>
    </div>
    """
  end
end
