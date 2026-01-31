defmodule AppPlannerWeb.FeatureLive.Index do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        <div class="flex flex-col gap-1">
          <div :if={@app} class="mb-2">
            <.link navigate={~p"/apps/#{@app}"} class="btn btn-ghost btn-xs gap-2 text-gray-400 hover:text-primary p-0">
               <.icon name="hero-arrow-left" class="w-3 h-3" /> Back to {@app.name}
            </.link>
          </div>
          <h1 class="text-2xl font-black">
            <%= if @app, do: "Features for #{@app.name}", else: "Listing All Features" %>
          </h1>
        </div>
        <:actions>
          <.button variant="primary" navigate={if @app, do: ~p"/features/new?app_id=#{@app.id}&return_to=app", else: ~p"/features/new"}>
            <.icon name="hero-plus" /> New Feature
          </.button>
        </:actions>
      </.header>

      <div class="max-w-5xl mx-auto border-t border-base-200 mt-8" id="features" phx-update="stream">
        <div :for={{id, feature} <- @streams.features} id={id} class="group border-b border-base-200 hover:bg-base-200/50 transition-all px-4 py-6 flex items-center justify-between gap-6">
            <div class="flex items-center gap-5 cursor-pointer flex-1" phx-click={JS.navigate(~p"/features/#{feature}")}>
               <div class="w-10 h-10 rounded-lg bg-base-200 flex items-center justify-center text-gray-400 group-hover:bg-primary group-hover:text-primary-content transition-all border">
                  <.icon name={if feature.icon, do: "hero-#{feature.icon}", else: "hero-bolt"} class="w-5 h-5" />
               </div>
               <div>
                  <h3 class="text-base font-bold tracking-tight mb-0.5">{feature.title}</h3>
                  <div class="flex gap-3 items-center text-[10px] text-gray-400 font-bold uppercase tracking-widest flex-wrap">
                    <span>{feature.time_estimate || "No est."}</span>
                    <span>•</span>
                    <span>{feature.implementation_date || "No date"}</span>
                    <span :if={feature.app}>• {feature.app.name}</span>
                    <%= if feature.pr_link && feature.pr_link != "" do %>
                      <a href={feature.pr_link} target="_blank" rel="noopener noreferrer" class="text-primary hover:underline" phx-click-stop>GIT</a>
                    <% end %>
                  </div>
               </div>
            </div>

            <div class="flex items-center gap-2">
              <.link navigate={~p"/features/#{feature}/edit"} class="btn btn-ghost btn-xs text-gray-400 hover:text-primary">
                 <.icon name="hero-pencil" class="w-4 h-4" />
              </.link>
              <.link
                phx-click={JS.push("delete", value: %{id: feature.id}) |> hide("##{id}")}
                data-confirm="Are you sure?"
                class="btn btn-ghost btn-xs text-gray-400 hover:text-error"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </.link>
            </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_scope.user

    app =
      case params["app_id"] do
        nil -> nil
        id -> Planner.get_app!(id, user)
      end

    features =
      if app do
        Enum.map(app.features, &%{&1 | app: app})
      else
        Planner.list_features(user)
      end

    {:ok,
     socket
     |> assign(:page_title, if(app, do: "Features for #{app.name}", else: "Listing Features"))
     |> assign(:app, app)
     |> stream(:features, features)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    feature = Planner.get_feature!(id, user)
    {:ok, _} = Planner.delete_feature(feature)

    {:noreply, stream_delete(socket, :features, feature)}
  end
end
