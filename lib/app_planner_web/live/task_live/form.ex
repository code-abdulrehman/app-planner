defmodule AppPlannerWeb.TaskLive.Form do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Planner.Task
  alias AppPlanner.Workspaces

  @impl true
  def mount(params, _session, socket) do
    workspace_id = params["workspace_id"]
    app_id = params["app_id"]
    feature_id = params["feature_id"]
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace

    feature = Planner.get_feature!(feature_id, user, workspace_id)
    app = Planner.get_app!(app_id, user, workspace_id)

    workspace_members = Workspaces.list_workspace_members(workspace_id)
    assignees = Enum.map(workspace_members, fn m -> {m.user.email, m.user_id} end)

    {:ok,
     socket
     |> assign(:feature, feature)
     |> assign(:app, app)
     |> assign(:workspace_id, workspace_id)
     |> assign(:app_id, app_id)
     |> assign(:assignees, assignees)
     |> assign(:statuses, Planner.task_statuses(app, current_workspace))
     |> assign(:icon_search, "")
     |> assign(:icon_preview, nil)
     |> assign(:filtered_icons, AppPlannerWeb.IconHelper.icons() |> Enum.take(24))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    task = Planner.get_task!(id)

    socket
    |> assign(:page_title, "Update Task")
    |> assign(:task, task)
    |> assign(:icon_preview, task.icon)
    |> assign(:form, to_form(Planner.change_task(task)))
  end

  defp apply_action(socket, :new, params) do
    task = %Task{
      feature_id: socket.assigns.feature.id,
      status: params["status"] || "Todo",
      parent_task_id: params["parent_task_id"]
    }

    socket
    |> assign(:page_title, "New Task")
    |> assign(:task, task)
    |> assign(:icon_preview, nil)
    |> assign(:form, to_form(Planner.change_task(task, %{status: task.status})))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-12 px-6">
      <div class="mb-10 flex items-center justify-between">
        <div>
          <div class="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-base-content/30 mb-2">
            <.link
              navigate={
                ~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks"
              }
              class="hover:text-primary transition-colors"
            >
              Board
            </.link>
            <span>/</span>
            <span class="text-base-content/80 font-bold">{@page_title}</span>
          </div>
          <h1 class="text-3xl font-black text-base-content tracking-tight">{@page_title}</h1>
        </div>

        <div class="flex items-center gap-2">
          <.link
            navigate={~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks"}
            class="btn btn-ghost btn-sm rounded-lg border border-base-200 uppercase text-[10px] font-black tracking-widest px-6 transition-all"
          >
            Cancel
          </.link>
          <button
            form="task-form"
            type="submit"
            class="btn btn-primary btn-sm rounded-lg px-8 uppercase text-[10px] font-black tracking-widest shadow-lg shadow-primary/20"
          >
            Save
          </button>
        </div>
      </div>

      <.form
        for={@form}
        id="task-form"
        phx-change="validate"
        phx-submit="save"
        class="space-y-8"
      >
        <div class="bg-base-50/50 border border-base-200 rounded-xl p-8 space-y-8">
          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Task Title
              </span>
            </label>
            <.input
              field={@form[:title]}
              type="text"
              placeholder="What needs to be done?"
              required
              class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div class="form-control">
              <label class="label">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Label
                </span>
              </label>
              <.input
                field={@form[:category]}
                type="text"
                placeholder="e.g. Design, Frontend, Logic"
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
                options={@statuses}
                class="select select-bordered w-full rounded-lg bg-base-100 font-bold"
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Assign To
                </span>
              </label>
              <.input
                field={@form[:assignee_id]}
                type="select"
                options={@assignees}
                prompt="Select an owner"
                class="select select-bordered w-full rounded-lg bg-base-100 font-bold"
              />
            </div>
            <div class="form-control">
              <label class="label">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Due Date
                </span>
              </label>
              <.input
                field={@form[:due_date]}
                type="date"
                class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              />
            </div>

            <div class="form-control">
              <label class="label">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Estimate
                </span>
              </label>
              <.input
                field={@form[:time_estimate]}
                type="text"
                placeholder="e.g. 2h, 1d"
                class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              />
            </div>
          </div>

          <div class="divider opacity-20"></div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Description
              </span>
            </label>
            <.input
              field={@form[:description]}
              type="textarea"
              rows={8}
              placeholder="Detail the task requirements..."
              class="textarea textarea-bordered w-full rounded-lg bg-base-100 font-medium leading-relaxed"
            />
          </div>

          <div class="space-y-4">
            <label class="text-[10px] font-black uppercase tracking-widest text-base-content/40 px-1">
              Visual Marker
            </label>
            <div class="flex items-center gap-6 p-4 bg-base-100 rounded-lg border border-base-200">
              <div class="w-16 h-16 rounded-lg bg-primary/5 text-primary border border-primary/10 flex items-center justify-center shrink-0 shadow-sm">
                <.icon
                  name={if @icon_preview, do: "hero-#{@icon_preview}", else: "hero-bolt"}
                  class="w-8 h-8"
                />
              </div>
              <div class="flex-1 min-w-0">
                <input
                  type="text"
                  phx-keyup="search-icons"
                  placeholder="Filter vectors..."
                  class="input input-sm input-bordered w-full rounded-lg mb-3 bg-base-50 font-bold text-xs"
                />
                <div class="grid grid-cols-6 sm:grid-cols-12 gap-2 max-h-36 overflow-y-auto p-3 bg-base-50 border border-base-200 rounded-lg scrollbar-hidden">
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
            <input type="hidden" name="task[icon]" value={@icon_preview} />
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-4">
          <.link
            navigate={~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks"}
            class="btn btn-ghost rounded-lg uppercase text-[10px] font-black tracking-widest border border-base-200 px-8"
          >
            Cancel
          </.link>
          <button
            type="submit"
            phx-disable-with="Syncing..."
            class="btn btn-primary rounded-lg px-12 uppercase text-[10px] font-black tracking-widest shadow-lg shadow-primary/20"
          >
            Save Task
          </button>
        </div>

        <div class="text-[10px] text-base-content/40 font-bold">
          Supports Markdown: **bold**, *italic*, [link](url), - list
        </div>

        <input type="hidden" name="task[feature_id]" value={@feature.id} />
        <input type="hidden" name="task[parent_task_id]" value={@task.parent_task_id} />
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("search-icons", %{"value" => search}, socket) do
    filtered =
      AppPlannerWeb.IconHelper.icons()
      |> Enum.filter(&String.contains?(String.downcase(&1), String.downcase(search)))
      |> Enum.take(24)

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
  def handle_event("validate", %{"task" => task_params}, socket) do
    task_params = Map.put(task_params, "icon", socket.assigns.icon_preview)

    changeset =
      socket.assigns.task
      |> Planner.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"task" => task_params}, socket) do
    task_params = Map.put(task_params, "icon", socket.assigns.icon_preview)
    save_task(socket, socket.assigns.live_action, task_params)
  end

  defp save_task(socket, :edit, task_params) do
    case Planner.update_task(socket.assigns.task, task_params) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Synchronized: Task metadata updated")
         |> push_navigate(to: board_path(socket))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_task(socket, :new, task_params) do
    user = socket.assigns.current_scope.user

    case Planner.create_task(task_params, user) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task created successfully")
         |> push_navigate(to: board_path(socket))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp board_path(socket) do
    ~p"/workspaces/#{socket.assigns.workspace_id}/apps/#{socket.assigns.app_id}/features/#{socket.assigns.feature.id}/tasks"
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
