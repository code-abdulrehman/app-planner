defmodule AppPlannerWeb.AppLive.Export do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user

    case Planner.get_app(id, user) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "This project is no longer available.")
         |> push_navigate(to: ~p"/apps")}

      app ->
        # Recursively load children and their features if needed
        # For now, get_app preloads direct children and features.
        # Let's see if we need more depth.
        {:ok,
         socket
         |> assign(:page_title, "Export - #{app.name}")
         |> assign(:app, app)
         |> assign(:current_user, user)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white min-h-screen p-8 md:p-16 text-slate-900 print:p-0 print:bg-white print:text-black">
      <%!-- Controls: hidden during print --%>
      <div class="mb-12 flex justify-between items-center print:hidden border-b pb-6">
        <div>
           <.link navigate={~p"/apps/#{@app.id}"} class="text-xs font-bold text-slate-400 hover:text-primary flex items-center gap-1 mb-2">
             <.icon name="hero-arrow-left" class="w-3 h-3" /> Back to Project
           </.link>
           <h1 class="text-xl font-bold">Export Project Documentation</h1>
        </div>
        <button
          onclick="window.print()"
          class="btn btn-primary btn-sm flex items-center gap-2"
        >
          <.icon name="hero-printer" class="w-4 h-4" />
          Print to PDF
        </button>
      </div>

      <%!-- Document Start --%>
      <div id="document-content" class="max-w-4xl mx-auto space-y-12">
        <%!-- Header --%>
        <header class="border-b-4 border-slate-900 pb-10">
          <div class="flex justify-between items-start mb-6">
            <div>
              <h1 class="text-5xl font-black uppercase tracking-tighter mb-2">{@app.name}</h1>
              <p class="text-lg font-bold text-slate-500 tracking-wide">PROJECT SPECIFICATION DOCUMENT</p>
            </div>
            <div class="text-right">
              <div class="text-4xl font-black text-primary/20">#{@app.id}</div>
              <div class="text-xs font-bold text-slate-400 mt-1 uppercase">Generated: {Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d %H:%M")}</div>
            </div>
          </div>

          <div class="grid grid-cols-2 lg:grid-cols-4 gap-6 py-8 border-y border-slate-200">
             <div>
               <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Status</label>
               <span class="text-sm font-bold uppercase">{@app.status}</span>
             </div>
             <div>
               <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Category</label>
               <span class="text-sm font-bold uppercase">{@app.category}</span>
             </div>
             <div>
               <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Owner</label>
               <span class="text-sm font-bold truncate">{@app.user.email}</span>
             </div>
             <div>
               <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Visibility</label>
               <span class="text-sm font-bold uppercase">{@app.visibility}</span>
             </div>
          </div>
        </header>

        <%!-- Overview --%>
        <section class="space-y-4">
          <h2 class="text-2xl font-black uppercase border-b-2 border-slate-900 pb-2">01. Overview</h2>
          <div class="prose max-w-none text-slate-700 leading-relaxed">
            {@app.description}
          </div>
        </section>

        <%!-- Technical Metadata --%>
        <%= if @app.custom_fields && map_size(@app.custom_fields) > 0 do %>
          <section class="space-y-4">
            <h2 class="text-2xl font-black uppercase border-b-2 border-slate-900 pb-2">02. Technical Metadata</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for {key, value} <- @app.custom_fields do %>
                <div class="border border-slate-200 p-4 rounded bg-slate-50/50">
                  <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest block mb-1">{key}</label>
                  <p class="text-sm font-mono break-all line-clamp-2">{value}</p>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Features --%>
        <%= if length(@app.features) > 0 do %>
          <section class="space-y-8">
            <h2 class="text-2xl font-black uppercase border-b-2 border-slate-900 pb-2">03. Feature Roadmap</h2>
            <div class="space-y-12">
              <%= for feature <- @app.features do %>
                <div class="group border-l-4 border-primary pl-6 py-2 break-inside-avoid">
                  <div class="flex justify-between items-baseline mb-4">
                    <h3 class="text-xl font-bold uppercase tracking-tight">{feature.title}</h3>
                    <span class="text-xs font-black uppercase border-2 border-slate-900 px-2 py-0.5">{feature.status}</span>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-3 gap-8 text-sm">
                    <div class="col-span-2 space-y-4 text-slate-700">
                      <div>
                        <label class="text-[10px] font-black text-slate-400 uppercase mb-1 block">Description</label>
                        <p>{feature.description || "No description provided."}</p>
                      </div>

                      <%= if feature.why do %>
                        <div>
                          <label class="text-[10px] font-black text-slate-400 uppercase mb-1 block">Rationale (Why)</label>
                          <p>{feature.why}</p>
                        </div>
                      <% end %>

                      <%= if feature.how_to_implement do %>
                        <div>
                          <label class="text-[10px] font-black text-slate-400 uppercase mb-1 block">Implementation Strategy</label>
                          <div class="prose-sm prose-slate">
                            {feature.how_to_implement}
                          </div>
                        </div>
                      <% end %>
                    </div>

                    <div class="space-y-4">
                      <%= if feature.time_estimate do %>
                        <div>
                          <label class="text-[10px] font-black text-slate-400 uppercase mb-1 block">Estimated Effort</label>
                          <span class="font-bold">{feature.time_estimate}</span>
                        </div>
                      <% end %>

                      <%= if feature.implementation_date do %>
                        <div>
                          <label class="text-[10px] font-black text-slate-400 uppercase mb-1 block">Target Date</label>
                          <span class="font-bold">{feature.implementation_date}</span>
                        </div>
                      <% end %>

                      <%= if feature.pros do %>
                        <div>
                          <label class="text-[10px] font-black text-slate-400 uppercase mb-1 block text-success">Pros</label>
                          <p class="text-xs">{feature.pros}</p>
                        </div>
                      <% end %>

                      <%= if feature.cons do %>
                        <div>
                          <label class="text-[10px] font-black text-slate-400 uppercase mb-1 block text-error">Cons</label>
                          <p class="text-xs">{feature.cons}</p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Sub-Components --%>
        <%= if length(@app.children) > 0 do %>
          <section class="space-y-6">
            <h2 class="text-2xl font-black uppercase border-b-2 border-slate-900 pb-2">04. Sub-Components</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for child <- @app.children do %>
                <div class="border border-slate-200 p-6 rounded break-inside-avoid">
                  <h3 class="text-lg font-black uppercase mb-2 flex items-center gap-2 text-primary">
                    <.icon name={if child.icon, do: "hero-#{child.icon}", else: "hero-cube"} class="w-4 h-4" />
                    {child.name}
                  </h3>
                  <p class="text-xs text-slate-500 mb-4 line-clamp-3">{child.description}</p>
                  <div class="grid grid-cols-2 gap-2 text-[10px] font-bold uppercase tracking-widest text-slate-400">
                    <div>Status: <span class="text-slate-900">{child.status}</span></div>
                    <div>Category: <span class="text-slate-900">{child.category}</span></div>
                  </div>
                </div>
              <% end %>
            </div>
            <p class="text-xs text-slate-400 italic">Detailed specifications for sub-components are available in their respective documents.</p>
          </section>
        <% end %>

        <%!-- Footer --%>
        <footer class="pt-16 border-t border-slate-100 mt-24 text-center">
          <p class="text-[10px] font-bold text-slate-300 uppercase tracking-[0.2em]">End of Document • Generated by AppPlanner</p>
        </footer>
      </div>
    </div>

    <style>
      @media print {
        @page {
          margin: 0;
          size: auto;
        }
        body {
          background: white !important;
          color: black !important;
          margin: 0 !important;
          padding: 0 !important;
        }
        .print\:hidden {
          display: none !important;
        }
        .break-inside-avoid {
          break-inside: avoid;
        }
        #document-content {
          max-width: 100% !important;
          padding: 2cm !important; /* Re-apply margin as padding so it doesn't trigger browser headers */
        }
      }
    </style>
    """
  end
end
