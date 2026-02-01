defmodule AppPlannerWeb.FeatureLive.Show do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.breadcrumb items={breadcrumb_items_feature_show(@feature)} />

      <div class="flex justify-between items-start border-b pb-8 mb-10">
        <div class="flex items-start gap-3">
          <div class="text-primary">
            <.icon name={if @feature.icon, do: "hero-#{@feature.icon}", else: "hero-bolt"} class="w-8 h-8" />
          </div>
          <div>
            <h1 class="text-2xl font-bold">{@feature.title}</h1>
          <div class="flex items-center gap-2 mt-1">
            <p class="text-xs text-gray-400 font-bold uppercase tracking-widest">Feature Roadmap</p>
            <span :if={@feature.status} class="text-[9px] font-black uppercase px-2 py-0.5 rounded bg-base-200 text-base-content/80">{@feature.status}</span>
          </div>
          </div>
        </div>
        <div class="flex gap-2">
          <.link navigate={~p"/features/#{@feature}/edit?return_to=show"} class="btn btn-sm btn-ghost">Edit</.link>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-16">
         <div class="space-y-10">
            <div class="flex flex-col">
              <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Rationale</label>
              <p class="text-sm leading-relaxed">{@feature.why_need || "—"}</p>
            </div>

            <div class="flex flex-col">
              <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Description</label>
              <p class="text-sm leading-relaxed">{@feature.description || "—"}</p>
            </div>

            <div class="grid grid-cols-2 gap-8 pt-8 border-t">
               <div :if={@feature.time_estimate} class="flex flex-col">
                 <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Time Effort</label>
                 <span class="text-sm font-bold">{@feature.time_estimate}</span>
               </div>
               <div :if={@feature.implementation_date} class="flex flex-col">
                 <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Target Date</label>
                 <span class="text-sm font-bold">{@feature.implementation_date}</span>
               </div>
            </div>
            <%= if @feature.pr_link && @feature.pr_link != "" do %>
              <div class="flex flex-col pt-6">
                <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Git / PR link</label>
                <a href={@feature.pr_link} target="_blank" rel="noopener noreferrer" class="text-sm font-bold text-primary hover:underline flex items-center gap-2 uppercase tracking-tighter">
                  <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.042-1.416-4.042-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                  Source / PR
                </a>
              </div>
            <% end %>
         </div>

         <div class="space-y-10">
            <div class="flex flex-col">
              <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-2">Implementation Path</label>
              <div class="space-y-6">
                 <div class="border-l-2 border-base-200 pl-4 py-1">
                    <span class="text-[9px] font-black uppercase text-gray-400 block mb-1">User Flow</span>
                    <p class="text-xs">{@feature.how_to_add || "--"}</p>
                 </div>
                 <div class="border-l-2 border-base-200 pl-4 py-1">
                    <span class="text-[9px] font-black uppercase text-gray-400 block mb-1">Technical Strategy</span>
                    <p class="text-xs">{@feature.how_to_implement || "--"}</p>
                 </div>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-8 pt-8 border-t">
               <div class="flex flex-col">
                 <label class="text-[10px] font-black uppercase text-success/60 tracking-widest mb-2">Pros</label>
                 <p class="text-xs leading-relaxed">{@feature.pros || "--"}</p>
               </div>
               <div class="flex flex-col">
                 <label class="text-[10px] font-black uppercase text-error/60 tracking-widest mb-2">Cons</label>
                 <p class="text-xs leading-relaxed">{@feature.cons || "--"}</p>
               </div>
            </div>

            <%= if @feature.custom_fields && map_size(@feature.custom_fields) > 0 do %>
              <div class="flex flex-col gap-4 pt-8 border-t">
                <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest">Technical Metadata</label>
                <div class="space-y-3">
                  <%= for {key, value} <- @feature.custom_fields do %>
                    <div class="flex flex-col border-l-2 border-base-200 pl-3 py-0.5">
                      <span class="text-[9px] font-black uppercase text-gray-400 leading-none mb-1">{key}</span>
                       <%= if String.contains?(value, "http") do %>
                           <a href={value} target="_blank" class="text-primary hover:underline text-xs font-mono font-bold tracking-tight line-clamp-1">{value}</a>
                         <% else %>
                         <span class="text-xs font-mono font-bold tracking-tight line-clamp-1">
                           {value}
                         </span>
                         <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
         </div>
      </div>
    </Layouts.app>
    """
  end

  def breadcrumb_items_feature_show(feature) do
    app_name = if feature.app, do: feature.app.name, else: "Project"
    [
      %{label: "Projects", path: ~p"/apps"},
      %{label: app_name, path: ~p"/apps/#{feature.app_id}"},
      %{label: feature.title, path: nil}
    ]
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    feature = Planner.get_feature!(id, user)

    {:ok,
     socket
     |> assign(:page_title, feature.title)
     |> assign(:feature, feature)}
  end
end
