defmodule AppPlannerWeb.FeatureLive.Form do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Planner.Feature
  alias AppPlannerWeb.IconHelper
  alias AppPlannerWeb.ScopeFromPath

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-12 px-6">
      <div class="mb-10 flex items-center justify-between">
        <div>
          <div class="flex items-center gap-2 text-[10px] font-black uppercase text-base-content/30 tracking-widest mb-2">
            <.link
              :if={@feature.app_id && @feature.app}
              navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{@feature.app_id}"}
              class="hover:text-primary transition-colors"
            >
              {@feature.app.name}
            </.link>
            <span :if={@feature.app_id} class="text-base-content/10">/</span>
            <span class="text-base-content/80">{@page_title}</span>
          </div>
          <h1 class="text-3xl font-black text-base-content tracking-tight">{@page_title}</h1>
        </div>

        <.link
          navigate={return_path(@return_to, @feature, @current_workspace)}
          class="btn btn-ghost btn-sm rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200"
        >
          Back
        </.link>
      </div>

      <.form
        for={@form}
        id={"feature-form-#{@feature.id || "new"}"}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <div class="bg-base-50/50 border border-base-200 rounded-lg p-6 space-y-6">
          <!-- Title Section -->
          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Feature Title
              </span>
            </label>
            <.input
              field={@form[:title]}
              type="text"
              value={@feature.title}
              placeholder="Name this feature"
              required
              class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
            />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Project
              </span>
            </label>
            <div :if={!@feature.app_id}>
              <.input
                field={@form[:app_id]}
                type="select"
                options={Enum.map(@apps, &{&1.name, &1.id})}
                prompt="Select a project"
                class="select select-bordered w-full rounded-lg bg-base-100 font-bold"
              />
            </div>
            <div
              :if={@feature.app_id}
              class="input input-bordered bg-base-200/50 flex items-center rounded-lg font-bold text-sm text-base-content/60 border-dashed"
            >
              {if @feature.app, do: @feature.app.name, else: ""}
              <input type="hidden" name="feature[app_id]" value={@feature.app_id} />
            </div>
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Summary <span class="font-normal normal-case text-base-content/35">(optional)</span>
              </span>
            </label>
            <.input
              field={@form[:description]}
              type="textarea"
              rows={4}
              value={@feature.description}
              placeholder="What’s included in this feature?"
              class="textarea textarea-bordered w-full rounded-lg bg-base-100 font-bold leading-relaxed"
            />
          </div>
          
    <!-- Icon Selection -->
          <div class="space-y-4">
            <label class="text-[10px] font-black uppercase tracking-widest text-base-content/40 px-1">
              Icon
            </label>
            <div class="flex items-center gap-6 p-4 bg-base-100 rounded-lg border border-base-200">
              <div class="w-16 h-16 rounded-lg bg-primary/5 text-primary border border-primary/10 flex items-center justify-center shrink-0 shadow-sm">
                <.icon
                  name={if @icon_preview, do: "hero-#{@icon_preview}", else: "hero-bolt"}
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
                <div class="grid grid-cols-6 sm:grid-cols-10 gap-2 p-3 bg-base-50 rounded-lg max-h-36 overflow-y-auto border border-base-200 scrollbar-hidden">
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
                </div>
              </div>
            </div>
            <input type="hidden" name="feature[icon]" value={@icon_preview} />
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <.link
            navigate={return_path(@return_to, @feature, @current_workspace)}
            class="btn btn-ghost rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200 px-8"
          >
            Cancel
          </.link>
          <button
            type="submit"
            phx-disable-with="Saving..."
            class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-10 shadow-lg shadow-primary/20"
          >
            {if @live_action == :new, do: "Save Feature", else: "Save"}
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    current_workspace = socket.assigns.current_workspace
    user = socket.assigns.current_scope.user

    socket =
      socket
      |> assign(:return_to, "app")
      |> assign(:icon_search, "")
      |> assign(:filtered_icons, Enum.take(IconHelper.icons(), 20))
      |> assign(:current_workspace, current_workspace)

    # `live_action` isn't reliably set during the disconnected mount render.
    # If an id is present, treat it as edit so the first render includes values.
    socket =
      if is_binary(params["id"]) do
        feature = Planner.get_feature!(params["id"], user, current_workspace.id)
        app = Planner.get_app!(feature.app_id, user, current_workspace.id)
        feature = %{feature | app: app}
        apps = Planner.list_apps(user, current_workspace.id)

        changeset =
          Planner.change_feature(feature, %{
            "title" => feature.title,
            "description" => feature.description,
            "app_id" => feature.app_id,
            "icon" => feature.icon
          })

        if Mix.env() == :dev do
          IO.inspect(
            %{params: params, feature: feature, changeset: changeset},
            label: "FeatureLive.Form mount/edit"
          )
        end

        socket
        |> assign(:apps, apps)
        |> assign(:page_title, "Update Feature")
        |> assign(:feature, feature)
        |> assign(:icon_preview, feature.icon)
        |> assign(:form, to_form(changeset))
      else
        if Mix.env() == :dev do
          IO.inspect(%{params: params, live_action: socket.assigns.live_action},
            label: "FeatureLive.Form mount/non-edit"
          )
        end

        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, url, socket) do
    params = ScopeFromPath.merge_scoped_params(params, url)
    socket = ScopeFromPath.align_current_workspace(socket, params)
    current_workspace = socket.assigns.current_workspace
    return_to = params["return_to"] || socket.assigns.return_to || "app"
    user = socket.assigns.current_scope.user
    apps = Planner.list_apps(user, current_workspace.id)

    if Mix.env() == :dev do
      IO.inspect(%{params: params, url: url, live_action: socket.assigns.live_action},
        label: "FeatureLive.Form handle_params"
      )
    end

    socket =
      socket
      |> assign(:return_to, return_to)
      |> assign(:apps, apps)

    {:noreply, apply_action(socket, socket.assigns.live_action, params, current_workspace)}
  end

  defp apply_action(socket, :edit, params, current_workspace) do
    user = socket.assigns.current_scope.user

    case Map.get(params, "id") do
      nil ->
        socket
        |> put_flash(:error, "Missing feature id.")
        |> push_navigate(to: ~p"/workspaces/#{current_workspace.id}/board")

      id ->
        feature = Planner.get_feature!(id, user, current_workspace.id)
        app = Planner.get_app!(feature.app_id, user, current_workspace.id)
        feature = %{feature | app: app}

        changeset =
          Planner.change_feature(feature, %{
            "title" => feature.title,
            "description" => feature.description,
            "app_id" => feature.app_id,
            "icon" => feature.icon
          })

        if Mix.env() == :dev do
          IO.inspect(
            %{params: params, feature: feature, changeset: changeset},
            label: "FeatureLive.Form apply_action/edit"
          )
        end

        socket
        |> assign(:page_title, "Update Feature")
        |> assign(:feature, feature)
        |> assign(:icon_preview, feature.icon)
        |> assign(:form, to_form(changeset))
    end
  end

  defp apply_action(socket, :new, params, current_workspace) do
    user = socket.assigns.current_scope.user
    app_id = params["app_id"]

    feature = %Feature{
      app_id: app_id && if(is_binary(app_id), do: String.to_integer(app_id), else: app_id)
    }

    feature =
      if app_id,
        do: %{feature | app: Planner.get_app!(app_id, user, current_workspace.id)},
        else: feature

    socket
    |> assign(:page_title, "New Feature")
    |> assign(:feature, feature)
    |> assign(:icon_preview, nil)
    |> assign(:form, to_form(Planner.change_feature(feature)))
  end

  @impl true
  def handle_event("validate", %{"feature" => feature_params}, socket) do
    feature_params =
      feature_params
      |> Map.put("icon", socket.assigns.icon_preview)
      |> ensure_feature_persisted_fields(socket)

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
    cs =
      socket.assigns.form.source
      |> Ecto.Changeset.put_change(:icon, icon)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:icon_preview, icon)
     |> assign(:form, to_form(cs))}
  end

  @impl true
  def handle_event("save", %{"feature" => feature_params}, socket) do
    feature_params =
      feature_params
      |> Map.put("icon", socket.assigns.icon_preview)
      |> ensure_feature_persisted_fields(socket)

    save_feature(socket, socket.assigns.live_action, feature_params)
  end

  defp ensure_feature_persisted_fields(params, socket) do
    user = socket.assigns.current_scope.user
    feature = socket.assigns.feature

    params
    |> Map.put_new("user_id", to_string(feature.user_id || user.id))
    |> Map.put_new("last_updated_by_id", to_string(user.id))
    |> then(fn p ->
      if feature.app_id,
        do: Map.put_new(p, "app_id", to_string(feature.app_id)),
        else: p
    end)
  end

  defp save_feature(socket, :edit, feature_params) do
    user = socket.assigns.current_scope.user

    case Planner.update_feature(socket.assigns.feature, feature_params, user) do
      {:ok, _feature} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feature saved successfully")
         |> push_navigate(to: ~p"/workspaces/#{socket.assigns.current_workspace.id}/board")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_feature(socket, :new, feature_params) do
    user = socket.assigns.current_scope.user

    case Planner.create_feature(feature_params, user) do
      {:ok, _feature} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feature created successfully")
         |> push_navigate(to: ~p"/workspaces/#{socket.assigns.current_workspace.id}/board")}

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
      else: ~p"/workspaces/#{current_workspace.id}"
  end
end
