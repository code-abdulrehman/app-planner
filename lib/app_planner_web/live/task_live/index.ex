defmodule AppPlannerWeb.TaskLive.Index do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Workspaces

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_scope.user
    current_workspace = socket.assigns.current_workspace

    cond do
      is_nil(current_workspace) ->
        {:ok, push_navigate(socket, to: ~p"/workspaces")}

      is_nil(params["workspace_id"]) ->
        # Redirect /board to specific workspace board
        {:ok, push_navigate(socket, to: ~p"/workspaces/#{current_workspace.id}/board")}

      is_nil(params["app_id"]) or is_nil(params["feature_id"]) ->
        # Auto-selection logic for /workspaces/:id/board
        workspace_id = params["workspace_id"]
        app_id_param = params["app_id"]

        apps =
          if app_id_param,
            do: [Planner.get_app!(app_id_param, user, workspace_id)],
            else: Planner.list_apps(user, workspace_id)

        case apps do
          [target_app | _] ->
            features = Planner.list_features(user, target_app.id, workspace_id)

            case features do
              [first_feature | _] ->
                {:ok,
                 push_navigate(socket,
                   to:
                     ~p"/workspaces/#{workspace_id}/apps/#{target_app.id}/features/#{first_feature.id}/tasks"
                 )}

              [] ->
                # Create a sample feature if the app exists but has no features
                {:ok, feature} =
                  Planner.create_feature(
                    %{
                      "name" => "Core Assets",
                      "app_id" => target_app.id,
                      "workspace_id" => workspace_id,
                      "description" => "A sample feature to get you started."
                    },
                    user
                  )

                {:ok,
                 push_navigate(socket,
                   to:
                     ~p"/workspaces/#{workspace_id}/apps/#{target_app.id}/features/#{feature.id}/tasks"
                 )}
            end

          [] ->
            # Create a sample app if none exists
            {:ok, app} =
              Planner.create_app(
                %{
                  "name" => "Sample Project",
                  "icon" => "cube",
                  "description" => "Start planning your project here."
                },
                user,
                workspace_id
              )

            {:ok, feature} =
              Planner.create_feature(
                %{
                  "name" => "Core Assets",
                  "app_id" => app.id,
                  "workspace_id" => workspace_id,
                  "description" => "A sample feature to get you started."
                },
                user
              )

            {:ok,
             push_navigate(socket,
               to: ~p"/workspaces/#{workspace_id}/apps/#{app.id}/features/#{feature.id}/tasks"
             )}
        end

      true ->
        assign_metadata(socket, user, current_workspace, params)
    end
  end

  defp assign_metadata(socket, user, current_workspace, params) do
    workspace_id = params["workspace_id"]
    app_id = params["app_id"]
    feature_id = params["feature_id"]

    try do
      # Fetch required data
      feature = if feature_id, do: Planner.get_feature!(feature_id, user, workspace_id), else: nil
      app = if app_id, do: Planner.get_app!(app_id, user, workspace_id), else: nil
      workspace_members = Workspaces.list_workspace_members(workspace_id)
      statuses = Planner.task_statuses(app, current_workspace)

      # For the collapsible navigator
      apps_with_features =
        Planner.list_apps(user, workspace_id)
        |> Enum.map(fn a ->
          %{a | features: Planner.list_features(user, a.id, workspace_id)}
        end)

      assignees = Enum.map(workspace_members, fn m -> {m.user.email, m.user_id} end)

      {:ok,
       socket
       |> assign(:workspace_id, workspace_id)
       |> assign(:app_id, app_id)
       |> assign(:feature, feature)
       |> assign(:app, app)
       |> assign(:apps_with_features, apps_with_features)
       |> assign(:workspace_members, workspace_members)
       |> assign(:assignees, assignees)
       |> assign(:statuses, statuses)
       |> assign(:editing_task_id, nil)
       |> assign(:editing_field, nil)
       |> assign(:inline_add_status, nil)
       |> assign(:inline_add_title, "")
       |> assign(:inline_add_icon, "pencil")
       |> assign(:expanded_apps, MapSet.new([app_id]))
       |> assign(:sidebar_collapsed, false)
       |> fetch_tasks()}
    rescue
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Board location became invalid. Returning home.")
         |> push_navigate(to: ~p"/workspaces")}
    end
  end

  defp fetch_tasks(socket) do
    if feature = socket.assigns.feature do
      tasks = Planner.list_tasks_by_feature(feature.id)
      tasks_by_status = Enum.group_by(tasks, & &1.status)
      assign(socket, tasks_by_status: tasks_by_status)
    else
      assign(socket, tasks_by_status: %{})
    end
  end

  defp board_path(assigns) do
    workspace_id = assigns.workspace_id
    app_id = assigns.app_id
    feature = assigns.feature

    if feature do
      ~p"/workspaces/#{workspace_id}/apps/#{app_id}/features/#{feature.id}/tasks"
    else
      ~p"/workspaces/#{workspace_id}/board"
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> fetch_tasks()}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Tasks Board")
    |> assign(:task, nil)
    |> assign(:form, nil)
  end

  defp apply_action(socket, :new_task, params) do
    task = %AppPlanner.Planner.Task{
      feature_id: socket.assigns.feature.id,
      status: params["status"] || "Todo"
    }

    socket
    |> assign(:page_title, "New Task")
    |> assign(:task, task)
    |> assign(:form, to_form(Planner.change_task(task, %{status: task.status})))
  end

  defp apply_action(socket, :show_task, %{"id" => id}) do
    task = Planner.get_task!(id)

    socket
    |> assign(:page_title, task.title)
    |> assign(:task, task)
    |> assign(:form, to_form(Planner.change_task(task)))
  end

  defp apply_action(socket, :edit_task, %{"id" => id}) do
    task = Planner.get_task!(id)

    socket
    |> assign(:page_title, "Edit #{task.title}")
    |> assign(:task, task)
    |> assign(:icon_preview, task.icon)
    |> assign(:form, to_form(Planner.change_task(task)))
  end

  defp apply_action(socket, :rename_column, %{"status" => status}) do
    socket
    |> assign(:page_title, "Rename Column")
    |> assign(:status_to_rename, status)
    |> assign(:task, nil)
    |> assign(:form, nil)
  end

  defp apply_action(socket, :rename_column, %{}) do
    socket
    |> push_patch(
      to:
        ~p"/workspaces/#{socket.assigns.workspace_id}/apps/#{socket.assigns.app_id}/features/#{socket.assigns.feature.id}/tasks"
    )
  end

  defp apply_action(socket, :add_column, _params) do
    socket
    |> assign(:page_title, "Add Column")
    |> assign(:task, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden bg-base-content/6">
      <!-- Collapsible Sidebar -->
      <aside class={[
        "border-r border-base-200 bg-base-50 flex flex-col shrink-0 transition-all duration-300 ease-in-out overflow-hidden",
        if(@sidebar_collapsed, do: "w-0 opacity-0 border-none", else: "w-72")
      ]}>
        <!-- Sidebar Content -->

        <div class="flex-1 overflow-y-auto p-3 space-y-2 min-w-[18rem]">
          <!-- min-w ensures content doesn't squash during transition -->
          <%= for a <- @apps_with_features do %>
            <div class="space-y-0.5">
              <div
                phx-click="toggle_app"
                phx-value-id={a.id}
                class={[
                  "flex items-center justify-between p-2 rounded-lg cursor-pointer transition-all group",
                  if(to_string(a.id) == to_string(@app_id),
                    do: "bg-primary/5 text-primary",
                    else: "hover:bg-base-200 text-base-content/70"
                  )
                ]}
              >
                <div class="flex items-center gap-2.5">
                  <.icon
                    name={
                      if MapSet.member?(@expanded_apps, to_string(a.id)),
                        do: "hero-chevron-down",
                        else: "hero-chevron-right"
                    }
                    class="w-3 h-3 opacity-40 shrink-0"
                  />
                  <.icon
                    name={if a.icon, do: "hero-#{a.icon}", else: "hero-cube"}
                    class="w-4 h-4 shrink-0"
                  />
                  <span class="text-[11px] font-bold text-base-content/80 truncate w-32">
                    {a.name}
                  </span>
                </div>

                <div
                  class="dropdown dropdown-end"
                  onclick="event.stopPropagation()"
                  text-left
                >
                  <button
                    tabindex="0"
                    class="btn btn-ghost btn-xs w-4 ml-1 opacity-0 group-hover:opacity-100 transition-opacity"
                    onclick="event.stopPropagation()"
                  >
                    <.icon name="hero-ellipsis-horizontal" class="w-3.5 h-3.5" />
                  </button>
                  <ul
                    tabindex="0"
                    class="dropdown-content z-[1] menu p-1 shadow-lg bg-base-100 rounded-lg border border-base-200 text-[10px] font-bold w-40"
                  >
                    <li>
                      <.link navigate={~p"/workspaces/#{@workspace_id}/apps/#{a.id}/edit"}>
                        <.icon name="hero-pencil-square" class="w-3 h-3" /> Edit
                      </.link>
                    </li>
                    <li>
                      <button
                        phx-click="delete_app"
                        phx-value-id={a.id}
                        data-confirm="Delete this project?"
                        class="text-error hover:bg-error/5"
                      >
                        <.icon name="hero-trash" class="w-3 h-3" /> Delete
                      </button>
                    </li>
                  </ul>
                </div>
              </div>

              <div :if={MapSet.member?(@expanded_apps, to_string(a.id))} class="pl-6 space-y-0.5 pb-2">
                <%= for f <- a.features do %>
                  <div class="flex items-center group/feature">
                    <.link
                      navigate={~p"/workspaces/#{@workspace_id}/apps/#{a.id}/features/#{f.id}/tasks"}
                      class={[
                        "flex-1 flex items-center gap-2.5 px-3 py-2 rounded-lg text-[10px] font-medium transition-all border border-transparent truncate",
                        if(@feature && f.id == @feature.id,
                          do: "bg-white shadow-sm border-base-200 text-primary font-bold",
                          else: "text-base-content/50 hover:bg-base-200 hover:text-base-content"
                        )
                      ]}
                    >
                      <.icon
                        name={if f.icon, do: "hero-#{f.icon}", else: "hero-bolt"}
                        class="w-3.5 h-3.5 shrink-0"
                      />
                      <span class="truncate">{f.title}</span>
                    </.link>

                    <div class="dropdown dropdown-end" onclick="event.stopPropagation()" text-left>
                      <button
                        tabindex="0"
                        class="btn btn-ghost btn-xs w-4 ml-1 opacity-0 group-hover/feature:opacity-100 transition-opacity"
                        onclick="event.stopPropagation()"
                      >
                        <.icon name="hero-ellipsis-vertical" class="w-3 h-3" />
                      </button>
                      <ul
                        tabindex="0"
                        class="dropdown-content z-[1] menu p-1 shadow-lg bg-base-100 rounded-lg border border-base-200 text-[10px] font-bold w-40"
                      >
                        <li>
                          <.link navigate={
                            ~p"/workspaces/#{@workspace_id}/apps/#{a.id}/features/#{f.id}/edit"
                          }>
                            <.icon name="hero-pencil" class="w-3 h-3" /> Edit
                          </.link>
                        </li>
                        <li>
                          <button
                            phx-click="delete_feature"
                            phx-value-id={f.id}
                            data-confirm="Delete this module?"
                            class="text-error hover:bg-error/5"
                          >
                            <.icon name="hero-trash" class="w-3 h-3" /> Delete
                          </button>
                        </li>
                      </ul>
                    </div>
                  </div>
                <% end %>
                <.link
                  navigate={~p"/workspaces/#{@workspace_id}/apps/#{a.id}/features/new"}
                  class="flex items-center gap-2.5 px-3 py-2 text-[9px] font-bold text-base-content/30 hover:text-primary transition-colors pl-4"
                >
                  <.icon name="hero-plus-circle" class="w-3.5 h-3.5" /> Add Module
                </.link>
              </div>
            </div>
          <% end %>
          <.link
            navigate={~p"/workspaces/#{@workspace_id}/apps/new"}
            class="btn btn-outline btn-sm btn-block rounded-lg text-[10px] border-base-200 font-bold hover:bg-primary hover:text-white hover:border-primary sticky bottom-0"
          >
            <div class="flex items-center gap-2">
              <.icon name="hero-plus" class="w-3 h-3" /> New Project
            </div>
          </.link>
        </div>
      </aside>

    <!-- Main Content Area -->
      <div class="flex-1 flex flex-col min-w-0">
        <!-- Header -->
        <header class="h-11 border-b border-base-200 bg-base-50 backdrop-blur-md flex flex-col justify-center px-4 sticky top-0 z-30">
          <div class="flex items-center justify-between w-full">
            <div class="flex items-center gap-4">
              <button
                phx-click="toggle_sidebar"
                class="btn btn-ghost btn-sm btn-square text-base-content/50 hover:text-primary transition-colors"
              >
                <.icon
                  name={if @sidebar_collapsed, do: "hero-bars-3", else: "hero-bars-3-bottom-left"}
                  class="w-5 h-5"
                />
              </button>

    <!-- Breadcrumbs -->
              <div :if={@app && @feature} class="hidden md:flex items-center gap-2">
                <span class="text-[10px] font-bold text-base-content/60">{@app.name}</span>
                <span class="text-[9px] text-base-content/10">/</span>
                <span class="text-[10px] font-bold text-base-content">{@feature.title}</span>
              </div>

              <div :if={!(@app && @feature)} class="hidden md:flex items-center gap-2">
                <div class="text-[10px] font-bold text-base-content/30">
                  Select a module from the sidebar
                </div>
              </div>

    <!-- Avatars Group -->
              <div class="flex items-center gap-2 pl-6 border-l border-base-200">
                <div class="flex -space-x-1.5">
                  <%= for member <- Enum.take(@workspace_members, 5) do %>
                    <div
                      class="w-7 h-7 rounded-lg bg-base-100 ring-2 ring-base-100 flex items-center justify-center text-[10px] font-bold text-base-content/40 shadow-sm ring-1 ring-base-200"
                      title={member.user.email}
                    >
                      {String.at(member.user.email, 0) |> String.upcase()}
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="flex items-center gap-8 mt-1">
              <button class="text-[10px] font-bold text-primary border-b-2 border-primary pb-2">
                kanban Board
              </button>
            </div>
          </div>
        </header>
        <!-- Kanban Scroll Area -->
        <div class="flex-1 overflow-x-auto overflow-y-hidden p-4 pt-2 bg-base-100/50 ">
          <%= if is_nil(@feature) do %>
            <div class="h-full flex flex-col items-center justify-center text-center p-20 bg-base-100 rounded-[3rem] border border-base-200 shadow-sm m-8 animate-in fade-in zoom-in duration-700">
              <div class="w-24 h-24 rounded-[2.5rem] bg-gradient-to-tr from-primary/20 to-primary/5 flex items-center justify-center text-primary shadow-2xl shadow-primary/10 ring-8 ring-base-50 mb-10 border border-primary/10">
                <.icon name="hero-command-line" class="w-12 h-12" />
              </div>
              <div class="max-w-md">
                <h3 class="text-3xl font-black text-base-content tracking-tight mb-4">
                  Select Task
                </h3>
                <p class="text-[11px] text-base-content/40 font-bold uppercase tracking-widest mb-10 px-12 leading-relaxed italic">
                  Select a project and its specific module from the sidebar to visualize the board.
                </p>
                <div class="flex items-center justify-center gap-6">
                  <div class="flex flex-col items-center gap-2">
                    <div class="w-10 h-10 rounded-lg bg-base-50 border border-base-200 flex items-center justify-center text-base-content/20 font-bold text-xs">
                      1
                    </div>
                    <span class="text-[9px] font-bold text-base-content/40 uppercase tracking-wider">
                      Select Project
                    </span>
                  </div>
                  <div class="w-12 h-px bg-base-200/50 mb-6"></div>
                  <div class="flex flex-col items-center gap-2">
                    <div class="w-10 h-10 rounded-lg bg-base-50 border border-base-200 flex items-center justify-center text-base-content/20 font-bold text-xs tracking-widest">
                      2
                    </div>
                    <span class="text-[9px] font-bold text-base-content/40 uppercase tracking-wider">
                      Module Board
                    </span>
                  </div>
                </div>
              </div>
            </div>
          <% else %>
            <div id="kanban-columns" phx-hook="SortableColumns" class="flex gap-6 h-[calc(100vh-100px)] min-w-max">
              <%= for status <- @statuses do %>
                <div
                  id={"col-#{String.replace(status, ~r/[^a-zA-Z0-9]/, "-")}"}
                  data-status={status}
                  class="flex-shrink-0 w-80 flex flex-col bg-base-50 border border-base-200 rounded-lg group transition-all h-full shadow-sm"
                >
                  <!-- Column Header -->
                  <div class="p-3 flex items-center justify-between border-b border-base-200 bg-base-100 rounded-t-lg relative">
                    <!-- Status Accent Line -->
                    <div
                      class="absolute top-0 left-0 right-0 h-1 rounded-t-lg transition-all"
                      style={"background-color: #{Planner.status_color(status, @app, @current_workspace)}"}
                    >
                    </div>

                    <div class="flex items-center gap-2.5">
                      <div class="column-handle cursor-grab active:cursor-grabbing text-base-content/40 hover:text-primary transition-colors p-1">
                        <.icon name="hero-bars-3" class="w-4 h-4" />
                      </div>

                      <div class="flex items-center gap-2">
                        <div
                          class="w-2 h-2 rounded-full"
                          style={"background-color: #{Planner.status_color(status, @app, @current_workspace)}"}
                        >
                        </div>
                        <h2 class="text-[10px] font-black uppercase tracking-widest text-base-content/80">
                          {status}
                        </h2>
                      </div>

                      <span class="bg-base-200 text-base-content/60 text-[9px] font-black px-1.5 py-0.5 rounded shadow-inner">
                        {length(Map.get(@tasks_by_status, status, []))}
                      </span>
                    </div>

                    <div class="flex items-center gap-1 p-1 bg-base-100 rounded">
                      <!-- Add Task to Column Button -->
                      <.link
                        navigate={
                          ~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks/new?status=#{status}"
                        }
                        class="btn btn-ghost btn-xs hover:bg-primary/10 hover:text-primary w-5 h-5 flex justify-center items-center"
                        title={"Add task to #{status}"}
                      >
                        <.icon name="hero-plus" class="w-4.5 h-2" />
                      </.link>
                      <div class="w-0.5 h-5 bg-base-200 rounded mx-0.5" />

    <!-- Column Menu -->
                      <div class="dropdown dropdown-end">
                        <button
                          tabindex="0"
                          class="btn btn-ghost btn-xs hover:bg-base-200 w-5 h-5 flex justify-center items-center"
                        >
                          <.icon name="hero-ellipsis-horizontal" class="w-4.5 h-2" />
                        </button>
                        <ul
                          tabindex="0"
                          class="dropdown-content z-[2] menu p-1 shadow-xl bg-base-100 rounded-lg border border-base-200 text-[10px] font-black w-40"
                        >
                          <li>
                            <.link
                              patch={
                                ~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks/rename_column?status=#{status}"
                              }
                              class="hover:bg-primary/5 py-3"
                            >
                              <.icon name="hero-pencil-square" class="w-3.5 h-3.5" /> Rename
                            </.link>
                          </li>
                          <li>
                            <button
                              phx-click="remove_column"
                              phx-value-status={status}
                              class="text-error hover:bg-error/5 py-3"
                              data-confirm="Remove this status? Tasks will be moved to first available column."
                            >
                              <.icon name="hero-trash" class="w-3.5 h-3.5" /> Remove
                            </button>
                          </li>
                        </ul>
                      </div>
                    </div>
                  </div>

                  <div
                    class="flex-1 p-3 space-y-3 overflow-y-auto scrollbar-hidden bg-base-content/4 overflow-x-visible"
                    id={"tasks-#{String.replace(status, ~r/[^a-zA-Z0-9]/, "-")}"}
                    phx-hook="Sortable"
                    data-status={status}
                    data-group="kanban"
                  >
                    <!--
                    <%= if Map.get(@tasks_by_status, status, []) == [] do %>
                      <div class="h-24 border-2 border-dashed border-base-200 rounded-xl flex items-center justify-center text-[10px] font-black uppercase tracking-widest text-base-content/20">
                        Empty
                      </div>
                    <% end %>
                    -->
                    <%= for task <- Map.get(@tasks_by_status, status, []) do %>
                      <div
                        id={"task-#{task.id}"}
                        data-id={task.id}
                        class="bg-base-100 p-4 rounded-lg shadow-sm border border-base-200 hover:border-primary hover:shadow-md transition-all cursor-pointer group/card relative overflow-visible"
                      >
                        <.link
                          patch={
                            ~p"/workspaces/#{@workspace_id}/apps/#{@app_id}/features/#{@feature.id}/tasks/#{task.id}"
                          }
                          class="absolute inset-0 z-0"
                        >
                          <span class="sr-only">View task details</span>
                        </.link>
                        <div class="relative z-10 pointer-events-none">
                          <div class="flex items-start gap-3 mb-3">
                            <div
                              :if={task.icon}
                              class="w-5 h-5 rounded-lg bg-primary/10 flex items-center justify-center border border-primary/20 shrink-0 text-primary pointer-events-auto"
                            >
                              <.icon name={"hero-#{task.icon}"} class="w-2.5 h-2.5" />
                            </div>
                            <div class="flex-1 min-w-0 pointer-events-auto">
                              <%= if @editing_task_id == task.id and @editing_field == "card_title_#{task.id}" do %>
                                <form
                                  id={"card-title-form-#{task.id}"}
                                  phx-submit="save_field"
                                  phx-click-away="cancel_edit"
                                >
                                  <input type="hidden" name="field" value="title" />
                                  <input type="hidden" name="task_id" value={task.id} />
                                  <input
                                    id={"card-title-input-#{task.id}"}
                                    type="text"
                                    name="value"
                                    value={task.title}
                                    class="w-full bg-base-100 border-none focus:ring-0 p-0 text-sm font-bold text-base-content leading-tight"
                                    autofocus
                                    phx-hook="AutoSubmitOnBlur"
                                    data-form-id={"card-title-form-#{task.id}"}
                                  />
                                </form>
                              <% else %>
                                <div
                                  phx-click={
                                    JS.push("edit_field",
                                      value: %{task_id: task.id, field: "card_title_#{task.id}"}
                                    )
                                  }
                                  class="text-sm font-bold text-base-content group-hover/card:text-primary transition-colors leading-tight line-clamp-2 hover:underline cursor-text js-no-drag"
                                >
                                  {task.title}
                                </div>
                              <% end %>
                            </div>
                            <div class="dropdown dropdown-end pointer-events-auto">
                              <button
                                tabindex="0"
                                phx-click={JS.push("no_op")}
                                class="btn btn-ghost btn-xs w-4 ml-1 opacity-0 group-hover/card:opacity-100 transition-opacity hover:bg-base-200"
                              >
                                <.icon
                                  name="hero-ellipsis-vertical"
                                  class="w-4 h-4 text-base-content"
                                />
                              </button>
                              <ul
                                tabindex="0"
                                class="dropdown-content z-[3] menu p-1 shadow-xl bg-base-100 rounded-lg border border-base-200 text-[10px] font-black uppercase w-36"
                              >
                                <li>
                                  <button
                                    phx-click={JS.push("delete_task", value: %{id: task.id})}
                                    data-confirm="Delete this task?"
                                    class="text-error hover:bg-error/5 w-full flex items-center justify-start gap-2 js-no-drag"
                                  >
                                    <.icon name="hero-trash" class="w-3 h-3" /> Delete
                                  </button>
                                </li>
                              </ul>
                            </div>
                          </div>

                          <div class="flex items-center justify-between pt-4 border-t border-base-100 mt-auto pointer-events-auto">
                            <div class="flex items-center gap-2">
                              <span
                                :if={task.category}
                                class="text-[9px] font-bold text-base-content/40 bg-base-100 px-2 py-0.5 rounded"
                              >
                                {task.category}
                              </span>
                              <span
                                :if={task.time_estimate}
                                class="flex items-center gap-1 text-[9px] font-bold text-primary"
                              >
                                <.icon name="hero-clock" class="w-2.5 h-2.5" /> {task.time_estimate}
                              </span>
                              <span
                                :if={task.due_date}
                                class="flex items-center gap-1 text-[9px] font-bold text-orange-600/70"
                              >
                                <.icon name="hero-calendar" class="w-2.5 h-2.5" />
                                {Calendar.strftime(task.due_date, "%b %d")}
                              </span>
                              <a
                                :if={task.git_link && task.git_link != ""}
                                href={task.git_link}
                                target="_blank"
                                class="flex items-center gap-1 text-[9px] font-bold text-base-content/40 hover:text-primary transition-colors"
                              >
                                <.icon name="hero-link" class="w-2.5 h-2.5" />
                              </a>
                              <div
                                :if={length(task.subtasks) > 0}
                                class="flex items-center gap-1 text-[9px] font-bold text-base-content/30 bg-base-50 px-1.5 py-0.5 rounded border border-base-200/50"
                                title={"#{length(task.subtasks)} nested tasks"}
                              >
                                <.icon name="hero-swatch" class="w-2.5 h-2.5" />
                                {length(task.subtasks)}
                              </div>
                            </div>

                            <div class="flex items-center gap-2 relative">
                              <div
                                :if={task.assignee}
                                class="w-6 h-6 rounded-lg bg-primary/10 text-primary border border-primary/20 flex items-center justify-center text-[10px] font-bold shadow-sm cursor-pointer hover:bg-primary/20 transition-all js-no-drag"
                                title={"Assigned to #{task.assignee.email}. Click to change."}
                                phx-click={
                                  JS.push("edit_field",
                                    value: %{task_id: task.id, field: "assignee_id"}
                                  )
                                }
                              >
                                {String.at(task.assignee.email, 0) |> String.upcase()}
                              </div>
                              <div
                                :if={!task.assignee}
                                class="w-6 h-6 rounded-lg bg-base-200 text-base-content/30 border border-base-200 flex items-center justify-center text-[10px] font-bold shadow-sm cursor-pointer hover:bg-base-300 transition-all js-no-drag"
                                title="Unassigned. Click to assign."
                                phx-click={
                                  JS.push("edit_field",
                                    value: %{task_id: task.id, field: "assignee_id"}
                                  )
                                }
                              >
                                <.icon name="hero-user" class="w-3.5 h-3.5" />
                              </div>
                            </div>
                          </div>
                        </div>
                        <%= if @editing_task_id == task.id and @editing_field == "assignee_id" do %>
                          <div
                            class="absolute z-[9999] top-full mt-2 right-0 w-56 bg-base-100 shadow-2xl rounded-2xl border border-base-200 p-2 space-y-1 animate-in slide-in-from-bottom-2 duration-200"
                            phx-click-away="cancel_edit"
                          >
                            <div class="px-3 py-2 text-[9px] font-bold text-base-content/30 border-b border-base-100 mb-1">
                              Assign To
                            </div>
                            <div class="max-h-48 overflow-y-auto scrollbar-hidden">
                              <%= for member <- @workspace_members do %>
                                <button
                                  phx-click={
                                    JS.push("save_field",
                                      value: %{
                                        value: to_string(member.user_id),
                                        field: "assignee_id",
                                        task_id: task.id
                                      }
                                    )
                                  }
                                  class="w-full text-left px-2 py-2 text-[10px] font-bold rounded-xl hover:bg-primary/10 hover:text-primary transition-all flex items-center gap-3 group/member js-no-drag"
                                >
                                  <div class="w-6 h-6 rounded-lg bg-primary/5 group-hover/member:bg-primary/20 flex items-center justify-center text-[9px]">
                                    {String.at(member.user.email, 0) |> String.upcase()}
                                  </div>
                                  <span class="truncate">{member.user.email}</span>
                                </button>
                              <% end %>
                              <button
                                phx-click={
                                  JS.push("save_field",
                                    value: %{field: "assignee_id", value: "", task_id: task.id}
                                  )
                                }
                                class="w-full text-left px-2 py-2 text-[10px] font-bold rounded-xl hover:bg-error/10 hover:text-error transition-all flex items-center gap-3 border-t border-base-100 mt-1 js-no-drag"
                              >
                                <div class="w-6 h-6 rounded-lg bg-error/5 flex items-center justify-center text-[9px]">
                                  <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
                                </div>
                                <span>Remove Assignee</span>
                              </button>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                    </div>
                    <div class="px-1 pb-3 js-no-drag">
                      <%= if @inline_add_status == status do %>
                        <div
                          id={"inline-add-container-#{status |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "-")}"}
                          class="bg-base-100 p-4 rounded-xl shadow-xl border border-primary ring-1 ring-primary/20 space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-300 overflow-visible"
                        >
                          <form
                            id={"inline-add-form-#{status |> String.downcase() |> String.replace(~r/[^a-z0-9]/, "-")}"}
                            phx-submit="save_inline_task"
                            class="space-y-4"
                          >
                            <input type="hidden" name="status" value={status} />

                            <div class="flex items-start gap-2">
                              <div
                                class="w-5 h-5 rounded-lg bg-primary/10 flex items-center justify-center border border-primary/20 shrink-0 text-primary cursor-pointer hover:bg-primary/20 transition-all dropdown dropdown-right"
                                title="Select Icon"
                              >
                                <button
                                  type="button"
                                  tabindex="0"
                                  class="cursor-pointer"
                                >
                                  <.icon
                                    name={
                                      if @inline_add_icon && @inline_add_icon != "",
                                        do: "hero-#{@inline_add_icon}",
                                        else: "hero-pencil"
                                    }
                                    class="w-2.5 h-2.5"
                                  />
                                  <input type="hidden" name="icon" value={@inline_add_icon} />
                                </button>

                                <div
                                    tabindex="0"
                                    class="dropdown-content z-[999] p-2 shadow-2xl bg-base-100 rounded-xl border border-base-200 w-48 mb-2 flex flex-wrap gap-1"
                                  >
                                    <%= for icon <- ~w(rocket-launch sparkles bug-ant bolt star fire heart cube globe-alt cpu-chip light-bulb beaker cloud) do %>
                                      <button
                                        type="button"
                                        phx-click={JS.push("set_inline_icon", value: %{icon: icon})}
                                        class={"p-1.5 rounded-lg hover:bg-primary/10 transition-all #{if @inline_add_icon == icon, do: "bg-primary/20 text-primary", else: "text-base-content/40 hover:text-primary"}"}
                                      >
                                        <.icon name={"hero-#{icon}"} class="w-3 h-3" />
                                      </button>
                                    <% end %>
                                  </div>
                              </div>
                              <div class="flex-1">
                                <input
                                  name="title"
                                  value={@inline_add_title}
                                  placeholder="Type a title..."
                                  class="w-full bg-transparent border-none focus:ring-0 p-0 text-md font-medium text-base-content leading-tight placeholder:text-base-content/20"
                                  autofocus
                                  required
                                  autocomplete="off"
                                />
                              </div>
                            </div>

                            <div class="flex items-center justify-between pt-3 border-t border-base-100">
                              <div class="flex items-center gap-2 flex-1 h-auto">
                                <select
                                  name="assignee_id"
                                  onclick="event.stopPropagation()"
                                  class="pointer-events-auto select select-ghost select-xs bg-base-100/50 hover:bg-base-200 border-none text-[9px] font-black uppercase h-7 px-2 min-h-0 min-w-[100px] rounded-lg"
                                >
                                  <option value="">Unassigned</option>
                                  <%= for member <- @workspace_members do %>
                                    <option value={member.user_id}>{member.user.email}</option>
                                  <% end %>
                                </select>
                                <div class="w-px h-4 bg-base-100 mx-1"></div>
                                <input
                                  type="date"
                                  name="due_date"
                                  class="input input-ghost input-xs bg-base-100/50 hover:bg-base-200 border-none text-[9px] font-black h-7 px-2 min-h-0 rounded-lg w-28"
                                />
                              </div>
                            </div>
                            <div class="flex items-center justify-end w-full">
                              <div class="flex gap-1.5 shadow-sm rounded-lg p-0.5 bg-base-100 border border-base-200 shrink-0">
                                <button
                                  type="submit"
                                  class="btn btn-primary btn-xs font-black uppercase text-[9px] h-7 px-3 rounded-md"
                                >
                                  Add
                                </button>
                                <button
                                  type="button"
                                  phx-click="cancel_inline_add"
                                  class="btn btn-ghost btn-xs font-black uppercase text-[9px] h-7 px-1.5 rounded-md text-base-content/40 hover:text-error"
                                >
                                  <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
                                </button>
                              </div>
                            </div>
                          </form>
                        </div>
                      <% else %>
                        <button
                          phx-click="toggle_inline_add"
                          phx-value-status={status}
                          class="btn btn-ghost btn-xs w-full justify-start text-[10px] font-bold text-base-content/40 hover:text-primary hover:bg-primary/5 border-transparent flex gap-1.5 h-10 px-3 transition-all rounded-xl"
                        >
                          <.icon name="hero-plus" class="w-3.5 h-3.5" />
                          <span>Add Task</span>
                        </button>
                      <% end %>
                    </div>
                </div>
              <% end %>

              <div class="flex-shrink-0 w-80">
                <button
                  phx-click="add_column"
                  class="w-full h-32 border-2 border-dashed border-base-200 rounded-xl flex flex-col items-center justify-center gap-3 text-base-content/20 hover:text-primary hover:border-primary/30 hover:bg-primary/5 transition-all group"
                >
                  <div class="w-10 h-10 rounded-full bg-base-100 flex items-center justify-center border border-base-200 group-hover:border-primary/20 shadow-sm transition-all">
                    <.icon name="hero-plus" class="w-5 h-5" />
                  </div>
                  <span class="text-[10px] font-black uppercase tracking-widest text-base-content/30 group-hover:text-primary">
                    Add Column
                  </span>
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>

    <!-- Modals -->
    <.modal
      :if={@live_action == :add_column}
      id="add-column-modal"
      show
      on_cancel={JS.patch(board_path(assigns))}
    >
      <div class="p-8">
        <div class="flex items-center gap-4 mb-8">
          <div class="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center shadow-inner">
            <.icon name="hero-plus-circle" class="w-6 h-6" />
          </div>
          <div>
            <h3 class="text-xl font-black tracking-tight text-base-content">Add New Column</h3>
            <p class="text-[10px] font-bold text-base-content/40 uppercase tracking-widest text-primary">
              Expand your workflow
            </p>
          </div>
        </div>

        <form phx-submit="save_column_config" class="space-y-6">
          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Column Name
              </span>
            </label>
            <input
              type="text"
              name="name"
              placeholder="e.g. Code Review"
              required
              autofocus
              class="input input-bordered w-full rounded-lg bg-base-50 font-bold"
            />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Column Color
              </span>
            </label>
            <div class="flex items-center gap-4">
              <input
                type="color"
                name="color"
                value="#3b82f6"
                class="w-12 h-12 rounded-lg cursor-pointer border-none bg-transparent p-0"
              />
              <span class="text-[10px] font-bold text-base-content/40 font-mono">#3B82F6</span>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t border-base-200 mt-8">
            <button
              type="button"
              phx-click={JS.patch(board_path(assigns))}
              class="btn btn-ghost rounded-lg px-8 uppercase text-[10px] font-black tracking-widest border border-base-200"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="btn btn-primary rounded-lg px-10 uppercase text-[10px] font-black tracking-widest shadow-lg shadow-primary/20"
            >
              Add Column
            </button>
          </div>
        </form>
      </div>
    </.modal>

    <.modal
      :if={@live_action == :rename_column}
      id="rename-column-modal"
      show
      on_cancel={JS.patch(board_path(assigns))}
    >
      <div class="p-8">
        <div class="flex items-center gap-4 mb-6">
          <div class="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center shadow-inner">
            <.icon name="hero-pencil-square" class="w-6 h-6" />
          </div>
          <div>
            <h3 class="text-xl font-black tracking-tight text-base-content">Rename Column</h3>
            <p class="text-[10px] font-bold text-base-content/40 uppercase tracking-widest text-primary">
              Updating: {@status_to_rename}
            </p>
          </div>
        </div>

        <form phx-submit="save_column_config" class="space-y-6">
          <input type="hidden" name="old_status" value={@status_to_rename} />
          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                New Column Name
              </span>
            </label>
            <input
              type="text"
              name="name"
              value={@status_to_rename}
              required
              autofocus
              placeholder="e.g. In Review"
              class="input input-bordered w-full rounded-lg bg-base-50 font-bold"
            />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Column Color
              </span>
            </label>
            <div class="flex items-center gap-4">
              <input
                type="color"
                name="color"
                value={Planner.status_color(@status_to_rename, @app, @current_workspace)}
                class="w-12 h-12 rounded-lg cursor-pointer border-none bg-transparent p-0"
              />
              <span class="text-[10px] font-bold text-base-content/40 font-mono">
                {Planner.status_color(@status_to_rename, @app, @current_workspace)}
              </span>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t border-base-200 mt-8">
            <button
              type="button"
              phx-click={JS.patch(board_path(assigns))}
              class="btn btn-ghost rounded-lg px-8 uppercase text-[10px] font-black tracking-widest border border-base-200"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="btn btn-primary rounded-lg px-10 uppercase text-[10px] font-black tracking-widest shadow-lg shadow-primary/20"
            >
              Save
            </button>
          </div>
        </form>
      </div>
    </.modal>

    <.modal
      :if={@live_action in [:show_task, :edit_task]}
      box_class="max-w-6xl w-11/12"
      id="task-details-modal"
      show
      on_cancel={JS.patch(board_path(assigns))}
    >
      <div :if={@task} class="flex flex-col h-[90vh] overflow-hidden bg-base-100 rounded-lg">
        <!-- Modal Header -->
        <div class="px-6 py-5 border-b border-base-200 flex items-center justify-between bg-base-50/50">
          <div class="flex items-center gap-4 min-w-0 flex-1">
            <div class="w-10 h-10 rounded-lg bg-primary/10 text-primary flex items-center justify-center shrink-0 shadow-sm border border-primary/20">
              <.icon
                name={if @task.icon, do: "hero-#{@task.icon}", else: "hero-check-circle"}
                class="w-5 h-5"
              />
            </div>
            <div class="min-w-0 flex-1">
              <%= if @editing_task_id == @task.id and @editing_field == "modal-title" do %>
                <form phx-submit="save_field" class="w-full">
                  <input type="hidden" name="field" value="title" />
                  <input
                    type="text"
                    name="value"
                    value={@task.title}
                    class="w-full text-2xl font-black text-base-content bg-transparent border-none focus:ring-0 p-0 leading-tight"
                    autofocus
                  />
                  <div class="flex gap-2 mt-2">
                    <button
                      type="button"
                      class="btn btn-ghost btn-xs text-[10px] uppercase font-black tracking-widest"
                      phx-click="cancel_edit"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="btn btn-primary btn-xs text-[10px] uppercase font-black tracking-widest"
                    >
                      Save
                    </button>
                  </div>
                </form>
              <% else %>
                <h2
                  class="text-2xl font-black text-base-content line-height-[1] line-clamp-2 editable-field transition-colors pr-8 cursor-pointer hover:text-primary"
                  phx-click="edit_field"
                  phx-value-task_id={@task.id}
                  phx-value-field="modal-title"
                >
                  {@task.title}
                </h2>
              <% end %>
            </div>
          </div>
          <!--
          <div class="flex items-center gap-3">
            <button
              type="button"
              class="btn btn-ghost btn-sm btn-circle"
              phx-click={JS.patch(board_path(assigns))}
            >
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </div>
          -->
        </div>
        <!-- Modal Body -->
        <div class="flex-1 overflow-y-auto p-6 scrollbar-hidden">
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Left Side: Content -->
            <div class="lg:col-span-2 space-y-8">
              <!-- Description Section -->
              <div class="space-y-4">
                <div class="flex items-center justify-between">
                  <h3 class="text-[11px] font-black uppercase tracking-widest text-base-content/40 flex items-center gap-2">
                    <.icon name="hero-document-text" class="w-3.5 h-3.5" /> Description
                  </h3>
                </div>

                <div class="group relative bg-base-50/50 rounded-lg p-5 border border-base-200 min-h-[100px] hover:border-primary/30 transition-all">
                  <%= if @editing_task_id == @task.id and @editing_field == "modal-description" do %>
                    <form phx-submit="save_field">
                      <input type="hidden" name="field" value="description" />
                      <textarea
                        id={"task-desc-editor-#{@task.id}"}
                        name="value"
                        class="w-full min-h-[300px] markdown-editor-textarea outline-none resize-y"
                        placeholder="Detailed description (Markdown supported)..."
                        autofocus
                      >{@task.description}</textarea>
                      <div class="flex justify-end gap-2 mt-2">
                        <button
                          type="button"
                          class="btn btn-ghost btn-xs text-[10px] uppercase font-black tracking-widest"
                          phx-click="cancel_edit"
                        >
                          Cancel
                        </button>
                        <button
                          type="submit"
                          class="btn btn-primary btn-xs text-[10px] uppercase font-black tracking-widest px-4"
                        >
                          Save Changes
                        </button>
                      </div>
                    </form>
                  <% else %>
                    <div
                      class="text-base leading-relaxed text-base-content editable-field markdown-content break-words overflow-wrap-anywhere min-h-[200px]"
                      phx-click="edit_field"
                      phx-value-task_id={@task.id}
                      phx-value-field="modal-description"
                    >
                      <%= if @task.description && @task.description != "" do %>
                        {Phoenix.HTML.raw(Earmark.as_html!(@task.description))}
                      <% else %>
                        <span class="text-base-content/30 italic">No description...</span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>

    <!-- Rationale Section -->
              <div class="space-y-4">
                <h3 class="text-[11px] font-black uppercase tracking-widest text-base-content/40 flex items-center gap-2">
                  <.icon name="hero-light-bulb" class="w-3.5 h-3.5" /> Rationale
                </h3>
                <div class="group relative bg-base-50/50 rounded-lg border border-base-200 p-5 hover:border-primary/30 transition-all">
                  <%= if @editing_task_id == @task.id and @editing_field == "modal-rationale" do %>
                    <form phx-submit="save_field">
                      <input type="hidden" name="field" value="rationale" />
                      <textarea
                        id={"task-rationale-editor-#{@task.id}"}
                        name="value"
                        class="w-full min-h-[150px] markdown-editor-textarea p-4 outline-none resize-y"
                        placeholder="Why are we doing this? (Markdown supported)..."
                        autofocus
                      >{@task.rationale}</textarea>
                      <div class="flex justify-end gap-2 mt-2">
                        <button
                          type="button"
                          class="btn btn-ghost btn-xs text-[10px] uppercase font-black tracking-widest"
                          phx-click="cancel_edit"
                        >
                          Cancel
                        </button>
                        <button
                          type="submit"
                          class="btn btn-primary btn-xs text-[10px] uppercase font-black tracking-widest px-4"
                        >
                          Save
                        </button>
                      </div>
                    </form>
                  <% else %>
                    <div
                      phx-click="edit_field"
                      phx-value-task_id={@task.id}
                      phx-value-field="modal-rationale"
                      class="text-base text-base-content/80 editable-field min-h-[1.5em] markdown-content"
                    >
                      <%= if @task.rationale && @task.rationale != "" do %>
                        {Phoenix.HTML.raw(Earmark.as_html!(@task.rationale))}
                      <% else %>
                        <span class="text-base-content/30 italic">Click to add rationale...</span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>

    <!-- Pros & Cons Grid -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-4">
                  <h3 class="text-[11px] font-black uppercase tracking-widest text-success/60 flex items-center gap-2">
                    <.icon name="hero-check-circle" class="w-3.5 h-3.5" /> Pros
                  </h3>
                  <div class="group relative bg-success/5 rounded-lg border border-success/10 p-5 min-h-[100px]">
                    <%= if @editing_task_id == @task.id and @editing_field == "modal-pros" do %>
                      <form phx-submit="save_field">
                        <input type="hidden" name="field" value="pros" />
                        <textarea
                          id={"task-pros-editor-#{@task.id}"}
                          name="value"
                          class="w-full min-h-[100px] markdown-editor-textarea border-success/20 outline-none focus:border-success focus:ring-success/20"
                          placeholder="List benefits..."
                          autofocus
                        >{@task.pros}</textarea>
                        <div class="flex justify-end gap-2 mt-2">
                          <button
                            type="button"
                            class="btn btn-ghost btn-xs text-[10px] uppercase font-black tracking-widest"
                            phx-click="cancel_edit"
                          >
                            Cancel
                          </button>
                          <button
                            type="submit"
                            class="btn btn-primary btn-xs text-[10px] uppercase font-black tracking-widest px-4"
                          >
                            Save
                          </button>
                        </div>
                      </form>
                    <% else %>
                      <div
                        phx-click="edit_field"
                        phx-value-task_id={@task.id}
                        phx-value-field="modal-pros"
                        class="text-sm editable-field markdown-content"
                      >
                        <%= if @task.pros && @task.pros != "" do %>
                          {Phoenix.HTML.raw(Earmark.as_html!(@task.pros))}
                        <% else %>
                          <span class="text-base-content/30 italic">List benefits...</span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>

                <div class="space-y-4">
                  <h3 class="text-[11px] font-black uppercase tracking-widest text-error/60 flex items-center gap-2">
                    <.icon name="hero-x-circle" class="w-3.5 h-3.5" /> Cons
                  </h3>
                  <div class="group relative bg-error/5 rounded-lg border border-error/10 p-5 min-h-[100px]">
                    <%= if @editing_task_id == @task.id and @editing_field == "modal-cons" do %>
                      <form phx-submit="save_field">
                        <input type="hidden" name="field" value="cons" />
                        <textarea
                          id={"task-cons-editor-#{@task.id}"}
                          name="value"
                          class="w-full min-h-[100px] markdown-editor-textarea border-error/20 outline-none focus:border-error focus:ring-error/20"
                          placeholder="List drawbacks..."
                          autofocus
                        >{@task.cons}</textarea>
                        <div class="flex justify-end gap-2 mt-2">
                          <button
                            type="button"
                            class="btn btn-ghost btn-xs text-[10px] uppercase font-black tracking-widest"
                            phx-click="cancel_edit"
                          >
                            Cancel
                          </button>
                          <button
                            type="submit"
                            class="btn btn-primary btn-xs text-[10px] uppercase font-black tracking-widest px-4"
                          >
                            Save
                          </button>
                        </div>
                      </form>
                    <% else %>
                      <div
                        phx-click="edit_field"
                        phx-value-task_id={@task.id}
                        phx-value-field="modal-cons"
                        class="text-sm editable-field markdown-content"
                      >
                        <%= if @task.cons && @task.cons != "" do %>
                          {Phoenix.HTML.raw(Earmark.as_html!(@task.cons))}
                        <% else %>
                          <span class="text-base-content/30 italic">List drawbacks...</span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

    <!-- Strategy & User Flow -->
              <div class="space-y-6">
                <div>
                  <h3 class="text-[11px] font-black uppercase tracking-widest text-base-content/40 mb-3">
                    Strategy
                  </h3>
                  <div class="bg-base-50/50 rounded-lg border border-base-200 p-4">
                    <%= if @editing_task_id == @task.id and @editing_field == "modal-strategy" do %>
                      <form phx-submit="save_field">
                        <input type="hidden" name="field" value="strategy" />
                        <textarea
                          id={"task-strategy-editor-#{@task.id}"}
                          name="value"
                          class="w-full min-h-[120px] markdown-editor-textarea outline-none"
                          placeholder="Define approach..."
                          autofocus
                        >{@task.strategy}</textarea>
                        <div class="flex justify-end gap-2 mt-2">
                          <button
                            type="button"
                            class="btn btn-ghost btn-xs text-[10px] uppercase font-black tracking-widest"
                            phx-click="cancel_edit"
                          >
                            Cancel
                          </button>
                          <button
                            type="submit"
                            class="btn btn-primary btn-xs text-[10px] uppercase font-black tracking-widest px-4"
                          >
                            Save
                          </button>
                        </div>
                      </form>
                    <% else %>
                      <div
                        phx-click="edit_field"
                        phx-value-task_id={@task.id}
                        phx-value-field="modal-strategy"
                        class="text-sm editable-field markdown-content"
                      >
                        <%= if @task.strategy && @task.strategy != "" do %>
                          {Phoenix.HTML.raw(Earmark.as_html!(@task.strategy))}
                        <% else %>
                          <span class="text-base-content/30 italic">Define approach...</span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>

                <div>
                  <h3 class="text-[11px] font-black uppercase tracking-widest text-base-content/40 mb-3">
                    User Flow
                  </h3>
                  <div class="bg-base-50/50 rounded-lg border border-base-200 p-4">
                    <%= if @editing_task_id == @task.id and @editing_field == "modal-user_flow" do %>
                      <form phx-submit="save_field">
                        <input type="hidden" name="field" value="user_flow" />
                        <textarea
                          id={"task-user_flow-editor-#{@task.id}"}
                          name="value"
                          class="w-full min-h-[120px] markdown-editor-textarea p-3 outline-none"
                          placeholder="Describe user journey..."
                          autofocus
                        >{@task.user_flow}</textarea>
                        <div class="flex justify-end gap-2 mt-2">
                          <button
                            type="button"
                            class="btn btn-ghost btn-xs text-[10px] uppercase font-black tracking-widest"
                            phx-click="cancel_edit"
                          >
                            Cancel
                          </button>
                          <button
                            type="submit"
                            class="btn btn-primary btn-xs text-[10px] uppercase font-black tracking-widest px-4"
                          >
                            Save
                          </button>
                        </div>
                      </form>
                    <% else %>
                      <div
                        phx-click="edit_field"
                        phx-value-task_id={@task.id}
                        phx-value-field="modal-user_flow"
                        class="text-sm editable-field markdown-content"
                      >
                        <%= if @task.user_flow && @task.user_flow != "" do %>
                          {Phoenix.HTML.raw(Earmark.as_html!(@task.user_flow))}
                        <% else %>
                          <span class="text-base-content/30 italic">Describe user journey...</span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

    <!-- Comments Section -->
              <div class="divider"></div>
              <div class="space-y-6 pb-20">
                <h3 class="text-sm font-black text-base-content">Comments</h3>
                <div class="space-y-4">
                  <%= for comment <- @task.comments do %>
                    <div class="flex gap-4 p-4 bg-base-50/30 rounded-lg border border-base-200/50">
                      <div class="w-8 h-8 rounded bg-primary/10 flex items-center justify-center text-[10px] font-bold shrink-0">
                        {String.at(comment.user.email, 0) |> String.upcase()}
                      </div>
                      <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-2 mb-1">
                          <span class="text-[11px] font-bold text-base-content">
                            {comment.user.email}
                          </span>
                          <span class="text-[9px] text-base-content/30">
                            {Calendar.strftime(comment.inserted_at, "%b %d, %H:%M")}
                          </span>
                        </div>
                        <div class="text-sm text-base-content/80 leading-relaxed markdown-content">
                          {Phoenix.HTML.raw(Earmark.as_html!(comment.content))}
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>

                <form phx-submit="add_comment" class="space-y-3 rounded-lg border border-base-200">
                  <textarea
                    id={"task-comment-editor-#{@task.id}"}
                    name="content"
                    class="w-full min-h-[100px] markdown-editor-textarea p-3"
                    placeholder="Add a comment (Markdown supported)..."
                    required
                  ></textarea>
                  <div class="flex justify-end">
                    <button
                      type="submit"
                      class="btn btn-primary btn-sm rounded-lg px-6 text-[10px] font-black uppercase tracking-widest"
                    >
                      Post
                    </button>
                  </div>
                </form>
              </div>
            </div>

    <!-- Right Side: Sidebar Metadata -->
            <div class="space-y-6 bg-base-50/30 p-5 rounded-lg border border-base-200/50 h-fit sticky top-0">
              <div class="space-y-5">
                <!-- Status -->
                <div class="space-y-1.5">
                  <label class="text-[10px] font-black uppercase tracking-widest text-base-content/30">
                    Status
                  </label>
                  <div class="relative">
                    <button
                      phx-click="edit_field"
                      phx-value-task_id={@task.id}
                      phx-value-field="modal-status"
                      class="flex items-center justify-between w-full px-4 py-2.5 bg-base-100 rounded-lg border border-base-200 hover:border-primary transition-all text-[10px] font-black uppercase tracking-widest"
                    >
                      <div class="flex items-center gap-2">
                        <span
                          class="w-1.5 h-1.5 rounded-full"
                          style={"background-color: #{Planner.status_color(@task.status, @app, @current_workspace)}"}
                        >
                        </span>
                        {@task.status}
                      </div>
                      <.icon name="hero-chevron-down" class="w-3 h-3 opacity-30" />
                    </button>

                    <%= if @editing_task_id == @task.id and @editing_field == "modal-status" do %>
                      <div
                        class="absolute z-10 top-full mt-1 w-full bg-base-100 shadow-xl rounded-lg border border-base-200 p-1 overflow-hidden"
                        phx-click-away="cancel_edit"
                      >
                        <%= for s <- @statuses do %>
                          <button
                            phx-click={
                              JS.push("save_field",
                                value: %{field: "status", value: s, task_id: @task.id}
                              )
                            }
                            class={[
                              "w-full text-left px-3 py-2 text-[10px] font-black uppercase tracking-widest rounded-md",
                              if(@task.status == s,
                                do: "bg-primary text-primary-content",
                                else: "hover:bg-primary/5"
                              )
                            ]}
                          >
                            {s}
                          </button>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>

    <!-- Assignee -->
                <div class="space-y-1.5">
                  <label class="text-[10px] font-black uppercase tracking-widest text-base-content/30">
                    Assignee
                  </label>
                  <div class="relative">
                    <button
                      phx-click="edit_field"
                      phx-value-task_id={@task.id}
                      phx-value-field="modal-assignee_id"
                      class="flex items-center justify-between w-full px-4 py-2 bg-base-100 rounded-lg border border-base-200 hover:border-primary transition-all"
                    >
                      <div class="flex items-center gap-3 min-w-0">
                        <div class="w-7 h-7 rounded bg-primary/10 text-primary flex items-center justify-center font-black text-[9px] shrink-0">
                          {if @task.assignee,
                            do: String.at(@task.assignee.email, 0) |> String.upcase(),
                            else: "U"}
                        </div>
                        <div class="text-[11px] font-black truncate">
                          {if @task.assignee, do: @task.assignee.email, else: "Unassigned"}
                        </div>
                      </div>
                      <.icon name="hero-chevron-down" class="w-3 h-3 opacity-30" />
                    </button>

                    <%= if @editing_task_id == @task.id and @editing_field == "modal-assignee_id" do %>
                      <div
                        class="absolute z-10 top-full mt-1 w-full bg-base-100 shadow-xl rounded-lg border border-base-200 p-1 max-h-48 overflow-y-auto"
                        phx-click-away="cancel_edit"
                      >
                        <%= for member <- @workspace_members do %>
                          <button
                            phx-click={
                              JS.push("save_field",
                                value: %{
                                  field: "assignee_id",
                                  value: to_string(member.user_id),
                                  task_id: @task.id
                                }
                              )
                            }
                            class={[
                              "w-full text-left px-3 py-2 rounded-md transition-all flex items-center gap-3",
                              if(@task.assignee_id == member.user_id,
                                do: "bg-primary text-primary-content",
                                else: "hover:bg-primary/5"
                              )
                            ]}
                          >
                            <div class="w-5 h-5 rounded bg-base-200 flex items-center justify-center text-[9px] font-bold shrink-0">
                              {String.at(member.user.email, 0) |> String.upcase()}
                            </div>
                            <span class="text-[10px] font-bold truncate tracking-tight">
                              {member.user.email}
                            </span>
                          </button>
                        <% end %>
                        <button
                          phx-click={
                            JS.push("save_field",
                              value: %{field: "assignee_id", value: "", task_id: @task.id}
                            )
                          }
                          class="w-full text-left px-3 py-2 hover:bg-error/10 hover:text-error rounded-md text-[10px] font-bold border-t border-base-100 mt-1"
                        >
                          Remove Assignee
                        </button>
                      </div>
                    <% end %>
                  </div>
                </div>

    <!-- Metadata Grid -->
                <div class="grid grid-cols-2 gap-4">
                  <div class="space-y-1.5">
                    <label class="text-[10px] font-black uppercase tracking-widest text-base-content/30">
                      Estimate
                    </label>
                    <div class="bg-base-100 rounded-lg border border-base-200 px-3 py-2">
                      <%= if @editing_task_id == @task.id and @editing_field == "modal-time_estimate" do %>
                        <form phx-submit="save_field" class="flex flex-col gap-1">
                          <input type="hidden" name="field" value="time_estimate" />
                          <input
                            type="text"
                            name="value"
                            value={@task.time_estimate}
                            class="input input-xs w-full bg-base-100 border border-primary/20 rounded p-1 text-[11px] font-bold"
                            autofocus
                          />
                          <div class="flex justify-end gap-1 mt-1">
                            <button
                              type="button"
                              phx-click="cancel_edit"
                              class="btn btn-ghost btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Cancel
                            </button>
                            <button
                              type="submit"
                              class="btn btn-primary btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Save
                            </button>
                          </div>
                        </form>
                      <% else %>
                        <div
                          phx-click="edit_field"
                          phx-value-task_id={@task.id}
                          phx-value-field="modal-time_estimate"
                          class="text-xs font-bold editable-field min-h-[1.5em] text-primary px-1 cursor-pointer hover:bg-primary/5 rounded transition-colors"
                        >
                          {if @task.time_estimate && @task.time_estimate != "",
                            do: @task.time_estimate,
                            else: "--"}
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <div class="space-y-1.5">
                    <label class="text-[10px] font-black uppercase tracking-widest text-base-content/30">
                      Label
                    </label>
                    <div class="bg-base-100 rounded-lg border border-base-200 px-3 py-2">
                      <%= if @editing_task_id == @task.id and @editing_field == "modal-category" do %>
                        <form phx-submit="save_field" class="flex flex-col gap-1">
                          <input type="hidden" name="field" value="category" />
                          <input
                            type="text"
                            name="value"
                            value={@task.category}
                            class="input input-xs w-full bg-base-100 border border-primary/20 rounded p-1 text-[11px] font-bold"
                            autofocus
                          />
                          <div class="flex justify-end gap-1 mt-1">
                            <button
                              type="button"
                              phx-click="cancel_edit"
                              class="btn btn-ghost btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Cancel
                            </button>
                            <button
                              type="submit"
                              class="btn btn-primary btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Save
                            </button>
                          </div>
                        </form>
                      <% else %>
                        <div
                          phx-click="edit_field"
                          phx-value-task_id={@task.id}
                          phx-value-field="modal-category"
                          class="text-xs font-bold editable-field min-h-[1.5em] text-base-content/60 px-1 cursor-pointer hover:bg-base-content/5 rounded transition-colors"
                        >
                          {if @task.category && @task.category != "", do: @task.category, else: "--"}
                        </div>
                      <% end %>
                    </div>
                  </div>
                  <!-- Dates & Links -->
                  <div class="space-y-4 pt-2 col-span-2">
                    <div class="flex items-center justify-between text-[11px] w-full">
                      <span class="font-bold text-base-content/30 uppercase tracking-widest">
                        Due Date
                      </span>
                      <%= if @editing_task_id == @task.id and @editing_field == "modal-due_date" do %>
                        <form phx-submit="save_field" class="flex flex-col gap-1">
                          <input type="hidden" name="field" value="due_date" />
                          <input
                            type="date"
                            name="value"
                            value={@task.due_date}
                            class="bg-base-100 border border-primary/20 rounded p-1 text-[10px]"
                            autofocus
                          />
                          <div class="flex justify-end gap-1 mt-1">
                            <button
                              type="button"
                              phx-click="cancel_edit"
                              class="btn btn-ghost btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Cancel
                            </button>
                            <button
                              type="submit"
                              class="btn btn-primary btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Save
                            </button>
                          </div>
                        </form>
                      <% else %>
                        <div
                          phx-click="edit_field"
                          phx-value-task_id={@task.id}
                          phx-value-field="modal-due_date"
                          class="font-black text-base-content/60 editable-field px-2 cursor-pointer hover:text-primary transition-colors"
                        >
                          {if @task.due_date, do: @task.due_date, else: "None"}
                        </div>
                      <% end %>
                    </div>

                    <div class="space-y-1.5">
                      <span class="text-[10px] font-black text-base-content/30 uppercase tracking-widest">
                        Git Link
                      </span>
                      <%= if @editing_task_id == @task.id and @editing_field == "modal-git_link" do %>
                        <form phx-submit="save_field" class="flex flex-col gap-1 w-full">
                          <input type="hidden" name="field" value="git_link" />
                          <input
                            type="url"
                            name="value"
                            value={@task.git_link}
                            class="input input-xs w-full bg-base-100 border border-primary/20 rounded p-1 text-[10px]"
                            placeholder="https://github.com/..."
                            autofocus
                          />
                          <div class="flex justify-end gap-1 mt-1">
                            <button
                              type="button"
                              phx-click="cancel_edit"
                              class="btn btn-ghost btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Cancel
                            </button>
                            <button
                              type="submit"
                              class="btn btn-primary btn-[8px] h-auto min-h-0 py-0.5 px-1 uppercase text-[8px] font-black"
                            >
                              Save
                            </button>
                          </div>
                        </form>
                      <% else %>
                        <div
                          phx-click="edit_field"
                          phx-value-task_id={@task.id}
                          phx-value-field="modal-git_link"
                          class="text-[10px] font-bold text-primary truncate editable-field hover:underline px-1"
                        >
                          {if @task.git_link && @task.git_link != "",
                            do: @task.git_link,
                            else: "Add link..."}
                        </div>
                      <% end %>
                    </div>
                  </div>
                  <div class="flex flex-col gap-2 col-span-2">
                    <span class="text-[9px] text-base-content/20 font-bold uppercase">Activity</span>
                    <div class="text-[9px] text-base-content/40 flex justify-between">
                      <span>Created</span>
                      <span>{Calendar.strftime(@task.inserted_at, "%b %d, %Y")}</span>
                    </div>
                    <div class="text-[9px] text-base-content/40 flex justify-between">
                      <span>Updated</span>
                      <span>{Calendar.strftime(@task.updated_at, "%b %d, %Y")}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </.modal>

    <.modal
      :if={@live_action == :new_task}
      id="new-task-modal"
      show
      on_cancel={JS.patch(board_path(assigns))}
    >
      <div class="p-8">
        <div class="flex items-center gap-4 mb-8">
          <div class="w-14 h-14 rounded-2xl bg-primary shadow-lg shadow-primary/20 text-primary-content flex items-center justify-center">
            <.icon name="hero-plus" class="w-8 h-8" />
          </div>
          <div>
            <h3 class="text-2xl font-black tracking-tight text-base-content">
              New Task
            </h3>
            <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
              Planning in {@feature.title}
            </p>
          </div>
        </div>

        <.form
          for={@form}
          phx-submit="save_task"
          phx-change="validate_task"
          class="space-y-6"
        >
          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Task Title
              </span>
            </label>
            <.input
              field={@form[:title]}
              type="text"
              placeholder="e.g. Implement User Authentication"
              class="input input-bordered w-full rounded-xl bg-base-50 font-bold"
              required
              autofocus
            />
          </div>

          <div class="grid grid-cols-2 gap-6">
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
                value={Phoenix.HTML.Form.input_value(@form, :status)}
                class="select select-bordered w-full rounded-xl bg-base-50 font-bold"
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
                prompt="Unassigned"
                value={Phoenix.HTML.Form.input_value(@form, :assignee_id)}
                class="select select-bordered w-full rounded-xl bg-base-50 font-bold"
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
                placeholder="e.g. 2h"
                class="input input-bordered w-full rounded-xl bg-base-50 font-bold"
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
                class="input input-bordered w-full rounded-xl bg-base-50 font-bold"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div class="form-control">
              <label class="label">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Label
                </span>
              </label>
              <.input
                field={@form[:category]}
                type="text"
                placeholder="e.g. Design"
                class="input input-bordered w-full rounded-xl bg-base-50 font-bold"
              />
            </div>
            <div class="form-control">
              <label class="label">
                <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Git Link
                </span>
              </label>
              <.input
                field={@form[:git_link]}
                type="text"
                placeholder="https://github.com/..."
                class="input input-bordered w-full rounded-xl bg-base-50 font-bold"
              />
            </div>
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Details
              </span>
            </label>
            <.input
              field={@form[:description]}
              type="textarea"
              rows={4}
              placeholder="Describe the task details..."
              class="textarea textarea-bordered w-full rounded-lg bg-base-50 font-medium"
            />
          </div>

          <div class="flex justify-end gap-3 pt-6 border-t border-base-100 mt-8">
            <button
              type="button"
              phx-click={JS.patch(board_path(assigns))}
              class="btn btn-ghost rounded-lg text-[10px] font-black uppercase tracking-widest"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="btn btn-primary rounded-lg px-12 text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20"
              phx-disable-with="Syncing..."
            >
              Save Task
            </button>
          </div>
        </.form>
      </div>
    </.modal>
    """
  end

  @impl true
  def handle_event("edit_field", %{"task_id" => task_id, "field" => field}, socket) do
    # task_id might be an integer (from JS.push) or a string (from phx-value)
    task_id_int = if is_binary(task_id), do: String.to_integer(task_id), else: task_id

    {:noreply,
     socket
     |> assign(:editing_task_id, task_id_int)
     |> assign(:editing_field, field)}
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply, socket |> assign(:editing_task_id, nil) |> assign(:editing_field, nil)}
  end

  @impl true
  def handle_event("no_op", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("add_comment", %{"content" => content}, socket) do
    user = socket.assigns.current_scope.user
    task_id = socket.assigns.task.id

    case Planner.create_task_comment(%{
           "content" => content,
           "task_id" => task_id,
           "user_id" => user.id
         }) do
      {:ok, _comment} ->
        {:noreply, assign(socket, :task, Planner.get_task!(task_id))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_field", params, socket) do
    # Extract value safely
    value = Map.get(params, "value")

    # Priority: params["field"] from hidden input > socket.assigns.editing_field
    raw_field = Map.get(params, "field") || socket.assigns.editing_field

    # Priority: params["task_id"] > socket.assigns.editing_task_id > socket.assigns.task.id
    raw_task_id =
      Map.get(params, "task_id") ||
        socket.assigns.editing_task_id ||
        (socket.assigns.task && socket.assigns.task.id)

    user = socket.assigns.current_scope.user

    cond do
      is_nil(raw_field) ->
        # If field identifier is missing (race condition between blur/click-away), ignore safely
        {:noreply, socket |> assign(:editing_task_id, nil) |> assign(:editing_field, nil)}

      is_nil(raw_task_id) ->
        {:noreply, socket |> put_flash(:error, "Could not identify task.")}

      true ->
        try do
          # Parse task_id safely
          task_id =
            if is_binary(raw_task_id), do: String.to_integer(raw_task_id), else: raw_task_id

          # Normalize field name
          field = raw_field |> String.replace("modal-", "")
          # Handle special prefix for inline card title form
          field = if String.starts_with?(field, "card_title_"), do: "title", else: field

          # Fetch task to ensure existence
          task = Planner.get_task!(task_id)

          # specific field handling and type conversion
          final_value =
            cond do
              # Handle empty strings for nullable fields
              (value == "" or value == nil) and
                  field in ["assignee_id", "due_date", "parent_task_id"] ->
                nil

              # Handle integer fields safely
              field in ["assignee_id", "position"] ->
                case value do
                  nil ->
                    nil

                  "" ->
                    nil

                  val when is_integer(val) ->
                    val

                  val when is_binary(val) ->
                    case Integer.parse(val) do
                      {int, _} -> int
                      :error -> nil
                    end

                  _ ->
                    nil
                end

              true ->
                value
            end

          # Create attributes map
          attrs = %{field => final_value}

          case Planner.update_task(task, attrs, user) do
            {:ok, _updated_task} ->
              # Reload fully to get fresh associations (e.g. assignee, comments)
              reloaded_task = Planner.get_task!(task_id)

              # Update the modal task if it's the one being edited
              socket =
                if socket.assigns.task && socket.assigns.task.id == reloaded_task.id do
                  assign(socket, :task, reloaded_task)
                else
                  socket
                end

              {:noreply,
               socket
               |> assign(:editing_task_id, nil)
               |> assign(:editing_field, nil)
               |> assign(:inline_add_status, nil)
               |> fetch_tasks()}

            {:error, changeset} ->
              error_msg =
                changeset.errors
                |> Enum.map_join(", ", fn {k, {msg, _}} -> "#{k} #{msg}" end)

              {:noreply, socket |> put_flash(:error, "Could not update: #{error_msg}")}

            _ ->
              {:noreply, socket |> put_flash(:error, "Could not update field")}
          end
        rescue
          _e ->
            {:noreply, socket |> put_flash(:error, "An error occurred while updating.")}
        end
    end
  end

  @impl true
  def handle_event("validate_task", %{"task" => task_params}, socket) do
    changeset =
      socket.assigns.task
      |> Planner.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_task", %{"task" => task_params}, socket) do
    user = socket.assigns.current_scope.user

    # Determine if we are creating or updating
    result =
      if socket.assigns.task && socket.assigns.task.id do
        # Update existing task
        task = socket.assigns.task
        Planner.update_task(task, task_params, user)
      else
        # Create new task
        task_params = Map.put(task_params, "feature_id", socket.assigns.feature.id)
        Planner.create_task(task_params, user)
      end

    case result do
      {:ok, _task} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           if(socket.assigns.task && socket.assigns.task.id,
             do: "Task Updated",
             else: "Task Created"
           )
         )
         |> push_patch(to: board_path(socket.assigns))
         |> fetch_tasks()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_collapsed, !socket.assigns.sidebar_collapsed)}
  end

  @impl true
  def handle_event("toggle_app", %{"id" => id}, socket) do
    expanded = socket.assigns.expanded_apps
    id_str = to_string(id)

    new_expanded =
      if MapSet.member?(expanded, id_str),
        do: MapSet.delete(expanded, id_str),
        else: MapSet.put(expanded, id_str)

    {:noreply, assign(socket, expanded_apps: new_expanded)}
  end

  @impl true
  def handle_event(
        "reorder",
        %{"id" => id, "to_status" => to_status, "new_index" => new_index},
        socket
      ) do
    # to_status should be the raw status name from data-status
    task = Planner.get_task!(id)

    # new_index might be string or integer
    target_index = if is_binary(new_index), do: String.to_integer(new_index), else: new_index

    case Planner.reposition_task(task, to_status, target_index) do
      {:ok, _} ->
        {:noreply, fetch_tasks(socket)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reorder_columns", %{"status" => status, "new_index" => new_index}, socket) do
    statuses = socket.assigns.statuses
    new_index = if is_binary(new_index), do: String.to_integer(new_index), else: new_index

    # Find where the status was
    old_index = Enum.find_index(statuses, &(&1 == status))

    if old_index && old_index != new_index do
      new_statuses =
        statuses
        |> List.delete_at(old_index)
        |> List.insert_at(new_index, status)

      current_config =
        (socket.assigns.app && socket.assigns.app.status_config) ||
          (socket.assigns.current_workspace && socket.assigns.current_workspace.status_config) ||
          %{}

      # Ensure we merge correctly with existing config (like colors)
      updated_config = Map.put(current_config, "statuses", new_statuses)
      user = socket.assigns.current_scope.user

      result =
        if app = socket.assigns.app do
          app = Planner.get_app!(app.id, user, socket.assigns.workspace_id)
          Planner.update_app(app, %{"status_config" => updated_config}, user)
        else
          workspace = Workspaces.get_workspace!(socket.assigns.current_workspace.id)

          Workspaces.update_workspace(user, workspace, %{
            "status_config" => updated_config
          })
        end

      case result do
        {:ok, updated} ->
          # Update socket to keep data in sync
          socket =
            if socket.assigns.app do
              assign(socket, :app, updated)
            else
              assign(socket, :current_workspace, updated)
            end

          {:noreply, assign(socket, :statuses, new_statuses)}

        {:error, _reason} ->
          {:noreply, socket |> put_flash(:error, "Could not save column order")}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_column", _, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/workspaces/#{socket.assigns.workspace_id}/apps/#{socket.assigns.app_id}/features/#{socket.assigns.feature.id}/tasks/add_column"
     )}
  end

  @impl true
  def handle_event("save_column_config", params, socket) do
    old = params["old_status"]
    new = params["name"]
    color = params["color"]
    user = socket.assigns.current_scope.user

    current_config =
      (socket.assigns.app && socket.assigns.app.status_config) ||
        (socket.assigns.current_workspace && socket.assigns.current_workspace.status_config) ||
        %{}

    statuses = socket.assigns.statuses
    colors = current_config["colors"] || %{}

    {new_statuses, new_colors} =
      if old && old != "" do
        # Rename existing
        updated_statuses = Enum.map(statuses, fn s -> if s == old, do: new, else: s end)
        updated_colors = Map.delete(colors, old) |> Map.put(new, color)

        # Update tasks with the old status
        tasks_to_update = Map.get(socket.assigns.tasks_by_status, old, [])

        Enum.each(tasks_to_update, fn t ->
          Planner.update_task(t, %{status: new}, user)
        end)

        {updated_statuses, updated_colors}
      else
        # Add new
        {statuses ++ [new], Map.put(colors, new, color)}
      end

    new_config =
      Map.put(current_config, "statuses", new_statuses) |> Map.put("colors", new_colors)

    result =
      if socket.assigns.app do
        Planner.update_app(socket.assigns.app, %{"status_config" => new_config}, user)
      else
        Workspaces.update_workspace(user, socket.assigns.current_workspace, %{
          "status_config" => new_config
        })
      end

    case result do
      {:ok, updated_obj} ->
        socket =
          if is_struct(updated_obj, AppPlanner.Planner.App) do
            assign(socket, :app, updated_obj)
          else
            assign(socket, :current_workspace, updated_obj)
          end

        {:noreply,
         socket
         |> assign(:statuses, new_statuses)
         |> assign(
           :app,
           if(is_struct(updated_obj, AppPlanner.Planner.App),
             do: updated_obj,
             else: socket.assigns.app
           )
         )
         |> assign(
           :current_workspace,
           if(is_struct(updated_obj, AppPlanner.Planner.Workspace),
             do: updated_obj,
             else: socket.assigns.current_workspace
           )
         )
         |> fetch_tasks()
         |> put_flash(:info, "Column configuration updated")
         |> push_patch(to: board_path(socket.assigns))}

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not save column configuration")}
    end
  end

  @impl true
  def handle_event("remove_column", %{"status" => status}, socket) do
    statuses = List.delete(socket.assigns.statuses, status)

    # Move tasks in this status to first available status or Todo
    tasks_to_move = Map.get(socket.assigns.tasks_by_status, status, [])
    target_status = if length(statuses) > 0, do: List.first(statuses), else: "Todo"

    Enum.each(tasks_to_move, fn t ->
      Planner.update_task(t, %{status: target_status}, socket.assigns.current_scope.user)
    end)

    current_config =
      (socket.assigns.app && socket.assigns.app.status_config) ||
        (socket.assigns.current_workspace && socket.assigns.current_workspace.status_config) ||
        %{}

    new_colors = Map.delete(current_config["colors"] || %{}, status)
    config = Map.merge(current_config, %{"statuses" => statuses, "colors" => new_colors})

    user = socket.assigns.current_scope.user

    result =
      if socket.assigns.app do
        Planner.update_app(socket.assigns.app, %{"status_config" => config}, user)
      else
        workspace = socket.assigns.current_workspace
        Workspaces.update_workspace(user, workspace, %{"status_config" => config})
      end

    case result do
      {:ok, updated_obj} ->
        socket =
          if is_struct(updated_obj, AppPlanner.Planner.App) do
            assign(socket, :app, updated_obj)
          else
            assign(socket, :current_workspace, updated_obj)
          end

        {:noreply,
         socket
         |> assign(:statuses, statuses)
         |> assign(:inline_add_status, nil)
         |> fetch_tasks()
         |> put_flash(:info, "Column removed")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_app", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    workspace_id = socket.assigns.workspace_id
    app = Planner.get_app!(id, user, workspace_id)

    case Planner.delete_app(app) do
      {:ok, _} ->
        if to_string(app.id) == to_string(socket.assigns.app_id) do
          {:noreply,
           socket
           |> put_flash(:info, "Project deleted")
           |> push_navigate(to: ~p"/workspaces/#{workspace_id}/board")}
        else
          # Reload sidebar
          apps_with_features =
            Planner.list_apps(user, workspace_id)
            |> Enum.map(fn a ->
              %{a | features: Planner.list_features(user, a.id, workspace_id)}
            end)

          {:noreply,
           socket
           |> put_flash(:info, "Project deleted")
           |> assign(apps_with_features: apps_with_features)}
        end

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not delete project")}
    end
  end

  @impl true
  def handle_event("toggle_inline_add", %{"status" => status}, socket) do
    {:noreply, assign(socket, inline_add_status: status, inline_add_title: "")}
  end

  @impl true
  def handle_event("cancel_inline_add", _, socket) do
    {:noreply,
     assign(socket, inline_add_status: nil, inline_add_title: "", inline_add_icon: "pencil")}
  end

  def handle_event("set_inline_icon", %{"icon" => icon}, socket) do
    {:noreply, assign(socket, :inline_add_icon, icon)}
  end

  @impl true
  def handle_event("save_inline_task", params, socket) do
    status = params["status"]
    title = params["title"]
    assignee_id = if params["assignee_id"] == "", do: nil, else: params["assignee_id"]
    user = socket.assigns.current_scope.user

    task_params = %{
      "title" => title,
      "status" => status,
      "assignee_id" => assignee_id,
      "due_date" => params["due_date"],
      "icon" => params["icon"] || socket.assigns.inline_add_icon,
      "feature_id" => socket.assigns.feature.id
    }

    case Planner.create_task(task_params, user) do
      {:ok, _task} ->
        # Clear title and close the form
        {:noreply,
         socket
         |> assign(inline_add_title: "", inline_add_status: nil, inline_add_icon: "pencil")
         |> fetch_tasks()}

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not create task")}
    end
  end

  @impl true
  def handle_event("delete_feature", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    workspace_id = socket.assigns.workspace_id
    feature = Planner.get_feature!(id, user, workspace_id)

    case Planner.delete_feature(feature) do
      {:ok, _} ->
        if to_string(feature.id) == to_string(socket.assigns.feature.id) do
          {:noreply,
           socket
           |> put_flash(:info, "Feature deleted")
           |> push_navigate(to: ~p"/workspaces/#{workspace_id}/apps/#{feature.app_id}")}
        else
          # Reload sidebar
          apps_with_features =
            Planner.list_apps(user, workspace_id)
            |> Enum.map(fn a ->
              %{a | features: Planner.list_features(user, a.id, workspace_id)}
            end)

          {:noreply,
           socket
           |> put_flash(:info, "Feature deleted")
           |> assign(apps_with_features: apps_with_features)}
        end

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not delete feature")}
    end
  end

  @impl true
  def handle_event("delete_task", %{"id" => id}, socket) do
    task = Planner.get_task!(id)

    case Planner.delete_task(task) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task deleted")
         |> fetch_tasks()}

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not delete task")}
    end
  end
end
