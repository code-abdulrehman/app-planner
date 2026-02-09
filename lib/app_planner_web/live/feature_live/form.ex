defmodule AppPlannerWeb.FeatureLive.Form do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Planner.Feature
  alias AppPlannerWeb.IconHelper

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-12 px-6">
      <div class="mb-10 flex items-center justify-between">
        <div>
           <div class="flex items-center gap-2 text-[10px] font-black uppercase text-base-content/30 tracking-widest mb-2">
              <.link :if={@feature.app_id} navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{@feature.app_id}"} class="hover:text-primary transition-colors">
                {@feature.app.name}
              </.link>
              <span :if={@feature.app_id} class="text-base-content/10">/</span>
              <span class="text-base-content/80">{@page_title}</span>
           </div>
           <h1 class="text-3xl font-black text-base-content tracking-tight">{@page_title}</h1>
        </div>

        <.link navigate={return_path(@return_to, @feature, @current_workspace)} class="btn btn-ghost btn-sm rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200">
           Back
        </.link>
      </div>

      <.form for={@form} id="feature-form" phx-change="validate" phx-submit="save" class="space-y-8">
        <div class="bg-base-50/50 border border-base-200 rounded-xl p-8 space-y-8">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div class="md:col-span-2">
                 <div class="form-control">
                    <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Module Name</span></label>
                    <.input field={@form[:title]} type="text" placeholder="e.g. My Feature" required class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
                 </div>
              </div>

             <div class="form-control">
                <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Linked Project</span></label>
                <div :if={!@feature.app_id}>
                   <.input field={@form[:app_id]} type="select" options={Enum.map(@apps, &{&1.name, &1.id})} prompt="Select host project..." class="select select-bordered w-full rounded-lg bg-base-100 font-bold" />
                </div>
                <div :if={@feature.app_id} class="input input-bordered bg-base-200/50 flex items-center rounded-lg font-bold text-sm text-base-content/60 border-dashed">
                   {@feature.app.name}
                   <input type="hidden" name="feature[app_id]" value={@feature.app_id} />
                </div>
             </div>

              <div class="form-control">
                 <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Status</span></label>
                 <.input field={@form[:status]} type="select" options={["Idea", "Planned", "In Progress", "Completed", "Archived"]} class="select select-bordered w-full rounded-lg bg-base-100 font-bold" />
              </div>
          </div>

           <div class="form-control">
              <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Description</span></label>
              <.input field={@form[:description]} type="textarea" rows={6} placeholder="What does this module do?" class="textarea textarea-bordered w-full rounded-lg bg-base-100 font-bold leading-relaxed" />
           </div>

          <div class="space-y-4">
            <label class="text-[10px] font-black uppercase tracking-widest text-base-content/40 px-1">Visual ID</label>
            <div class="flex items-center gap-6 p-4 bg-base-100 rounded-lg border border-base-200">
              <div class="w-16 h-16 rounded-lg bg-primary/5 text-primary border border-primary/10 flex items-center justify-center shrink-0 shadow-sm">
                <.icon name={if @icon_preview, do: "hero-#{@icon_preview}", else: "hero-bolt"} class="w-8 h-8" />
              </div>
               <div class="flex-1">
                 <input type="text" name="icon_search" phx-keyup="search-icons" phx-debounce="200" placeholder="Search icons..." class="input input-sm input-bordered w-full rounded-lg mb-3 bg-base-50 font-bold text-xs" value={@icon_search} />
                 <div class="grid grid-cols-6 sm:grid-cols-10 gap-2 p-3 bg-base-50 rounded-lg max-h-36 overflow-y-auto border border-base-200 scrollbar-hidden">
                  <%= for icon <- @filtered_icons do %>
                    <button type="button" phx-click="select-icon" phx-value-icon={icon}
                            class={["p-2 rounded-lg hover:bg-white hover:shadow-sm border border-transparent transition-all flex items-center justify-center",
                                    if(@icon_preview == icon, do: "bg-white border-primary shadow-sm text-primary", else: "text-base-content/20")]}>
                      <.icon name={"hero-#{icon}"} class="w-4 h-4" />
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
            <input type="hidden" name="feature[icon]" value={@icon_preview} />
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <.link navigate={return_path(@return_to, @feature, @current_workspace)} class="btn btn-ghost rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200 px-8">Cancel</.link>
          <button type="submit" phx-disable-with="Saving..." class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-10 shadow-lg shadow-primary/20">
            {if @live_action == :new, do: "Save Module", else: "Save"}
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    current_workspace = socket.assigns.current_workspace

    {:ok,
     socket
     |> assign(:return_to, params["return_to"] || "app")
     |> assign(:icon_search, "")
     |> assign(:filtered_icons, Enum.take(IconHelper.icons(), 20))
     |> assign(:current_workspace, current_workspace)
     |> apply_action(socket.assigns.live_action, params, current_workspace)}
  end

  defp apply_action(socket, :edit, %{"id" => id}, current_workspace) do
    user = socket.assigns.current_scope.user
    feature = Planner.get_feature!(id, user, current_workspace.id)
    app = Planner.get_app!(feature.app_id, user, current_workspace.id)
    apps = Planner.list_apps(user, current_workspace.id)

    socket
    |> assign(:page_title, "Update Module")
    |> assign(:feature, %{feature | app: app})
    |> assign(:apps, apps)
    |> assign(:icon_preview, feature.icon)
    |> assign(:form, to_form(Planner.change_feature(feature)))
  end

  defp apply_action(socket, :new, params, current_workspace) do
    user = socket.assigns.current_scope.user
    app_id = params["app_id"]
    apps = Planner.list_apps(user, current_workspace.id)

    feature = %Feature{
      app_id: app_id && if(is_binary(app_id), do: String.to_integer(app_id), else: app_id)
    }

    feature =
      if app_id,
        do: %{feature | app: Planner.get_app!(app_id, user, current_workspace.id)},
        else: feature

    socket
    |> assign(:page_title, "New Module")
    |> assign(:feature, feature)
    |> assign(:apps, apps)
    |> assign(:icon_preview, nil)
    |> assign(:form, to_form(Planner.change_feature(feature)))
  end

  @impl true
  def handle_event("validate", %{"feature" => feature_params}, socket) do
    feature_params = Map.put(feature_params, "icon", socket.assigns.icon_preview)

    changeset =
      socket.assigns.feature
      |> Planner.change_feature(feature_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("search-icons", %{"value" => search}, socket) do
    filtered =
      AppPlannerWeb.IconHelper.icons()
      |> Enum.filter(&String.contains?(String.downcase(&1), String.downcase(search)))
      |> Enum.take(20)

    {:noreply, assign(socket, icon_search: search, filtered_icons: filtered)}
  end

  @impl true
  def handle_event("select-icon", %{"icon" => icon}, socket) do
    {:noreply, assign(socket, icon_preview: icon)}
  end

  @impl true
  def handle_event("save", %{"feature" => feature_params}, socket) do
    feature_params = Map.put(feature_params, "icon", socket.assigns.icon_preview)
    save_feature(socket, socket.assigns.live_action, feature_params)
  end

  defp save_feature(socket, :edit, feature_params) do
    user = socket.assigns.current_scope.user

    case Planner.update_feature(socket.assigns.feature, feature_params, user) do
      {:ok, feature} ->
        {:noreply,
         socket
         |> put_flash(:info, "Module saved successfully")
         |> push_navigate(
           to: return_path(socket.assigns.return_to, feature, socket.assigns.current_workspace)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_feature(socket, :new, feature_params) do
    user = socket.assigns.current_scope.user

    case Planner.create_feature(feature_params, user) do
      {:ok, feature} ->
        {:noreply,
         socket
         |> put_flash(:info, "Module created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.return_to, feature, socket.assigns.current_workspace)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("show", feature, current_workspace),
    do:
      ~p"/workspaces/#{current_workspace.id}/apps/#{feature.app_id}/features/#{feature.id}/tasks"

  defp return_path("app", feature, current_workspace),
    do: ~p"/workspaces/#{current_workspace.id}/apps/#{feature.app_id}"

  defp return_path(_, feature, current_workspace) do
    if feature.app_id,
      do: ~p"/workspaces/#{current_workspace.id}/apps/#{feature.app_id}",
      else: ~p"/workspaces/#{current_workspace.id}/apps"
  end
end
