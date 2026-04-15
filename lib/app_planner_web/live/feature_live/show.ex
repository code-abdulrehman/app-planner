defmodule AppPlannerWeb.FeatureLive.Show do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto py-12 px-6">
      <nav class="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-base-content/30 mb-10 border-b border-base-200 pb-4">
        <.link navigate={~p"/workspaces"} class="hover:text-primary transition-colors">
          Workspace
        </.link>
        <span>/</span>
        <.link
          navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{@feature.app_id}"}
          class="hover:text-primary transition-colors"
        >
          Project
        </.link>
        <span>/</span>
        <span class="text-base-content/80 font-bold truncate">{@feature.title}</span>
      </nav>

      <div class="flex flex-col lg:flex-row justify-between items-start gap-12 mb-16">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-5">
            <div class="w-16 h-16 rounded-xl bg-primary/10 text-primary border border-primary/20 flex items-center justify-center shadow-sm group">
              <.icon
                name={if @feature.icon, do: "hero-#{@feature.icon}", else: "hero-bolt"}
                class="w-8 h-8 group-hover:scale-110 transition-transform"
              />
            </div>
            <div>
              <div class="flex items-center gap-3 mb-2">
                <span class="text-[9px] font-black uppercase text-primary tracking-widest bg-primary/5 px-2 py-0.5 rounded border border-primary/10">
                  Module
                </span>
              </div>
              <h1 class="text-3xl font-black tracking-tight text-base-content leading-tight">
                {@feature.title}
              </h1>
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <.link
            navigate={
              ~p"/workspaces/#{@current_workspace.id}/apps/#{@feature.app_id}/features/#{@feature.id}/tasks"
            }
            class="btn btn-primary btn-sm rounded-lg px-6 text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20"
          >
            <.icon name="hero-view-columns" class="w-3.5 h-3.5 mr-2" /> Tasks
          </.link>
          <.link
            navigate={
              ~p"/workspaces/#{@current_workspace.id}/apps/#{@feature.app_id}/features/#{@feature.id}/edit?return_to=show"
            }
            class="btn btn-outline btn-sm rounded-lg px-6 text-[10px] font-black uppercase tracking-widest border-base-200 hover:bg-base-100 transition-all"
          >
            <.icon name="hero-pencil" class="w-3.5 h-3.5 mr-2" /> Edit
          </.link>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-4 gap-12">
        <div class="lg:col-span-3 space-y-12">
          <section :if={@feature.why_need}>
            <div class="flex items-center gap-3 mb-6">
              <div class="w-7 h-7 rounded bg-base-100 border border-base-200 flex items-center justify-center">
                <.icon name="hero-light-bulb" class="w-3.5 h-3.5 text-base-content/40" />
              </div>
              <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Why this module?
              </h3>
            </div>
            <div class="bg-base-50/50 p-8 rounded-xl border border-base-200">
              <div class="prose prose-sm max-w-none text-base-content/70 leading-relaxed font-medium italic">
                <.markdown content={@feature.why_need} compact />
              </div>
            </div>
          </section>

          <section :if={@feature.description}>
            <div class="flex items-center gap-3 mb-6">
              <div class="w-7 h-7 rounded bg-base-100 border border-base-200 flex items-center justify-center">
                <.icon name="hero-document-text" class="w-3.5 h-3.5 text-base-content/40" />
              </div>
              <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Description
              </h3>
            </div>
            <div class="prose prose-sm max-w-none text-base-content/70 leading-relaxed font-medium">
              <.markdown content={@feature.description} />
            </div>
          </section>

          <section class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="space-y-6">
              <div class="flex items-center gap-3">
                <div class="w-7 h-7 rounded bg-base-100 border border-base-200 flex items-center justify-center">
                  <.icon name="hero-arrow-path" class="w-3.5 h-3.5 text-base-content/40" />
                </div>
                <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Execution
                </h3>
              </div>
              <div class="space-y-4">
                <div :if={@feature.how_to_add} class="border-l-2 border-base-200 pl-4 py-1">
                  <span class="text-[9px] font-black uppercase text-base-content/20 tracking-widest block mb-1">
                    User Flow
                  </span>
                  <div class="prose prose-xs text-base-content/60 italic leading-relaxed">
                    <.markdown content={@feature.how_to_add} compact />
                  </div>
                </div>
                <div :if={@feature.how_to_implement} class="border-l-2 border-base-200 pl-4 py-1">
                  <span class="text-[9px] font-black uppercase text-base-content/20 tracking-widest block mb-1">
                    Technical Strategy
                  </span>
                  <div class="prose prose-xs text-base-content/60 italic leading-relaxed">
                    <.markdown content={@feature.how_to_implement} compact />
                  </div>
                </div>
              </div>
            </div>

            <div class="space-y-6">
              <div class="flex items-center gap-3">
                <div class="w-7 h-7 rounded bg-base-100 border border-base-200 flex items-center justify-center">
                  <.icon name="hero-shield-check" class="w-3.5 h-3.5 text-base-content/40" />
                </div>
                <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Benefits & Risks
                </h3>
              </div>
              <div class="grid grid-cols-1 gap-4">
                <div class="bg-success/5 p-4 rounded-lg border border-success/10">
                  <h4 class="text-[9px] font-black uppercase tracking-widest text-success mb-2">
                    Benefits
                  </h4>
                  <div class="prose prose-xs text-base-content/60 font-medium italic">
                    <.markdown content={@feature.pros || "*N/A*"} compact />
                  </div>
                </div>
                <div class="bg-error/5 p-4 rounded-lg border border-error/10">
                  <h4 class="text-[9px] font-black uppercase tracking-widest text-error mb-2">
                    Risks
                  </h4>
                  <div class="prose prose-xs text-base-content/60 font-medium italic">
                    <.markdown content={@feature.cons || "*N/A*"} compact />
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>

        <aside class="space-y-8">
          <div class="bg-base-50/50 border border-base-200 rounded-xl p-6 space-y-8">
            <div>
              <span class="text-[9px] font-black text-base-content/20 uppercase tracking-widest block mb-4">
                Links
              </span>
              <div class="flex flex-col gap-2">
                <a
                  :if={@feature.pr_link}
                  href={@feature.pr_link}
                  target="_blank"
                  class="flex items-center justify-between p-3 bg-white hover:bg-base-200 rounded-lg border border-base-200 group/link transition-all"
                >
                  <div class="flex items-center gap-2">
                    <.icon
                      name="hero-code-bracket"
                      class="w-3.5 h-3.5 text-base-content/30 group-hover/link:text-primary transition-colors"
                    />
                    <span class="text-[9px] font-black uppercase text-base-content/60 tracking-wider">
                      Source Code
                    </span>
                  </div>
                  <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3 text-base-content/10" />
                </a>
                <div
                  :if={!@feature.pr_link}
                  class="p-3 rounded-lg border border-dashed border-base-200 text-center italic text-[9px] font-bold text-base-content/20"
                >
                  Unlinked
                </div>
              </div>
            </div>

            <div class="bg-white rounded-lg p-5 border border-base-200 shadow-sm space-y-4">
              <h4 class="text-[9px] font-black uppercase tracking-widest text-base-content/20">
                Spec Info
              </h4>
              <div class="space-y-2">
                <div
                  :if={@feature.time_estimate}
                  class="flex items-center justify-between p-2 rounded bg-base-50 border border-base-100 text-[9px] font-bold"
                >
                  <span class="text-base-content/40 uppercase">Effort</span>
                  <span class="text-base-content/70">{@feature.time_estimate}</span>
                </div>
                <div
                  :if={@feature.implementation_date}
                  class="flex items-center justify-between p-2 rounded bg-base-50 border border-base-100 text-[9px] font-bold"
                >
                  <span class="text-base-content/40 uppercase">Target</span>
                  <span class="text-base-content/70">{@feature.implementation_date}</span>
                </div>
              </div>
            </div>

            <div
              :if={@feature.custom_fields && map_size(@feature.custom_fields) > 0}
              class="space-y-4"
            >
              <span class="text-[9px] font-black text-base-content/20 uppercase tracking-widest block">
                Custom Attributes
              </span>
              <div class="space-y-2">
                <%= for {key, value} <- @feature.custom_fields do %>
                  <div class="flex flex-col border-l-2 border-base-200 pl-3 py-0.5">
                    <span class="text-[8px] font-black uppercase text-base-content/30 leading-none mb-1">
                      {key}
                    </span>
                    <span class="text-[10px] font-bold text-base-content/70 truncate">{value}</span>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </aside>
      </div>
    </div>
    """
  end

  def breadcrumb_items_feature_show(feature, current_workspace) do
    app_name = if feature.app, do: feature.app.name, else: "Project"

    [
      %{label: "Workspace", path: ~p"/workspaces/#{current_workspace.id}"},
      %{label: app_name, path: ~p"/workspaces/#{current_workspace.id}/apps/#{feature.app_id}"},
      %{label: feature.title, path: nil}
    ]
  end

  @impl true
  def mount(%{"id" => id, "workspace_id" => workspace_id} = _params, _session, socket) do
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace
    feature = Planner.get_feature!(id, user, workspace_id)

    {:ok,
     socket
     |> assign(:page_title, feature.title)
     |> assign(:feature, feature)
     |> assign(:current_workspace, current_workspace)}
  end

  # Fallback for routes without explicit workspace_id in path (legacy routes)
  def mount(%{"id" => id} = _params, _session, socket) do
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace
    feature = Planner.get_feature!(id, user, current_workspace.id)

    {:ok,
     socket
     |> assign(:page_title, feature.title)
     |> assign(:feature, feature)
     |> assign(:current_workspace, current_workspace)}
  end
end
