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
      <div id="document-content" class="max-w-4xl mx-auto space-y-16">
        <%!-- Header --%>
        <header class="border-b-8 border-slate-900 pb-12">
          <div class="flex justify-between items-start mb-8">
            <div>
              <h1 class="text-3xl font-black uppercase tracking-tighter mb-2">{@app.name}</h1>
              <p class="text-md font-bold text-slate-500 tracking-[0.1em]">PROJECT SPECIFICATION DOCUMENT</p>
            </div>
            <div class="text-right">
              <div class="text-5xl font-black text-primary/10 tracking-widest leading-none">#{@app.id}</div>
              <div class="text-[10px] font-black text-slate-400 mt-2 uppercase tracking-[0.2em]">Generated: {Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d %H:%M")}</div>
            </div>
          </div>

          <div class="grid grid-cols-2 lg:grid-cols-4 gap-8 py-10 border-y border-slate-100">
             <div>
               <label class="text-[9px] font-black text-slate-400 uppercase tracking-[0.3em] block mb-2">Current Status</label>
               <span class="text-xs font-black uppercase bg-slate-100 px-3 py-1 rounded">{@app.status}</span>
             </div>
             <div>
               <label class="text-[9px] font-black text-slate-400 uppercase tracking-[0.3em] block mb-2">Market Category</label>
               <span class="text-sm font-bold uppercase tracking-tight">{@app.category}</span>
             </div>
             <div>
               <label class="text-[9px] font-black text-slate-400 uppercase tracking-[0.3em] block mb-2">Project Owner</label>
               <span class="text-sm font-bold truncate tracking-tight">{@app.user.email}</span>
             </div>
             <div>
               <label class="text-[9px] font-black text-slate-400 uppercase tracking-[0.3em] block mb-2">Visibility Level</label>
               <span class={"text-xs font-black uppercase #{if @app.visibility == "public", do: "text-success", else: "text-slate-400"}"}>
                 {@app.visibility}
               </span>
             </div>
          </div>
        </header>

        <%!-- Overview --%>
        <section class="space-y-6">
          <div class="flex items-center gap-4">
            <span class="text-4xl font-black text-slate-200">01</span>
            <h2 class="text-3xl font-black uppercase tracking-tight">Executive Summary</h2>
          </div>
          <div class="pl-14 border-l-2 border-slate-100">
            <.markdown content={@app.description} />
          </div>
        </section>

        <%!-- Technical Metadata --%>
        <%= if @app.custom_fields && map_size(@app.custom_fields) > 0 do %>
          <section class="space-y-6">
            <div class="flex items-center gap-4">
              <span class="text-4xl font-black text-slate-200">02</span>
              <h2 class="text-3xl font-black uppercase tracking-tight">Metadata</h2>
            </div>
            <div class="pl-14">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= for {key, value} <- @app.custom_fields do %>
                  <div class="group border border-slate-100 p-5 rounded-xl hover:border-primary transition-colors">
                    <label class="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] block mb-2">{key}</label>
                    <div class="text-sm font-bold break-all">
                      <.markdown content={value} compact={true} />
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </section>
        <% end %>

        <%!-- Features --%>
        <%= if length(@app.features) > 0 do %>
          <section class="space-y-12">
            <div class="flex items-center gap-4">
              <span class="text-4xl font-black text-slate-200">03</span>
              <h2 class="text-3xl font-black uppercase tracking-tight">Feature Roadmap</h2>
            </div>

            <div class="pl-12 space-y-20  border-l-2 border-slate-100">
              <%= for feature <- @app.features do %>
                <div class="break-inside-avoid relative">
                  <!-- <div class="absolute -left-14 top-2 w-10 h-[2px] bg-primary/20"></div> -->

                  <div class="flex justify-between items-center mb-8">
                    <h3 class="text-2xl font-black uppercase tracking-tighter flex items-center gap-3">
                      <span class="p-2 bg-primary/5 rounded-lg text-primary">
                        <.icon name={if feature.icon, do: "hero-#{feature.icon}", else: "hero-bolt"} class="w-6 h-6" />
                      </span>
                      {feature.title}
                    </h3>
                    <div class="flex items-center gap-2">
                      <span class="text-[10px] font-black uppercase border-2 border-slate-900 px-3 py-1">{feature.status}</span>
                    </div>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-12 gap-10">
                    <div class="md:col-span-8 space-y-8">
                      <div>
                        <h4 class="text-[10px] font-black uppercase text-slate-400 tracking-[0.2em] mb-3">Feature Overview</h4>
                        <.markdown content={feature.description || "No description provided."} />
                      </div>

                      <%= if feature.why_need || feature.why do %>
                        <div>
                          <h4 class="text-[10px] font-black uppercase text-slate-400 tracking-[0.2em] mb-3">Rationale & Strategic Value</h4>
                          <.markdown content={feature.why_need || feature.why} />
                        </div>
                      <% end %>

                      <%= if feature.how_to_add do %>
                        <div class="bg-slate-50 p-6 rounded-2xl border border-slate-100">
                          <h4 class="text-[10px] font-black uppercase text-slate-400 tracking-[0.2em] mb-3">Proposed User Flow</h4>
                          <.markdown content={feature.how_to_add} />
                        </div>
                      <% end %>

                      <%= if feature.how_to_implement do %>
                        <div>
                          <h4 class="text-[10px] font-black uppercase text-slate-400 tracking-[0.2em] mb-3">Technical Implementation Strategy</h4>
                          <.markdown content={feature.how_to_implement} />
                        </div>
                      <% end %>
                    </div>

                    <div class="md:col-span-4 space-y-6">
                      <div class="grid grid-cols-2 gap-4">
                        <div class="bg-slate-50 p-4 rounded-xl">
                          <label class="text-[9px] font-black text-slate-400 uppercase mb-2 block tracking-widest">Effort</label>
                          <span class="text-sm font-black text-slate-900">{feature.time_estimate || "—"}</span>
                        </div>
                        <div class="bg-slate-50 p-4 rounded-xl">
                          <label class="text-[9px] font-black text-slate-400 uppercase mb-2 block tracking-widest">Target Date</label>
                          <span class="text-sm font-black text-slate-900">{feature.implementation_date || "—"}</span>
                        </div>
                      </div>

                      <%= if feature.pros do %>
                        <div class="border-l-4 border-emerald-500 pl-4 py-1">
                          <label class="text-[9px] font-black text-emerald-600 uppercase mb-2 block tracking-widest">Strengths</label>
                          <.markdown content={feature.pros} class="!text-xs" />
                        </div>
                      <% end %>

                      <%= if feature.cons do %>
                        <div class="border-l-4 border-rose-500 pl-4 py-1">
                          <label class="text-[9px] font-black text-rose-600 uppercase mb-2 block tracking-widest">Challenges</label>
                          <.markdown content={feature.cons} class="!text-xs" />
                        </div>
                      <% end %>

                      <%= if feature.custom_fields && map_size(feature.custom_fields) > 0 do %>
                        <div class="pt-4 border-t border-slate-100">
                          <label class="text-[9px] font-black text-slate-400 uppercase mb-2 block tracking-widest">Feature Metadata</label>
                          <div class="grid grid-cols-2 gap-2">
                            <%= for {key, value} <- feature.custom_fields do %>
                              <div class="text-[10px]">
                                <span class="font-black uppercase text-slate-400">{key}:</span>
                                <div class="font-bold inline-block">
                                  <.markdown content={value} compact={true} />
                                </div>
                              </div>
                            <% end %>
                          </div>
                        </div>
                      <% end %>

                      <%= if feature.pr_link do %>
                         <div class="pt-4 mt-4 border-t border-slate-100">
                           <label class="text-[9px] font-black text-slate-400 uppercase mb-2 block tracking-widest">Reference Links</label>
                           <a href={feature.pr_link} target="_blank" class="text-[10px] font-mono font-black text-primary hover:underline truncate block">{feature.pr_link}</a>
                         </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Sub-Components Deep-Dive --%>
        <%= if length(@app.children) > 0 do %>
          <section class="space-y-16">
            <div class="flex items-center gap-4">
              <span class="text-4xl font-black text-slate-200">04</span>
              <h2 class="text-3xl font-black uppercase tracking-tight">Sub-Components:</h2>
            </div>

            <div class="space-y-24 pl-14">
              <%= for child <- @app.children do %>
                <div class="break-inside-avoid-page space-y-10 border-t-2 border-slate-100 pt-10">
                  <div class="flex flex-col md:flex-row md:items-start justify-between gap-8">
                    <div class="space-y-4 max-w-2xl">
                      <h3 class="text-4xl font-black uppercase tracking-tighter flex items-center gap-4">
                        <span class="p-3 bg-primary/10 rounded-2xl text-primary print:border print:border-primary">
                          <.icon name={if child.icon, do: "hero-#{child.icon}", else: "hero-cube"} class="w-8 h-8" />
                        </span>
                        {child.name}
                      </h3>
                      <div class="prose prose-slate max-w-none">
                        <.markdown content={child.description} />
                      </div>
                    </div>

                    <div class="flex flex-wrap gap-4 md:flex-col md:items-end">
                      <div class="bg-slate-50 p-4 rounded-xl min-w-[140px] text-right">
                        <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest block mb-1">Status</label>
                        <span class="text-sm font-black uppercase">{child.status}</span>
                      </div>
                      <div class="bg-slate-50 p-4 rounded-xl min-w-[140px] text-right">
                        <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest block mb-1">Type</label>
                        <span class="text-sm font-black uppercase font-mono">{child.category}</span>
                      </div>
                    </div>
                  </div>

                  <%!-- Sub-Component Features --%>
                  <%= if length(child.features) > 0 do %>
                    <div class="space-y-8 pl-8 border-l-4 border-slate-50">
                      <h4 class="text-xs font-black uppercase tracking-[0.4em] text-slate-400">System Modules & Features</h4>

                      <div class="grid grid-cols-1 gap-12">
                        <%= for feature <- child.features do %>
                          <div class="break-inside-avoid">
                            <div class="flex justify-between items-center mb-6">
                              <h5 class="text-xl font-black uppercase tracking-tight flex items-center gap-3">
                                <span class="w-8 h-8 rounded bg-primary/5 flex items-center justify-center text-primary print:border">
                                  <.icon name={if feature.icon, do: "hero-#{feature.icon}", else: "hero-bolt"} class="w-4 h-4" />
                                </span>
                                {feature.title}
                              </h5>
                              <span class="text-[10px] font-black uppercase bg-slate-100 px-3 py-1 rounded">{feature.status}</span>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-12 gap-8">
                              <div class="md:col-span-8 space-y-4">
                                <div>
                                  <label class="text-[8px] font-black uppercase text-slate-300 tracking-widest mb-1 block">Functional Requirements</label>
                                  <.markdown content={feature.description || "No detail provided."} class="!text-xs opacity-80" />
                                </div>

                                <%= if feature.why_need || feature.why do %>
                                  <div>
                                    <label class="text-[8px] font-black uppercase text-slate-300 tracking-widest mb-1 block">Strategic Rationale</label>
                                    <.markdown content={feature.why_need || feature.why} class="!text-xs opacity-70" />
                                  </div>
                                <% end %>

                                <%= if feature.how_to_implement do %>
                                  <div>
                                    <label class="text-[8px] font-black uppercase text-slate-300 tracking-widest mb-1 block">Technical Strategy</label>
                                    <.markdown content={feature.how_to_implement} class="!text-xs opacity-70" />
                                  </div>
                                <% end %>
                              </div>

                              <div class="md:col-span-4 space-y-4 bg-slate-50/50 p-4 rounded-xl border border-slate-100">
                                <div class="grid grid-cols-2 gap-2">
                                  <div>
                                    <label class="text-[8px] font-black text-slate-400 uppercase tracking-widest block mb-0.5">Effort</label>
                                    <span class="text-[10px] font-bold">{feature.time_estimate || "—"}</span>
                                  </div>
                                  <div>
                                    <label class="text-[8px] font-black text-slate-400 uppercase tracking-widest block mb-0.5">Date</label>
                                    <span class="text-[10px] font-bold">{feature.implementation_date || "—"}</span>
                                  </div>
                                </div>

                                <%= if feature.pros do %>
                                  <div class="border-t border-slate-100 pt-2 mt-2">
                                    <label class="text-[8px] font-black text-emerald-600 uppercase tracking-widest block mb-1">Key Strengths</label>
                                    <div class="text-[10px]"><.markdown content={feature.pros} /></div>
                                  </div>
                                <% end %>

                                <%= if feature.cons do %>
                                  <div class="border-t border-slate-100 pt-2">
                                    <label class="text-[8px] font-black text-rose-600 uppercase tracking-widest block mb-1">Risk Factors</label>
                                    <div class="text-[10px]"><.markdown content={feature.cons} /></div>
                                  </div>
                                <% end %>

                                <%= if feature.custom_fields && map_size(feature.custom_fields) > 0 do %>
                                  <div class="border-t border-slate-100 pt-2">
                                    <label class="text-[8px] font-black text-slate-400 uppercase tracking-widest block mb-1">Feature Metadata</label>
                                    <div class="grid grid-cols-1 gap-1">
                                      <%= for {key, value} <- feature.custom_fields do %>
                                        <div class="text-[10px]">
                                          <span class="font-black uppercase text-slate-400">{key}:</span>
                                          <div class="font-bold inline-block"><.markdown content={value} compact={true} /></div>
                                        </div>
                                      <% end %>
                                    </div>
                                  </div>
                                <% end %>
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>
        <% end %>

        <%!-- Footer --%>
        <footer class="pt-24 border-t border-slate-100 mt-32 text-center opacity-30">
          <p class="text-[10px] font-black uppercase tracking-[0.5em]">Project Documentation Master • Page End</p>
          <p class="text-[8px] mt-2 font-bold tracking-widest uppercase">Proprietary and Confidential</p>
        </footer>
      </div>
    </div>

    <style>
      @media print {
        @page {
          margin: 1.5cm;
          size: A4;
        }
        body {
          background: white !important;
          color: black !important;
          margin: 0 !important;
          padding: 0 !important;
          -webkit-print-color-adjust: exact;
          print-color-adjust: exact;
        }
        .print\:hidden {
          display: none !important;
        }
        .break-inside-avoid {
          break-inside: avoid;
        }
        .break-inside-avoid-page {
          break-inside: avoid-page;
        }
        #document-content {
          max-width: 100% !important;
          padding: 0 !important;
        }
        /* Ensure icons show up in PDF: Heroicons use masks, which print poorly.
           We force them to show or at least prevent shifting/whitespace issues. */
        [class^="hero-"], [class*=" hero-"] {
          display: inline-block !important;
          background-color: currentColor !important;
          -webkit-print-color-adjust: exact;
          /* If the mask is missing, at least show a block of color or nothing instead of weird spacing */
        }
        /* Increase contrast for print */
        .text-slate-200 { color: #e2e8f0 !important; }
        .text-slate-400 { color: #94a3b8 !important; }
        .bg-slate-50 { background-color: #f8fafc !important; }
      }
    </style>
    """
  end
end
