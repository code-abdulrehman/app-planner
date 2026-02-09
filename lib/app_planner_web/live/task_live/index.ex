defmodule AppPlannerWeb.TaskLive.Index do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Workspaces

  @impl true
  def mount(params, _session, socket) do
    workspace_id = params["workspace_id"]
    app_id = params["app_id"]
    feature_id = params["feature_id"]
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace

    if is_nil(current_workspace) do
      # Fallback if somehow current_workspace is nil
      {:ok, push_navigate(socket, to: ~p"/workspaces")}
    else
      feature = Planner.get_feature!(feature_id, user, workspace_id)
      app = Planner.get_app!(app_id, user, workspace_id)

      # For the collapsible sidebar
      apps_with_features =
        Planner.list_apps(user, workspace_id)
        |> Enum.map(fn a ->
          %{a | features: Planner.list_features(user, a.id, workspace_id)}
        end)

      workspace_members = Workspaces.list_workspace_members(workspace_id)

      {:ok,
       socket
       |> assign(:workspace_id, workspace_id)
       |> assign(:app_id, app_id)
       |> assign(:feature, feature)
       |> assign(:app, app)
       |> assign(:apps_with_features, apps_with_features)
       |> assign(:workspace_members, workspace_members)
       |> assign(:statuses, Planner.task_statuses(current_workspace))
       # Default current app expanded
       |> assign(:expanded_apps, MapSet.new([app_id]))
       |> fetch_tasks()}
    end
  end

  defp fetch_tasks(socket) do
    tasks = Planner.list_tasks_by_feature(socket.assigns.feature.id)
    tasks_by_status = Enum.group_by(tasks, & &1.status)
    assign(socket, tasks_by_status: tasks_by_status)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Tasks Board")
    |> assign(:task, nil)
  end

  defp apply_action(socket, :add_column, _params) do
    socket
    |> assign(:page_title, "Add Column")
    |> assign(:task, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden bg-base-100">
      <!-- Collapsible Sidebar -->
      <aside class="w-72 border-r border-base-200 bg-base-50 flex flex-col shrink-0 transition-all">
        <div class="p-6 flex items-center justify-between border-b border-base-200 bg-base-100">
           <h2 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">Navigator</h2>
           <.link navigate={~p"/workspaces/#{@workspace_id}/apps"} class="text-[10px] font-bold text-primary hover:underline uppercase">All Projects</.link>
        </div>

        <div class="flex-1 overflow-y-auto p-3 space-y-2">
            <%= for a <- @apps_with_features do %>
              <div class="space-y-0.5">
                 <div
                    phx-click="toggle_app"
                    phx-value-id={a.id}
                    class={["flex items-center justify-between p-2 rounded-lg cursor-pointer transition-all group",
                            if(a.id == String.to_integer(@app_id), do: "bg-primary/5 text-primary", else: "hover:bg-base-200 text-base-content/70")]}
                 >
                    <div class="flex items-center gap-2.5">
                       <.icon name={if MapSet.member?(@expanded_apps, to_string(a.id)), do: "hero-chevron-down", else: "hero-chevron-right"} class="w-3 h-3 opacity-40 shrink-0" />
                       <.icon name={if a.icon, do: "hero-#{a.icon}", else: "hero-cube"} class="w-4 h-4 shrink-0" />
                       <span class="text-[11px] font-black uppercase tracking-tight truncate w-32">{a.name}</span>
                    </div>

                     <div class="dropdown dropdown-end" phx-click-stop text-left>
                        <button tabindex="0" class="btn btn-ghost btn-xs btn-circle opacity-0 group-hover:opacity-100 transition-opacity" phx-click-stop>
                           <.icon name="hero-ellipsis-horizontal" class="w-3.5 h-3.5" />
                        </button>
                        <ul tabindex="0" class="dropdown-content z-[1] menu p-1 shadow-lg bg-base-100 rounded-lg border border-base-200 text-[10px] font-bold uppercase w-40">
                           <li><.link navigate={~p"/workspaces/#{@workspace_id}/apps/#{a.id}/features/new"}><.icon name="hero-plus" class="w-3 h-3" /> Add Module</.link></li>
                           <li><button phx-click="delete_app" phx-value-id={a.id} data-confirm="Delete this project?" class="text-error hover:bg-error/5"><.icon name="hero-trash" class="w-3 h-3" /> Delete</button></li>
                        </ul>
                     </div>
                 </div>

                 <div :if={MapSet.member?(@expanded_apps, to_string(a.id))} class="pl-6 space-y-0.5 pb-2">
                    <%= for f <- a.features do %>
                       <div class="flex items-center group/feature">
                          <.link
                            navigate={~p"/workspaces/#{@workspace_id}/apps/#{a.id}/features/#{f.id}/tasks"}
                            class={["flex-1 flex items-center gap-2.5 px-3 py-2 rounded-lg text-[10px] font-bold transition-all border border-transparent truncate",
                                    if(f.id == @feature.id, do: "bg-white shadow-sm border-base-200 text-primary", else: "text-base-content/50 hover:bg-base-200 hover:text-base-content")]}
                          >
                            <.icon name={if f.icon, do: "hero-#{f.icon}", else: "hero-bolt"} class="w-3.5 h-3.5 shrink-0" />
                            <span class="truncate">{f.title}</span>
                          </.link>

                          <div class="dropdown dropdown-end" phx-click-stop text-left>
                             <button tabindex="0" class="btn btn-ghost btn-xs btn-circle opacity-0 group-hover/feature:opacity-100 transition-opacity" phx-click-stop>
                                <.icon name="hero-ellipsis-vertical" class="w-3 h-3" />
                             </button>
                             <ul tabindex="0" class="dropdown-content z-[1] menu p-1 shadow-lg bg-base-100 rounded-lg border border-base-200 text-[10px] font-bold uppercase w-40">
                                <li><button phx-click="delete_feature" phx-value-id={f.id} data-confirm="Delete this module?" class="text-error hover:bg-error/5"><.icon name="hero-trash" class="w-3 h-3" /> Delete</button></li>
                             </ul>
                          </div>
                       </div>
                    <% end %>
                    <.link
                       navigate={~p"/workspaces/#{@workspace_id}/apps/#{a.id}/features/new"}
                       class="flex items-center gap-2.5 px-3 py-2 text-[9px] font-black uppercase text-base-content/20 hover:text-primary transition-colors tracking-widest pl-4"
                    >
                       <.icon name="hero-plus-circle" class="w-3.5 h-3.5" /> Add Module
                    </.link>
                 </div>
              </div>
            <% end %>
        </div>

        <div class="p-4 border-t border-base-200 bg-base-100">
           <.link navigate={~p"/workspaces/#{@workspace_id}/apps/new"} class="btn btn-outline btn-sm btn-block rounded-lg text-[10px] font-black uppercase tracking-widest border-base-200 font-bold hover:bg-primary hover:text-white hover:border-primary">
              <div class="flex items-center gap-2">
                 <.icon name="hero-plus" class="w-3 h-3" /> New Project
              </div>
           </.link>
        </div>
      </aside>

      <!-- Main Content Area -->
      <div class="flex-1 flex flex-col min-w-0">
        <!-- Header -->
        <header class="h-24 border-b border-base-200 bg-base-100/80 backdrop-blur-md flex flex-col justify-center px-8 sticky top-0 z-30">
          <div class="flex items-center justify-between w-full h-1/2 mb-2">
            <div class="flex items-center gap-6">
              <!-- Breadcrumbs -->
              <div class="hidden md:flex items-center gap-2">
                 <.link navigate={~p"/workspaces"} class="text-[9px] font-black uppercase text-base-content/30 hover:text-primary tracking-widest transition-colors">
                    Workspace
                 </.link>
                 <span class="text-[9px] text-base-content/10">/</span>
                 <.link navigate={~p"/workspaces/#{@workspace_id}/apps"} class="text-[9px] font-black uppercase text-base-content/30 hover:text-primary tracking-widest transition-colors">
                    {@app.name}
                 </.link>
                 <span class="text-[9px] text-base-content/10">/</span>
                 <div class="text-[9px] font-black uppercase text-base-content/80 tracking-widest pl-1">
                    {@feature.title}
                 </div>
              </div>

              <!-- Avatars Group -->
              <div class="flex items-center gap-2 pl-6 border-l border-base-200">
                <div class="flex -space-x-1.5">
                  <%= for member <- Enum.take(@workspace_members, 5) do %>
                    <div
                       class="w-6 h-6 rounded-md bg-base-200 ring-2 ring-base-100 flex items-center justify-center text-[8px] font-black text-base-content/40 uppercase cursor-help hover:z-10 transition-all hover:scale-110 shadow-sm"
                       title={member.email}
                    >
                      {String.at(member.email, 0)}
                    </div>
                  <% end %>
                  <%= if length(@workspace_members) > 5 do %>
                    <div class="w-6 h-6 rounded-md bg-primary text-white ring-2 ring-base-100 flex items-center justify-center text-[8px] font-black shadow-sm">
                      +{length(@workspace_members) - 5}
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="flex items-center gap-2">
               <.link
                  navigate={~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks/new"}
                  class="btn btn-primary btn-xs rounded-lg px-6 text-[9px] font-black uppercase tracking-widest shadow-lg shadow-primary/20 transition-all h-8 flex items-center"
               >
                  <.icon name="hero-plus" class="w-3.5 h-3.5 mr-1.5" /> New Task
               </.link>
            </div>
          </div>

          <div class="flex items-center gap-8 mt-1">
             <button class="text-[10px] font-black uppercase tracking-widest text-primary border-b-2 border-primary pb-2">Kanban Board</button>
          </div>
        </header>

        <!-- Kanban Scroll Area -->
        <div class="flex-1 overflow-x-auto overflow-y-hidden p-8 bg-base-100/50">
          <div class="flex gap-6 h-full min-w-max">
            <%= for status <- @statuses do %>
              <div class="flex-shrink-0 w-80 flex flex-col bg-base-50/50 border border-base-200 rounded-lg group transition-all h-full">
                <!-- Column Header -->
                <div class="p-4 flex items-center justify-between border-b border-base-200 pb-3 mb-2">
                  <div class="flex items-center gap-3">
                    <span class="w-2 h-2 rounded-full bg-primary/40 group-focus-within:bg-primary transition-colors"></span>
                    <h2 class="text-[11px] font-black uppercase tracking-widest text-base-content/70">{status}</h2>
                    <span class="bg-base-200 text-base-content/40 text-[10px] font-black px-1.5 py-0.5 rounded-md min-w-[20px] text-center">
                      {length(Map.get(@tasks_by_status, status, []))}
                    </span>
                  </div>
                  <div class="dropdown dropdown-end">
                    <button tabindex="0" class="btn btn-ghost btn-xs btn-circle opacity-0 group-hover:opacity-100">
                      <.icon name="hero-ellipsis-horizontal" class="w-4 h-4" />
                    </button>
                    <ul tabindex="0" class="dropdown-content z-[2] menu p-1 shadow-xl bg-base-100 rounded-lg border border-base-200 text-[10px] font-black uppercase w-40">
                       <li class="menu-title opacity-40 px-3 py-2 tracking-widest">Column Actions</li>
                       <li><button phx-click="remove_column" phx-value-status={status} class="text-error hover:bg-error/5 py-3" data-confirm="Remove this status? Tasks will be moved to first available column."><.icon name="hero-trash" class="w-3.5 h-3.5" /> Remove Column</button></li>
                    </ul>
                  </div>
                </div>

                <div
                  class="flex-1 p-3 space-y-3 overflow-y-auto scrollbar-hidden bg-white/50 dark:bg-base-100/10"
                  id={"column-#{status}"}
                  phx-hook="Sortable"
                  data-status={status}
                  data-group="kanban"
                >
                  <%= for task <- Map.get(@tasks_by_status, status, []) do %>
                    <div
                      id={"task-#{task.id}"}
                      data-id={task.id}
                      phx-click={JS.navigate(~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks/#{task.id}")}
                      class="bg-white dark:bg-base-200/50 p-4 rounded-lg shadow-sm border border-base-200 hover:border-primary/40 transition-all cursor-pointer group/card relative"
                    >
                      <div class="flex items-start gap-3 mb-4">
                         <div :if={task.icon} class="w-8 h-8 rounded-lg bg-base-50 flex items-center justify-center border border-base-200 shrink-0 text-base-content/40 group-hover/card:bg-primary/5 group-hover/card:text-primary transition-colors">
                            <.icon name={"hero-#{task.icon}"} class="w-4 h-4" />
                         </div>
                         <div class="flex-1 min-w-0">
                            <span class="text-xs font-black text-base-content/80 group-hover/card:text-primary transition-colors leading-tight line-clamp-2">
                              {task.title}
                            </span>
                         </div>
                      </div>

                      <div class="flex items-center justify-between pt-4 border-t border-base-200/50 mt-auto">
                         <div class="flex items-center gap-2">
                            <span :if={task.category} class="text-[9px] font-black text-base-content/30 uppercase tracking-widest">{task.category}</span>
                            <span :if={task.time_estimate} class="flex items-center gap-1 text-[9px] font-black text-primary uppercase tracking-widest">
                               <.icon name="hero-clock" class="w-2.5 h-2.5" /> {task.time_estimate}
                            </span>
                         </div>

                         <div class="flex items-center gap-2">
                            <span :if={task.due_date} class="text-[9px] font-black text-base-content/30 uppercase tracking-tight" title="Due Date">
                               {Calendar.strftime(task.due_date, "%b %d")}
                            </span>
                            <div :if={task.assignee} class="w-6 h-6 rounded-lg bg-primary/10 text-primary border border-primary/20 flex items-center justify-center text-[10px] font-black uppercase ring-1 ring-white shadow-sm" title={task.assignee.email}>
                               {String.at(task.assignee.email, 0)}
                            </div>
                         </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>

    <!-- Modals -->
    <.modal :if={@live_action == :add_column} id="add-column-modal" show on_cancel={JS.patch(~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks")}>
       <div class="p-8">
          <div class="flex items-center gap-4 mb-6">
             <div class="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center shadow-inner">
                <.icon name="hero-columns" class="w-6 h-6" />
             </div>
             <div>
                <h3 class="text-xl font-black tracking-tight text-base-content">Add Kanban Column</h3>
                <p class="text-[10px] font-bold text-base-content/40 uppercase tracking-widest">Manage your workflow phases</p>
             </div>
          </div>

          <form phx-submit="save_column" class="space-y-6">
             <div class="form-control">
                <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/50">Status Name</span></label>
                <input type="text" name="status" class="input input-bordered w-full rounded-xl bg-base-50 focus:bg-white font-bold" placeholder="e.g. In Review" required autofocus />
             </div>

             <div class="flex justify-end gap-3 pt-4">
                <button type="button" phx-click={JS.patch(~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks")} class="btn btn-ghost rounded-xl text-[10px] font-black uppercase tracking-widest">Cancel</button>
                <button type="submit" class="btn btn-primary rounded-xl px-8 text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">Create Column</button>
             </div>
          </form>
       </div>
    </.modal>
    """
  end

  @impl true
  def handle_event("toggle_app", %{"id" => id}, socket) do
    expanded = socket.assigns.expanded_apps
    id_str = to_string(id)

    new_expanded =
      if MapSet.member?(expanded, id_str),
        do: MapSet.delete(expanded, id_str),
        else: MapSet.put(expanded, id_str)

    {:noreply, assign(socket, expanded_apps: new_expanded)}
  end

  @impl true
  def handle_event(
        "reorder",
        %{"id" => id, "to_status" => to_status, "new_index" => new_index},
        socket
      ) do
    task = Planner.get_task!(id)
    user = socket.assigns.current_scope.user

    # new_index might be string or integer
    target_index = if is_binary(new_index), do: String.to_integer(new_index), else: new_index

    case Planner.update_task_status(task, to_status, target_index + 1, user) do
      {:ok, _} ->
        {:noreply, fetch_tasks(socket)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_column", _, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/workspaces/#{socket.assigns.workspace_id}/apps/#{socket.assigns.app_id}/features/#{socket.assigns.feature.id}/tasks/add_column"
     )}
  end

  @impl true
  def handle_event("save_column", %{"status" => status}, socket) do
    workspace = socket.assigns.current_workspace
    statuses = socket.assigns.statuses ++ [status]

    config = Map.merge(workspace.status_config || %{}, %{"statuses" => statuses})

    user = socket.assigns.current_scope.user

    case Workspaces.update_workspace(user, workspace, %{status_config: config}) do
      {:ok, workspace} ->
        {:noreply,
         socket
         |> assign(:current_workspace, workspace)
         |> assign(:statuses, statuses)
         |> put_flash(:info, "Column added")
         |> push_patch(
           to:
             ~p"/workspaces/#{socket.assigns.workspace_id}/apps/#{socket.assigns.app_id}/features/#{socket.assigns.feature.id}/tasks"
         )}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_column", %{"status" => status}, socket) do
    workspace = socket.assigns.current_workspace
    statuses = List.delete(socket.assigns.statuses, status)

    # Move tasks in this status to first available status or Todo
    tasks_to_move = Map.get(socket.assigns.tasks_by_status, status, [])
    target_status = if length(statuses) > 0, do: List.first(statuses), else: "Todo"

    Enum.each(tasks_to_move, fn t ->
      Planner.update_task_status(t, target_status, 1, socket.assigns.current_scope.user)
    end)

    config = Map.merge(workspace.status_config || %{}, %{"statuses" => statuses})

    user = socket.assigns.current_scope.user

    case Workspaces.update_workspace(user, workspace, %{status_config: config}) do
      {:ok, workspace} ->
        {:noreply,
         socket
         |> assign(:current_workspace, workspace)
         |> assign(:statuses, statuses)
         |> fetch_tasks()
         |> put_flash(:info, "Column removed")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_app", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    workspace_id = socket.assigns.workspace_id
    app = Planner.get_app!(id, user, workspace_id)

    case Planner.delete_app(app) do
      {:ok, _} ->
        if to_string(app.id) == to_string(socket.assigns.app_id) do
          {:noreply,
           socket
           |> put_flash(:info, "Project deleted")
           |> push_navigate(to: ~p"/workspaces/#{workspace_id}/apps")}
        else
          # Reload sidebar
          apps_with_features =
            Planner.list_apps(user, workspace_id)
            |> Enum.map(fn a ->
              %{a | features: Planner.list_features(user, a.id, workspace_id)}
            end)

          {:noreply,
           socket
           |> put_flash(:info, "Project deleted")
           |> assign(apps_with_features: apps_with_features)}
        end

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not delete project")}
    end
  end

  @impl true
  def handle_event("delete_feature", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    workspace_id = socket.assigns.workspace_id
    feature = Planner.get_feature!(id, user, workspace_id)

    case Planner.delete_feature(feature) do
      {:ok, _} ->
        if to_string(feature.id) == to_string(socket.assigns.feature.id) do
          {:noreply,
           socket
           |> put_flash(:info, "Feature deleted")
           |> push_navigate(to: ~p"/workspaces/#{workspace_id}/apps/#{feature.app_id}")}
        else
          # Reload sidebar
          apps_with_features =
            Planner.list_apps(user, workspace_id)
            |> Enum.map(fn a ->
              %{a | features: Planner.list_features(user, a.id, workspace_id)}
            end)

          {:noreply,
           socket
           |> put_flash(:info, "Feature deleted")
           |> assign(apps_with_features: apps_with_features)}
        end

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not delete feature")}
    end
  end
end
