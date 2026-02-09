defmodule AppPlannerWeb.WorkspaceLive.Index do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Workspaces
  alias AppPlanner.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :workspaces, list_workspaces(socket.assigns.current_scope.user))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :workspaces, list_workspaces(socket.assigns.current_scope.user))}
  end

  defp list_workspaces(%User{} = user) do
    Workspaces.list_user_workspaces(user)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-12 px-6">
      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-8 mb-12">
        <div>
          <h1 class="text-4xl font-black tracking-tight text-base-content mb-2">Workspaces</h1>
          <div class="flex items-center gap-3">
             <span class="w-2 h-2 rounded-full bg-primary"></span>
             <p class="text-base-content/40 text-[10px] font-black uppercase tracking-widest font-medium italic">Shared environments for projects</p>
          </div>
        </div>

        <.link navigate={~p"/workspaces/new"} class="btn btn-primary rounded-lg px-8 font-black text-[10px] uppercase tracking-widest shadow-lg shadow-primary/20">
          <div class="flex items-center gap-2">
             <.icon name="hero-plus" class="w-4 h-4" /> New Workspace
          </div>
        </.link>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <%= for workspace <- @workspaces do %>
          <div
            phx-click={JS.navigate(~p"/workspaces/#{workspace.id}")}
            class="group bg-base-50/50 border border-base-200 rounded-lg p-8 cursor-pointer hover:border-primary transition-all duration-500 hover:shadow-md relative overflow-hidden"
          >
             <div class="absolute -right-8 -top-8 w-32 h-32 bg-primary/5 rounded-full blur-3xl group-hover:bg-primary/10 transition-colors"></div>

             <div class="flex items-center justify-between relative">
                <div class="flex items-center gap-5">
                   <div class="w-14 h-14 rounded-lg bg-base-100 border border-base-200 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white transition-all shadow-sm">
                      <.icon name="hero-rectangle-stack" class="w-7 h-7" />
                   </div>
                   <div>
                      <h3 class="text-xl font-black text-base-content group-hover:text-primary transition-colors tracking-tight line-clamp-1">
                        {workspace.name}
                      </h3>
                      <p class="text-[10px] font-bold text-base-content/30 uppercase tracking-widest mt-1">
                        Owner: {if workspace.owner, do: workspace.owner.email, else: "Unknown"}
                      </p>
                   </div>
                </div>

                <div class="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                   <.link navigate={~p"/workspaces/#{workspace.id}/edit"} class="btn btn-ghost btn-xs btn-circle bg-base-100 border border-base-200 hover:text-primary" phx-click-stop>
                      <.icon name="hero-pencil" class="w-3.5 h-3.5" />
                   </.link>
                </div>
             </div>

             <div class="mt-8 flex items-center justify-between pt-6 border-t border-base-200/50">
                <div class="flex items-center gap-2">
                   <div class="flex -space-x-1">
                      <div class="w-5 h-5 rounded-md bg-base-200 border border-base-100 flex items-center justify-center text-[8px] font-black uppercase">
                        {if workspace.owner, do: String.at(workspace.owner.email, 0) |> String.upcase(), else: "W"}
                      </div>
                   </div>
                   <span class="text-[9px] font-black uppercase text-base-content/20 tracking-widest italic ml-1">Workspace Active</span>
                </div>
                <.link navigate={~p"/workspaces/#{workspace.id}"} class="text-[10px] font-black uppercase text-primary tracking-widest opacity-0 group-hover:opacity-100 translate-x-4 group-hover:translate-x-0 transition-all duration-300">
                   Open <.icon name="hero-arrow-right" class="w-3 h-3 ml-1" />
                </.link>
             </div>
          </div>
        <% end %>
      </div>

      <%= if Enum.empty?(@workspaces) do %>
        <div class="py-24 text-center border-4 border-dashed border-base-200 rounded-[3rem] bg-base-50/50">
           <div class="w-16 h-16 bg-white rounded-2xl shadow-xl flex items-center justify-center mx-auto mb-6 border border-base-200">
             <.icon name="hero-sparkles" class="w-7 h-7 text-primary/40" />
           </div>
           <p class="text-base-content/40 font-bold uppercase tracking-widest text-[11px]">No workspaces found</p>
           <.link navigate={~p"/workspaces/new"} class="mt-6 inline-block btn btn-primary btn-sm rounded-lg px-8 font-black uppercase text-[10px] tracking-widest shadow-lg shadow-primary/20">
             Create First Workspace
           </.link>
        </div>
      <% end %>
    </div>
    """
  end
end
