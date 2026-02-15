defmodule AppPlannerWeb.AppLive.Form do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Planner.App
  alias AppPlannerWeb.IconHelper

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-12 px-6">
      <div class="mb-10 flex items-center justify-between">
        <div>
          <div class="flex items-center gap-2 text-[10px] font-black uppercase text-base-content/30 tracking-widest mb-2">
            <.link
              navigate={~p"/workspaces/#{@current_workspace.id}/apps"}
              class="hover:text-primary transition-colors"
            >
              Projects
            </.link>
            <span>/</span>
            <span class="text-base-content/80">{@page_title}</span>
          </div>
          <h1 class="text-3xl font-black text-base-content tracking-tight">{@page_title}</h1>
        </div>

        <.link
          navigate={~p"/workspaces/#{@current_workspace.id}/board"}
          class="btn btn-ghost btn-sm rounded-lg text-[10px] font-bold border border-base-200"
        >
          Back to Board
        </.link>
      </div>

      <.form for={@form} id="app-form" phx-change="validate" phx-submit="save" class="space-y-6">
        <div class="bg-base-50/50 border border-base-200 rounded-lg p-6 space-y-6">
          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Project Name
              </span>
            </label>
            <.input
              field={@form[:name]}
              type="text"
              placeholder="Enter project name"
              required
              class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
            />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Status
              </span>
            </label>
            <.input
              field={@form[:status]}
              type="select"
              options={["Idea", "Planned", "In Progress", "Completed", "Archived"]}
              class="select select-bordered w-full rounded-lg bg-base-100 font-bold"
            />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Description
              </span>
            </label>
            <.input
              field={@form[:description]}
              type="textarea"
              rows={4}
              placeholder="Provide a brief overview of this project"
              class="textarea textarea-bordered w-full rounded-lg bg-base-100 font-bold leading-relaxed"
            />
          </div>

          <div class="space-y-4">
            <label class="text-[10px] font-black uppercase tracking-widest text-base-content/40 px-1">
              Project Icon
            </label>
            <div class="flex items-center gap-6 p-4 bg-base-100 rounded-lg border border-base-200">
              <div class="w-16 h-16 rounded-lg bg-primary/5 text-primary border border-primary/10 flex items-center justify-center shrink-0 shadow-sm">
                <.icon
                  name={if @icon_preview, do: "hero-#{@icon_preview}", else: "hero-cube"}
                  class="w-8 h-8"
                />
              </div>
              <div class="flex-1">
                <input
                  type="text"
                  name="icon_search"
                  phx-keyup="search-icons"
                  phx-debounce="200"
                  placeholder="Find an icon..."
                  class="input input-sm input-bordered w-full rounded-lg mb-3 bg-base-50 font-bold text-xs"
                  value={@icon_search}
                />
                <div class="grid grid-cols-6 gap-2 p-3 bg-base-50 rounded-lg max-h-36 overflow-y-auto border border-base-200 scrollbar-hidden">
                  <%= for icon <- @filtered_icons do %>
                    <button
                      type="button"
                      phx-click="select-icon"
                      phx-value-icon={icon}
                      class={[
                        "p-2 rounded-lg hover:bg-base-200 hover:shadow-sm border border-transparent transition-all flex items-center justify-center",
                        if(@icon_preview == icon,
                          do: "bg-base-200 border-primary shadow-sm text-primary",
                          else: "text-base-content/20"
                        )
                      ]}
                    >
                      <.icon name={"hero-#{icon}"} class="w-4 h-4" />
                    </button>
                  <% end %>
                  <input type="hidden" name="app[icon]" value={@icon_preview} />
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <.link
            navigate={return_path(@app, @current_workspace)}
            class="btn btn-ghost rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200 px-8"
          >
            Cancel
          </.link>
          <button
            type="submit"
            phx-disable-with="Saving..."
            class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-10 shadow-lg shadow-primary/20"
          >
            {if @live_action == :new, do: "Save Project", else: "Save"}
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_scope.user
    workspace = socket.assigns.current_workspace

    socket =
      socket
      |> assign(:icon_search, "")
      |> assign(:filtered_icons, Enum.take(IconHelper.icons(), 18))
      |> assign(:current_workspace, workspace)

    {:ok, apply_action(socket, socket.assigns.live_action, params, user, workspace)}
  end

  defp apply_action(socket, :edit, %{"id" => id}, user, workspace) do
    app = Planner.get_app!(id, user, workspace.id)

    socket
    |> assign(:page_title, "Update Roadmap")
    |> assign(:app, app)
    |> assign(:icon_preview, app.icon)
    |> assign(:form, to_form(Planner.change_app(app)))
  end

  defp apply_action(socket, :new, _params, _user, _workspace) do
    app = %App{}

    socket
    |> assign(:page_title, "New Project")
    |> assign(:app, app)
    |> assign(:icon_preview, nil)
    |> assign(:form, to_form(Planner.change_app(app)))
  end

  @impl true
  def handle_event("validate", %{"app" => app_params}, socket) do
    app_params = Map.put(app_params, "icon", socket.assigns.icon_preview)

    changeset =
      socket.assigns.app
      |> Planner.change_app(app_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("search-icons", %{"value" => search}, socket) do
    all_icons = IconHelper.icons()

    filtered =
      all_icons
      |> Enum.filter(&String.contains?(&1, String.downcase(search || "")))
      |> Enum.take(18)

    {:noreply, assign(socket, icon_search: search, filtered_icons: filtered)}
  end

  @impl true
  def handle_event("select-icon", %{"icon" => icon}, socket) do
    {:noreply, assign(socket, icon_preview: icon)}
  end

  @impl true
  def handle_event("save", %{"app" => app_params}, socket) do
    app_params = Map.put(app_params, "icon", socket.assigns.icon_preview)
    save_app(socket, socket.assigns.live_action, app_params)
  end

  defp save_app(socket, :edit, app_params) do
    user = socket.assigns.current_scope.user

    case Planner.update_app(socket.assigns.app, app_params, user) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project saved successfully")
         |> push_navigate(to: ~p"/workspaces/#{socket.assigns.current_workspace.id}/board")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_app(socket, :new, app_params) do
    user = socket.assigns.current_scope.user
    workspace = socket.assigns.current_workspace

    case Planner.create_app(app_params, user, workspace.id) do
      {:ok, _app} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_navigate(to: ~p"/workspaces/#{workspace.id}/board")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(app, workspace) do
    if app.id,
      do: ~p"/workspaces/#{workspace.id}/apps/#{app.id}",
      else: ~p"/workspaces/#{workspace.id}/apps"
  end
end
