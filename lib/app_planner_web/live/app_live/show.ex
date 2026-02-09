defmodule AppPlannerWeb.AppLive.Show do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Workspaces
  alias AppPlanner.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-12 px-6">
      <nav class="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-base-content/30 mb-10 border-b border-base-200 pb-4">
        <.link navigate={~p"/workspaces"} class="hover:text-primary transition-colors">Workspace</.link>
        <span>/</span>
        <.link navigate={~p"/workspaces/#{@current_workspace.id}/apps"} class="hover:text-primary transition-colors">Projects</.link>
        <span>/</span>
        <span class="text-base-content/80 font-bold">{@app.name}</span>
      </nav>

      <div class="flex flex-col md:flex-row justify-between items-start gap-8 mb-16">
        <div class="flex items-start gap-6">
           <div class="w-16 h-16 rounded-xl bg-primary/10 text-primary border border-primary/20 flex items-center justify-center shrink-0 shadow-sm group">
              <.icon name={if @app.icon, do: "hero-#{@app.icon}", else: "hero-cube"} class="w-8 h-8 group-hover:scale-110 transition-transform" />
           </div>
           <div>
              <div class="flex items-center gap-3 mb-2">
                 <span class="text-[10px] font-black uppercase text-primary tracking-widest bg-primary/5 px-2 py-0.5 rounded border border-primary/10">
                   {@app.category || "General Project"}
                 </span>
                 <span class="text-[10px] font-black uppercase text-base-content/40 tracking-widest px-2 py-0.5 rounded border border-base-200">
                   {@app.status}
                 </span>
              </div>
              <h1 class="text-4xl font-black tracking-tight text-base-content leading-tight">
                {@app.name}
              </h1>
              <p :if={@app.description} class="text-base-content/50 mt-4 text-sm font-medium leading-relaxed italic border-l-2 border-base-200 pl-4 max-w-2xl">
                 {@app.description}
              </p>
           </div>
        </div>

        <div class="flex items-center gap-2 self-center md:self-auto">
          <%= if @can_edit do %>
            <button
               phx-click="delete_app"
               data-confirm="Archive this project?"
               class="btn btn-ghost btn-sm rounded-lg px-4 font-black uppercase text-[10px] tracking-widest text-error hover:bg-error/5"
            >
              <.icon name="hero-trash" class="w-3.5 h-3.5" /> Archive
            </button>
          <% end %>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-12">
         <div class="lg:col-span-2 space-y-12">
            <section>
               <div class="flex justify-between items-center border-b border-base-200 pb-4 mb-8">
                  <div class="flex items-center gap-3">
                     <div class="w-8 h-8 rounded-lg bg-base-100 border border-base-200 flex items-center justify-center">
                        <.icon name="hero-rectangle-group" class="w-4 h-4 text-base-content/40" />
                     </div>
                     <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/60">Execution Modules</h3>
                  </div>
                  <%= if @can_edit do %>
                    <.link navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{@app.id}/features/new"} class="text-[10px] font-black uppercase text-primary hover:underline underline-offset-4 tracking-widest">
                       Add Module
                    </.link>
                  <% end %>
               </div>

               <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                 <%= for feature <- @app.features do %>
                   <div
                     phx-click={JS.navigate(~p"/workspaces/#{@current_workspace.id}/apps/#{@app.id}/features/#{feature.id}/tasks")}
                     class="group bg-base-100 border border-base-200 rounded-lg p-6 cursor-pointer hover:border-primary hover:shadow-xl hover:shadow-primary/5 transition-all relative overflow-hidden"
                   >
                     <div class="flex items-center gap-4 mb-4 relative z-10">
                       <div class="w-10 h-10 rounded-lg bg-base-50 flex items-center justify-center border border-base-200 text-base-content/20 group-hover:bg-primary group-hover:text-white group-hover:border-primary transition-all">
                          <.icon name={if feature.icon, do: "hero-#{feature.icon}", else: "hero-bolt"} class="w-5 h-5" />
                       </div>
                       <div class="flex-1 min-w-0">
                          <h4 class="font-black text-base-content group-hover:text-primary transition-colors truncate tracking-tight">{feature.title}</h4>
                          <span class="text-[9px] font-black uppercase text-base-content/30 tracking-widest">{feature.status}</span>
                       </div>
                     </div>

                     <p class="text-xs text-base-content/40 line-clamp-2 h-8 mb-6 font-medium leading-relaxed italic z-10 relative">{feature.description || "Module documentation draft."}</p>

                     <div class="flex items-center justify-between pt-4 border-t border-base-50 mt-auto z-10 relative">
                        <span class="text-[9px] font-black uppercase text-base-content/20 tracking-widest italic group-hover:text-primary transition-colors">Project Scope</span>
                        <div class="text-primary opacity-0 group-hover:opacity-100 translate-x-4 group-hover:translate-x-0 transition-all duration-300">
                           <.icon name="hero-arrow-right" class="w-4 h-4" />
                        </div>
                     </div>
                   </div>
                 <% end %>
               </div>

               <%= if Enum.empty?(@app.features) do %>
                 <div class="py-24 text-center border-2 border-dashed border-base-200 rounded-xl bg-base-50/50">
                    <div class="w-16 h-16 bg-white rounded-full flex items-center justify-center mx-auto mb-6 border border-base-200">
                       <.icon name="hero-sparkles" class="w-8 h-8 text-base-content/10" />
                    </div>
                    <h3 class="text-xl font-black tracking-tight mb-2">No modules yet</h3>
                    <p class="text-sm text-base-content/40 font-medium max-w-xs mx-auto mb-8 italic">Define the core modules of your project to start planning the execution roadmap.</p>
                    <%= if @can_edit do %>
                       <.link navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{@app.id}/features/new"} class="btn btn-primary btn-sm rounded-lg px-8 font-black uppercase text-[10px] tracking-widest shadow-lg shadow-primary/20">
                          Add Module
                       </.link>
                    <% end %>
                 </div>
               <% end %>
            </section>
         </div>

          <aside class="space-y-8">
            <div class="bg-base-50/50 border border-base-200 rounded-xl p-8 space-y-8">
              <div class="space-y-6">
                <div>
                  <span class="text-[9px] font-black text-base-content/20 uppercase tracking-widest block mb-4">Lead Architect</span>
                  <div class="flex items-center gap-3 px-4 py-3 bg-white rounded-lg border border-base-200 shadow-sm">
                    <div class="w-8 h-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center text-[11px] font-black uppercase">
                      {if @app.last_updated_by, do: String.at(@app.last_updated_by.email, 0) |> String.upcase(), else: "U"}
                    </div>
                    <div class="flex flex-col min-w-0">
                      <span class="text-xs font-black text-base-content truncate">{if @app.last_updated_by, do: @app.last_updated_by.email, else: "Unknown"}</span>
                      <span class="text-[9px] font-bold text-base-content/30 uppercase tracking-widest">Editor</span>
                    </div>
                  </div>
                </div>

                <div class="bg-white rounded-lg p-6 border border-base-200 shadow-sm space-y-4">
                  <h4 class="text-[10px] font-black uppercase tracking-widest text-base-content/20">Spec Info</h4>
                  <div class="space-y-1">
                    <div class="flex items-center justify-between p-2 rounded bg-base-50 border border-base-100 text-[9px] font-bold">
                      <span class="text-base-content/40 uppercase">Created</span>
                      <span class="text-base-content/70">{Calendar.strftime(@app.inserted_at, "%b %Y")}</span>
                    </div>
                    <div class="flex items-center justify-between p-2 rounded bg-base-50 border border-base-100 text-[9px] font-bold">
                      <span class="text-base-content/40 uppercase">Updated</span>
                      <span class="text-base-content/70">{Calendar.strftime(@app.updated_at, "%b %d")}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="px-8 flex items-center justify-between">
              <span class="text-[9px] font-black text-base-content/20 uppercase tracking-widest">Members</span>
              <div class="flex -space-x-1.5">
                <div class="w-6 h-6 rounded bg-primary ring-2 ring-white flex items-center justify-center text-[8px] font-black text-white uppercase shadow-sm">
                  {if @app.last_updated_by, do: String.at(@app.last_updated_by.email, 0) |> String.upcase(), else: "A"}
                </div>
                <div class="w-6 h-6 rounded bg-base-200 ring-2 ring-white flex items-center justify-center text-[8px] font-black text-base-content/40 shadow-sm">+9</div>
              </div>
            </div>
          </aside>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(AppPlanner.PubSub, "app_updates")
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace

    if is_nil(current_workspace) do
      {:ok,
       socket
       |> put_flash(:error, "A workspace must be selected.")
       |> push_navigate(to: ~p"/workspaces")}
    else
      case Planner.get_app(user, id, current_workspace.id) do
        nil ->
          {:ok,
           socket
           |> put_flash(:error, "App not found.")
           |> push_navigate(to: ~p"/workspaces/#{current_workspace.id}/apps")}

        app ->
          can_edit = Workspaces.can_edit?(user, current_workspace) || Accounts.super_admin?(user)

          {:ok,
           socket
           |> assign(:page_title, app.name)
           |> assign(:app, app)
           |> assign(:current_user, user)
           |> assign(:can_edit, can_edit)
           |> assign(:current_workspace, current_workspace)}
      end
    end
  end

  @impl true
  def handle_event("delete_app", _, socket) do
    case Planner.delete_app(socket.assigns.app) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project deleted")
         |> push_navigate(to: ~p"/workspaces/#{socket.assigns.current_workspace.id}/apps")}

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not terminate project")}
    end
  end

  @impl true
  def handle_info({:app_updated, id}, socket) do
    app = socket.assigns.app
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace

    if app.id == id do
      case Planner.get_app(user, id, current_workspace.id) do
        nil ->
          {:noreply, socket |> push_navigate(to: ~p"/workspaces/#{current_workspace.id}/apps")}

        updated_app ->
          {:noreply, assign(socket, app: updated_app)}
      end
    else
      {:noreply, socket}
    end
  end
end
