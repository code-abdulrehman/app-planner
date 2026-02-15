defmodule AppPlannerWeb.FeatureLive.Index do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-12 px-6">
      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-8 mb-12">
        <div>
          <h1 class="text-4xl font-black tracking-tight text-base-content mb-2">
            {if @app, do: @app.name, else: "All Modules"}
          </h1>
          <div class="flex items-center gap-3">
            <span class="w-2 h-2 rounded-full bg-primary"></span>
            <p class="text-base-content/40 text-[10px] font-black uppercase tracking-widest font-medium italic">
              {if @app, do: "Project scope", else: "Global roadmap"}
            </p>
          </div>
        </div>

        <.link
          :if={@app}
          navigate={
            ~p"/workspaces/#{@current_workspace.id}/apps/#{@app.id}/features/new?return_to=app"
          }
          class="btn btn-primary rounded-lg px-8 font-black text-[10px] uppercase tracking-widest shadow-lg shadow-primary/20"
        >
          <div class="flex items-center gap-2">
            <.icon name="hero-plus" class="w-4 h-4" /> Add Module
          </div>
        </.link>
      </div>

      <div
        class="bg-base-50/50 border border-base-200 rounded-lg overflow-hidden"
        id="features"
        phx-update="stream"
      >
        <div
          :for={{id, feature} <- @streams.features}
          id={id}
          class="group border-b border-base-200 hover:bg-base-100 transition-all px-8 py-6 flex items-center justify-between gap-6"
        >
          <div
            class="flex items-center gap-6 cursor-pointer flex-1"
            phx-click={
              JS.navigate(
                ~p"/workspaces/#{@current_workspace.id}/apps/#{feature.app_id}/features/#{feature.id}/tasks"
              )
            }
          >
            <div class="w-12 h-12 rounded-lg bg-base-100 border border-base-200 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white transition-all shadow-sm">
              <.icon
                name={if feature.icon, do: "hero-#{feature.icon}", else: "hero-bolt"}
                class="w-6 h-6"
              />
            </div>
            <div>
              <h3 class="text-lg font-black tracking-tight mb-1 group-hover:text-primary transition-colors">
                {feature.title}
              </h3>
              <div class="flex gap-3 items-center text-[10px] text-base-content/30 font-black uppercase tracking-widest flex-wrap">
                <span :if={feature.app} class="text-primary">{feature.app.name}</span>
                <span :if={feature.app}>•</span>
                <span>{feature.time_estimate || "No Estimate"}</span>
              </div>
            </div>
          </div>

          <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
            <.link
              navigate={
                ~p"/workspaces/#{@current_workspace.id}/apps/#{feature.app_id}/features/#{feature.id}/edit"
              }
              class="btn btn-ghost btn-xs rounded-md border border-base-200 hover:text-primary"
            >
              <.icon name="hero-pencil" class="w-3.5 h-3.5" />
            </.link>
            <button
              phx-click={JS.push("delete", value: %{id: feature.id}) |> hide("##{id}")}
              data-confirm="Delete this module?"
              class="btn btn-ghost btn-xs rounded-md border border-base-200 text-error hover:bg-error/5"
            >
              <.icon name="hero-trash" class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"workspace_id" => _workspace_id} = params, _session, socket) do
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace

    app =
      case params["app_id"] do
        nil ->
          nil

        id ->
          app_id = if is_binary(id), do: String.to_integer(id), else: id
          # Corrected call
          Planner.get_app(user, app_id, current_workspace.id)
      end

    if params["app_id"] != nil and app == nil do
      {:ok,
       socket
       |> put_flash(:error, "This project is no longer available.")
       # Corrected routing
       |> push_navigate(to: ~p"/workspaces/#{current_workspace.id}/apps")}
    else
      features =
        if app do
          Enum.map(app.features, &%{&1 | app: app})
        else
          # Corrected call
          Planner.list_features(user, nil, current_workspace.id)
        end

      {:ok,
       socket
       |> assign(:page_title, if(app, do: "Features for #{app.name}", else: "Listing Features"))
       |> assign(:app, app)
       # Assign current_workspace
       |> assign(:current_workspace, current_workspace)
       |> stream(:features, features)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace
    feature = Planner.get_feature!(id, user, current_workspace.id)
    {:ok, _} = Planner.delete_feature(feature)

    {:noreply, stream_delete(socket, :features, feature)}
  end
end
