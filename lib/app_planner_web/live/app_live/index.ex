defmodule AppPlannerWeb.AppLive.Index do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-6 py-10 max-w-7xl mx-auto space-y-12">
      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-8">
        <div>
          <h1 class="text-5xl font-black tracking-tighter text-base-content mb-2">
            {if @current_workspace, do: @current_workspace.name, else: "Project Library"}
          </h1>
          <div class="flex items-center gap-3">
            <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
            <p class="text-base-content/50 text-xs font-black uppercase tracking-widest">
              Manage your projects
            </p>
          </div>
        </div>

        <.link
          navigate={~p"/workspaces/#{@current_workspace.id}/apps/new"}
          class="btn btn-primary rounded-lg px-8 font-black text-[10px] uppercase tracking-widest shadow-sm shadow-primary/20 hover:scale-105 transition-all"
        >
          <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New Project
        </.link>
      </div>
      
    <!-- Search & Filters -->
      <div class="relative group">
        <div class="absolute inset-y-0 left-0 pl-5 flex items-center pointer-events-none transition-all group-focus-within:pl-6">
          <.icon
            name="hero-magnifying-glass"
            class="w-5 h-5 text-base-content/20 group-focus-within:text-primary"
          />
        </div>
        <input
          type="text"
          phx-keyup="search"
          phx-debounce="300"
          placeholder="Search by name or status..."
          class="input input-bordered w-full pl-14 h-14 rounded-lg bg-base-100 border-base-200 focus:border-primary/50 focus:ring-8 focus:ring-primary/5 transition-all text-sm font-bold shadow-sm"
        />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        <%= for app <- @filtered_apps do %>
          <div
            class="group relative bg-base-100 border border-base-200 rounded-xl p-8 cursor-pointer hover:border-primary transition-all duration-500 hover:shadow-md overflow-hidden"
            phx-click={JS.navigate(~p"/workspaces/#{@current_workspace.id}/apps/#{app.id}")}
          >
            <!-- Background Decoration -->
            <div class="absolute -right-8 -top-8 w-32 h-32 bg-primary/5 rounded-full blur-3xl group-hover:bg-primary/10 transition-colors">
            </div>

            <div class="flex items-start justify-between mb-8 relative">
              <div class="p-4 bg-primary/5 rounded-xl text-primary group-hover:bg-primary group-hover:text-white transition-all duration-500 shadow-inner">
                <.icon name={if app.icon, do: "hero-#{app.icon}", else: "hero-cube"} class="w-8 h-8" />
              </div>

              <div class="dropdown dropdown-end" phx-click-stop>
                <label
                  tabindex="0"
                  class="btn btn-ghost btn-sm btn-circle bg-base-200/50 hover:bg-primary hover:text-white transition-all"
                >
                  <.icon name="hero-ellipsis-vertical" class="w-5 h-5" />
                </label>
                <ul
                  tabindex="0"
                  class="dropdown-content z-[2] menu p-2 shadow-xl bg-base-100 rounded-lg w-48 border border-base-200 text-[10px] font-black tracking-widest overflow-hidden"
                >
                  <li class="menu-title opacity-40 px-4 py-3 border-b border-base-200 mb-1">
                    Actions
                  </li>
                  <li>
                    <.link
                      navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{app.id}"}
                      class="py-3 hover:bg-primary/5"
                    >
                      <.icon name="hero-eye" class="w-4 h-4 text-primary" /> Open
                    </.link>
                  </li>
                  <li>
                    <.link
                      navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{app.id}"}
                      class="py-3 hover:bg-primary/5"
                    >
                      <.icon name="hero-pencil" class="w-4 h-4 text-primary" /> View
                    </.link>
                  </li>
                  <li>
                    <button
                      phx-click="delete"
                      phx-value-id={app.id}
                      data-confirm="Are you sure?"
                      class="py-3 text-error hover:bg-error/5"
                    >
                      <.icon name="hero-trash" class="w-4 h-4" /> Delete
                    </button>
                  </li>
                </ul>
              </div>
            </div>

            <div class="space-y-3 mb-8 relative">
              <h3 class="text-2xl font-black tracking-tight text-base-content group-hover:text-primary transition-colors line-clamp-1">
                {app.name}
              </h3>
              <p class="text-sm text-base-content/40 line-clamp-2 h-10 leading-relaxed font-bold tracking-tight italic">
                {app.description || "Experimental project roadmap without abstract description."}
              </p>
            </div>

            <div class="flex items-center gap-3 pt-6 border-t border-base-200 relative">
              <div class="flex flex-col">
                <span class="text-[9px] font-black text-base-content/20 uppercase tracking-widest mb-1">
                  Status
                </span>
                <span class="text-[10px] font-black uppercase px-2 py-0.5 border border-base-200 text-base-content/40 rounded-lg tracking-widest">
                  {app.status}
                </span>
              </div>
            </div>
            
    <!-- Footer Meta -->
            <div class="mt-8 flex items-center justify-between relative bg-base-50/50 -mx-8 -mb-8 p-6 border-t border-base-200">
              <div class="flex items-center gap-3">
                <div
                  :if={app.user}
                  class="w-8 h-8 rounded-lg bg-base-100 border border-base-200 flex items-center justify-center text-[10px] font-black text-base-content shadow-sm"
                  title={app.user.email}
                >
                  {String.at(app.user.email, 0) |> String.upcase()}
                </div>
                <div class="flex flex-col">
                  <span class="text-[9px] font-black text-base-content opacity-40 uppercase">
                    Owner
                  </span>
                  <span class="text-[10px] font-bold text-base-content truncate w-24 lowercase italic opacity-60">
                    @{app.user && String.split(app.user.email, "@") |> List.first()}
                  </span>
                </div>
              </div>

              <div class="flex items-center gap-1 text-[10px] font-black text-primary uppercase tracking-widest group-hover:translate-x-1 transition-transform">
                Enter <.icon name="hero-chevron-right" class="w-3.5 h-3.5" />
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if Enum.empty?(@filtered_apps) do %>
        <div class="py-32 text-center border-2 border-dashed border-base-200 rounded-2xl bg-base-50/50">
          <div class="w-20 h-20 bg-white rounded-xl shadow-lg flex items-center justify-center mx-auto mb-8 border border-base-200 group hover:rotate-12 transition-transform duration-500">
            <.icon name="hero-command-line" class="w-10 h-10 text-primary" />
          </div>
          <h3 class="text-3xl font-black text-base-content tracking-tighter">No Projects Yet</h3>
          <p class="text-base-content/30 font-bold max-w-sm mx-auto mt-4 text-[10px] uppercase tracking-widest">
            Create your first project or load a sample.
          </p>
          <div class="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
            <.link
              navigate={~p"/workspaces/#{@current_workspace.id}/apps/new"}
              class="btn btn-primary btn-md rounded-lg px-8 font-black text-[10px] uppercase tracking-widest shadow-lg shadow-primary/20"
            >
              New Project
            </.link>
            <button
              phx-click="add_example"
              class="btn btn-outline btn-md rounded-lg px-8 font-black text-[10px] uppercase tracking-widest border-base-300"
            >
              Load Example
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    workspace = socket.assigns.current_workspace

    if is_nil(workspace) do
      {:ok,
       socket
       |> put_flash(:error, "Select a workspace first.")
       |> push_navigate(to: ~p"/workspaces")}
    else
      apps = Planner.list_apps(user, workspace.id)

      {:ok,
       socket
       |> assign(:apps, apps)
       |> assign(:filtered_apps, apps)
       |> assign(:search_query, "")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    if params["new_app"] == "true" do
      {:noreply,
       socket
       |> push_navigate(to: ~p"/workspaces/#{socket.assigns.current_workspace.id}/apps/new")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search", %{"value" => search}, socket) do
    query = String.downcase(String.trim(search))
    filtered = filter_apps(socket.assigns.apps, query)
    {:noreply, assign(socket, search_query: search, filtered_apps: filtered)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    workspace = socket.assigns.current_workspace
    app = Planner.get_app!(id, user, workspace.id)

    case Planner.delete_app(app) do
      {:ok, _} ->
        apps = Planner.list_apps(user, workspace.id)

        {:noreply,
         socket
         |> put_flash(:info, "Project deleted")
         |> assign(apps: apps, filtered_apps: filter_apps(apps, socket.assigns.search_query))}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Could not delete project")}
    end
  end

  @impl true
  def handle_event("add_example", _, socket) do
    user = socket.assigns.current_scope.user
    workspace = socket.assigns.current_workspace

    case Planner.create_example_app(user, workspace.id) do
      {:ok, app} ->
        # Find the first feature to navigate to Kanban
        feature = List.first(Planner.list_features(app.id))

        {:noreply,
         socket
         |> put_flash(:info, "Example project deployed successfully")
         |> push_navigate(
           to: ~p"/workspaces/#{workspace.id}/apps/#{app.id}/features/#{feature.id}/tasks"
         )}

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not deploy example")}
    end
  end

  defp filter_apps(apps, ""), do: apps

  defp filter_apps(apps, query) do
    Enum.filter(apps, fn app ->
      String.contains?(String.downcase(app.name || ""), query) or
        String.contains?(String.downcase(app.status || ""), query)
    end)
  end
end
