defmodule AppPlannerWeb.TaskLive.Show do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto py-12 px-6">
      <!-- Breadcrumbs -->
      <nav class="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-base-content/30 mb-10 border-b border-base-200 pb-4">
        <.link navigate={~p"/workspaces"} class="hover:text-primary transition-colors">
          Workspace
        </.link>
        <span>/</span>
        <.link
          navigate={~p"/workspaces/#{@current_workspace.id}/apps/#{@task.feature.app_id}"}
          class="hover:text-primary transition-colors"
        >
          Project
        </.link>
        <span>/</span>
        <.link
          navigate={
            ~p"/workspaces/#{@current_workspace.id}/apps/#{@task.feature.app_id}/features/#{@task.feature_id}/tasks"
          }
          class="hover:text-primary transition-colors"
        >
          Board
        </.link>
        <span>/</span>
        <span class="text-base-content/80 font-bold truncate">{@task.title}</span>
      </nav>

      <div class="flex flex-col lg:flex-row justify-between items-start gap-12 mb-16">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-5">
            <div
              :if={@task.icon}
              class="w-16 h-16 rounded-xl bg-primary/10 text-primary border border-primary/20 flex items-center justify-center shadow-sm group"
            >
              <.icon
                name={"hero-#{@task.icon}"}
                class="w-8 h-8 group-hover:scale-110 transition-transform"
              />
            </div>
            <div>
              <div class="flex items-center gap-3 mb-2">
                <span class="text-[9px] font-black uppercase text-primary tracking-widest bg-primary/5 px-2 py-0.5 rounded border border-primary/10">
                  {@task.category || "General Task"}
                </span>
                <span class="text-[9px] font-black uppercase text-base-content/40 tracking-widest px-2 py-0.5 rounded border border-base-200">
                  {@task.status}
                </span>
              </div>
              <h1 class="text-3xl font-black tracking-tight text-base-content leading-tight">
                {@task.title}
              </h1>
            </div>
          </div>

          <div class="flex items-center gap-6 mt-8">
            <div class="flex items-center gap-3">
              <div
                class="w-8 h-8 rounded-lg bg-base-200 border border-base-200 flex items-center justify-center text-[10px] font-black text-base-content/40 uppercase"
                title={if @task.assignee, do: @task.assignee.email, else: "Unassigned"}
              >
                {if @task.assignee,
                  do: String.at(@task.assignee.email, 0) |> String.upcase(),
                  else: "?"}
              </div>
              <span class="text-[10px] font-black uppercase text-base-content/40 tracking-widest">
                {if @task.assignee,
                  do: @task.assignee.email |> String.split("@") |> List.first(),
                  else: "Unassigned"}
              </span>
            </div>
            <div class="h-4 w-px bg-base-200"></div>
            <div class="flex items-center gap-2 text-[10px] font-black uppercase text-base-content/30 tracking-widest">
              <.icon name="hero-calendar" class="w-3.5 h-3.5" />
              {if @task.due_date,
                do: Calendar.strftime(@task.due_date, "%b %d, %Y"),
                else: "No Deadline"}
            </div>
            <div
              :if={@task.time_estimate}
              class="flex items-center gap-2 text-[10px] font-black uppercase text-primary tracking-widest bg-primary/5 px-3 py-1 rounded border border-primary/10"
            >
              <.icon name="hero-bolt" class="w-3.5 h-3.5" />
              {@task.time_estimate}
            </div>
          </div>
        </div>

        <div class="flex items-center gap-2 shrink-0">
          <.link
            navigate={
              ~p"/workspaces/#{@current_workspace.id}/apps/#{@task.feature.app_id}/features/#{@task.feature_id}/tasks/#{@task.id}/edit"
            }
            class="btn btn-outline btn-sm rounded-lg px-6 text-[10px] font-black uppercase tracking-widest border-base-200 hover:bg-base-100 transition-all"
          >
            <.icon name="hero-pencil" class="w-3.5 h-3.5 mr-2" /> Edit
          </.link>
          <button
            phx-click="delete"
            data-confirm="Delete this task?"
            class="btn btn-ghost btn-sm rounded-lg px-3 text-error hover:bg-error/5"
          >
            <.icon name="hero-trash" class="w-4 h-4" /> Delete
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-4 gap-12">
        <div class="lg:col-span-3 space-y-12">
          <section :if={@task.description}>
            <div class="flex items-center gap-3 mb-6">
              <div class="w-7 h-7 rounded bg-base-100 border border-base-200 flex items-center justify-center">
                <.icon name="hero-document-text" class="w-3.5 h-3.5 text-base-content/40" />
              </div>
              <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Task Requirements
              </h3>
            </div>
            <div class="bg-base-50/50 p-8 rounded-xl border border-base-200">
              <div class="prose prose-sm max-w-none text-base-content/70 leading-relaxed font-medium">
                <.markdown content={@task.description} />
              </div>
            </div>
          </section>

          <section>
            <div class="flex items-center justify-between border-b border-base-200 pb-4 mb-8">
              <div class="flex items-center gap-3">
                <div class="w-7 h-7 rounded bg-base-100 border border-base-200 flex items-center justify-center">
                  <.icon name="hero-swatch" class="w-3.5 h-3.5 text-base-content/40" />
                </div>
                <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Nested Components
                </h3>
              </div>
              <.link
                navigate={
                  ~p"/workspaces/#{@current_workspace.id}/apps/#{@task.feature.app_id}/features/#{@task.feature_id}/tasks/new?parent_task_id=#{@task.id}"
                }
                class="text-[10px] font-black uppercase text-primary hover:underline underline-offset-4 tracking-widest"
              >
                Add Sub-task
              </.link>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for subtask <- @task.subtasks do %>
                <.link
                  navigate={
                    ~p"/workspaces/#{@current_workspace.id}/apps/#{@task.feature.app_id}/features/#{@task.feature_id}/tasks/#{subtask.id}"
                  }
                  class="flex items-center justify-between p-4 bg-base-50/50 border border-base-200 rounded-xl hover:border-primary hover:bg-white transition-all group"
                >
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-base-100 border border-base-200 flex items-center justify-center text-base-content/20 group-hover:text-primary transition-colors">
                      <.icon
                        name={if subtask.icon, do: "hero-#{subtask.icon}", else: "hero-bolt"}
                        class="w-4 h-4"
                      />
                    </div>
                    <div class="flex flex-col">
                      <span class="text-xs font-black text-base-content group-hover:text-primary transition-colors">
                        {subtask.title}
                      </span>
                      <span class="text-[9px] font-black uppercase text-base-content/30 tracking-widest">
                        {subtask.status}
                      </span>
                    </div>
                  </div>
                  <.icon
                    name="hero-arrow-right"
                    class="w-3.5 h-3.5 text-base-content/10 group-hover:text-primary transition-all -translate-x-2 opacity-0 group-hover:translate-x-0 group-hover:opacity-100"
                  />
                </.link>
              <% end %>
            </div>

            <div
              :if={Enum.empty?(@task.subtasks)}
              class="py-12 text-center border-2 border-dashed border-base-200 rounded-xl bg-base-50/20"
            >
              <p class="text-[10px] font-black uppercase text-base-content/20 tracking-widest italic">
                No nested sub-tasks defined for this unit.
              </p>
            </div>
          </section>

          <div class="divider opacity-10"></div>
          
    <!-- Discussion -->
          <section class="space-y-8">
            <div class="flex items-center gap-3">
              <div class="w-7 h-7 rounded bg-primary/10 flex items-center justify-center">
                <.icon name="hero-chat-bubble-left-right" class="w-3.5 h-3.5 text-primary" />
              </div>
              <h3 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Discussion
              </h3>
            </div>

            <div class="space-y-4">
              <%= for comment <- @task.comments do %>
                <div class="flex gap-4 group">
                  <div class="w-10 h-10 rounded-lg bg-base-100 border border-base-200 flex items-center justify-center text-[10px] font-black text-base-content/30 uppercase shrink-0">
                    {String.at(comment.user.email, 0) |> String.upcase()}
                  </div>
                  <div class="flex-1 bg-base-50/50 border border-base-200 rounded-xl p-6 relative group/msg">
                    <div class="flex items-center justify-between mb-3">
                      <div class="flex items-center gap-3">
                        <span class="text-[10px] font-black text-base-content/80">
                          {comment.user.email |> String.split("@") |> List.first()}
                        </span>
                        <span class="text-[9px] font-bold text-base-content/20 uppercase">
                          {Calendar.strftime(comment.inserted_at, "%b %d")}
                        </span>
                      </div>

                      <button
                        :if={comment.user_id == @current_scope.user.id}
                        phx-click="delete-comment"
                        phx-value-id={comment.id}
                        class="p-1 text-base-content/10 hover:text-error opacity-0 group-hover/msg:opacity-100 transition-opacity"
                      >
                        <.icon name="hero-x-mark" class="w-3 h-3" />
                      </button>
                    </div>

                    <div class="prose prose-sm text-base-content/70 leading-relaxed font-medium">
                      <.markdown content={comment.content} compact />
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <form
              phx-submit="add-comment"
              class="bg-base-100 p-8 rounded-xl border border-base-200 space-y-4"
            >
              <textarea
                name="content"
                placeholder="Add note..."
                class="textarea textarea-bordered w-full rounded-lg text-sm h-32 bg-base-50 focus:bg-white transition-all font-medium border-base-200"
                required
              ></textarea>
              <div class="flex justify-end">
                <button
                  type="submit"
                  class="btn btn-primary btn-sm rounded-lg px-8 text-[9px] font-black uppercase tracking-widest shadow-lg shadow-primary/20"
                >
                  Post Comment
                </button>
              </div>
            </form>
          </section>
        </div>

        <aside class="space-y-8">
          <div class="bg-base-50/50 border border-base-200 rounded-xl p-6 space-y-8">
            <div>
              <span class="text-[9px] font-black text-base-content/20 uppercase tracking-widest block mb-4">
                Resource linkage
              </span>
              <div class="flex flex-col gap-2">
                <a
                  :if={@task.git_link}
                  href={@task.git_link}
                  target="_blank"
                  class="flex items-center justify-between p-3 bg-white hover:bg-base-200 rounded-lg border border-base-200 group/link transition-all"
                >
                  <div class="flex items-center gap-2">
                    <.icon
                      name="hero-code-bracket"
                      class="w-3.5 h-3.5 text-base-content/30 group-hover/link:text-primary transition-colors"
                    />
                    <span class="text-[9px] font-black uppercase text-base-content/60 tracking-wider">
                      Source
                    </span>
                  </div>
                  <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3 text-base-content/10" />
                </a>
                <div
                  :if={!@task.git_link}
                  class="p-3 rounded-lg border border-dashed border-base-200 text-center italic text-[9px] font-bold text-base-content/20"
                >
                  Unlinked
                </div>
              </div>
            </div>

            <div class="bg-white rounded-lg p-5 border border-base-200 shadow-sm space-y-4">
              <h4 class="text-[9px] font-black uppercase tracking-widest text-base-content/20">
                Metadata
              </h4>
              <div class="space-y-2">
                <div class="flex items-center justify-between p-2 rounded bg-base-50 border border-base-100 text-[9px] font-bold">
                  <span class="text-base-content/40 uppercase">Synced</span>
                  <span class="text-base-content/70">
                    {Calendar.strftime(@task.inserted_at, "%b %y")}
                  </span>
                </div>
                <div class="flex items-center justify-between p-2 rounded bg-base-50 border border-base-100 text-[9px] font-bold">
                  <span class="text-base-content/40 uppercase">Version</span>
                  <span class="text-base-content/70">#{@task.id}</span>
                </div>
              </div>
            </div>
          </div>
        </aside>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id, "workspace_id" => _workspace_id}, _session, socket) do
    current_workspace = socket.assigns.current_workspace

    if is_nil(current_workspace) do
      {:ok, socket |> push_navigate(to: ~p"/workspaces")}
    else
      task = Planner.get_task!(id)

      {:ok,
       socket
       |> assign(:page_title, task.title)
       |> assign(:task, task)
       |> assign(:current_workspace, current_workspace)}
    end
  end

  @impl true
  def handle_event("delete", _, socket) do
    case Planner.delete_task(socket.assigns.task) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task deleted")
         |> push_navigate(to: board_path(socket))}

      _ ->
        {:noreply, socket |> put_flash(:error, "Deletion failed")}
    end
  end

  @impl true
  def handle_event("add-comment", %{"content" => content}, socket) do
    attrs = %{
      content: content,
      task_id: socket.assigns.task.id,
      user_id: socket.assigns.current_scope.user.id
    }

    case Planner.create_task_comment(attrs) do
      {:ok, _comment} ->
        task = Planner.get_task!(socket.assigns.task.id)
        {:noreply, assign(socket, task: task)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not post log")}
    end
  end

  @impl true
  def handle_event("delete-comment", %{"id" => id}, socket) do
    comment = AppPlanner.Repo.get!(AppPlanner.Planner.TaskComment, id)

    if comment.user_id == socket.assigns.current_scope.user.id do
      {:ok, _} = Planner.delete_task_comment(comment)
      task = Planner.get_task!(socket.assigns.task.id)
      {:noreply, assign(socket, task: task)}
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  defp board_path(socket) do
    ~p"/workspaces/#{socket.assigns.current_workspace.id}/apps/#{socket.assigns.task.feature.app_id}/features/#{socket.assigns.task.feature_id}/tasks"
  end
end
