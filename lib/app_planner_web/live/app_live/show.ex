defmodule AppPlannerWeb.AppLive.Show do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.breadcrumb items={breadcrumb_items_app_show(@app)} />

      <div class="flex flex-col md:flex-row justify-between items-start gap-6 border-b pb-8 mb-10">
        <div class="flex items-start gap-4">
           <div class="text-primary">
              <.icon name={if @app.icon, do: "hero-#{@app.icon}", else: "hero-cube"} class="w-10 h-10" />
           </div>
           <div>
              <h1 class="text-2xl font-bold flex items-center gap-3">
                {@app.name}
                <span class="text-[10px] uppercase tracking-widest px-2 py-0.5 border rounded-full font-black text-gray-400">
                 <%= if String.contains?( @app.visibility ,"public") do %>
                 <.icon name="hero-globe-alt" class="w-3 h-3" />
                 {@app.visibility}
                 <%else%>
                 <.icon name="hero-lock-closed" class="w-3 h-3" />
                 {@app.visibility}
                 <% end %>
                </span>
              </h1>
              <div class="text-xs text-gray-400 font-bold mt-1">
                {@app.category} • {@app.user.email}
                <span :if={@app.last_updated_by}> • Last updated by {@app.last_updated_by.email}</span>
                <span :if={@app_members && length(@app_members) > 0} class="text-primary" title="Users who can view or edit">
                  • <%= length(@app_members) + 1 %> users have access
                </span>
              </div>
              <div class="flex flex-wrap gap-1 mt-2">
                <%= for label <- @app.labels do %>
                  <span class="text-[9px] px-2 py-0.5 rounded-full font-bold" style={"background-color: #{label.color}22; color: #{label.color}"}>
                    {label.title}
                  </span>
                <% end %>
              </div>
           </div>
        </div>

        <div class="flex items-center gap-4">
          <%!-- Like button: standalone, NOT inside dropdown so click always fires --%>
          <button type="button" phx-click="toggle-like" class={["cursor-pointer px-1 btn-xs shrink-0", if(Planner.liked_by?(@app, @current_user), do: "text-error", else: "text-gray-300")]} title="Like">
            <.icon name={if Planner.liked_by?(@app, @current_user), do: "hero-heart-solid", else: "hero-heart"} class="w-5 h-5 group-hover:scale-110" />
            <span class="text-xs font-black"><%= length(@app.likes || []) %></span>
          </button>
          <%!-- "Liked by" list: separate dropdown, hover on label only --%>
          <div class="dropdown dropdown-hover dropdown-end">
            <label tabindex="0" class="btn btn-ghost btn-sm text-base-content/50 cursor-default text-xs font-bold">
              who liked
            </label>
            <div tabindex="0" class="dropdown-content z-[100] p-3 shadow bg-base-100 rounded-lg border w-52 max-h-[200px] overflow-y-auto">
              <p class="text-[10px] font-black uppercase text-gray-400 mb-2">Liked by</p>
              <%= if Enum.empty?(@app.likes || []) do %>
                <p class="text-xs text-gray-500">No likes yet</p>
              <% else %>
                <ul class="text-xs space-y-1">
                  <%= for like <- @app.likes || [] do %>
                    <li class="truncate">{if Ecto.assoc_loaded?(like.user) && like.user, do: like.user.email, else: "—"}</li>
                  <% end %>
                </ul>
              <% end %>
            </div>
          </div>

          <div class="dropdown dropdown-hover dropdown-end">
            <label tabindex="0" class="btn btn-ghost btn-sm text-base-content/70 cursor-pointer flex items-center gap-2">
              <.icon name="hero-user-group" class="w-5 h-5" />
              <span class="text-xs font-black"><%= length(@app_members) + 1 %></span>
            </label>
            <div tabindex="0" class="dropdown-content z-[100] p-3 shadow bg-base-100 rounded-lg border w-52 max-h-[200px] overflow-y-auto">
              <p class="text-[10px] font-black uppercase text-gray-400 mb-2">Access</p>
              <ul class="text-xs space-y-1.5">
                <li class="truncate flex justify-between gap-2">
                  <span>{@app.user.email}</span>
                  <span class="text-[9px] uppercase text-primary shrink-0">Owner</span>
                </li>
                <%= for m <- @app_members do %>
                  <li class="truncate flex justify-between gap-2">
                    <span>{m.user.email}</span>
                    <span class="text-[9px] uppercase text-base-content/60 shrink-0">{m.role}</span>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>

          <%= if @can_edit do %>
            <.link navigate={~p"/apps/#{@app}/edit?return_to=show"} class="text-xs font-bold text-gray-400 hover:text-primary">Edit</.link>
            <span class="text-gray-200">|</span>
            <.link navigate={~p"/apps/#{@app}/export"} target="_blank" class="text-xs font-bold text-gray-400 hover:text-primary flex items-center gap-1">
              <.icon name="hero-document-text" class="w-3 h-3" /> Export
            </.link>
          <% end %>
          <%= if !@can_edit && !@is_owner && String.downcase(@app.visibility || "") == "public" do %>
            <button phx-click="fork" class="btn btn-sm btn-outline btn-primary">Clone</button>
          <% end %>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-16 mb-16">
         <div class="space-y-8">
            <div class="flex flex-col">
              <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Description</label>
              <.markdown content={@app.description} />
            </div>

            <div class="grid grid-cols-3 gap-8 pt-4 border-t">
              <div class="flex flex-col">
                <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Status</label>
                <span class="text-sm font-bold">
                  <span class="font-bold border rounded-sm px-1 py-[0.5px]"><%= @app.status %></span>
                </span>
              </div>
              <div class="flex flex-col">
                <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Features</label>
                <span class="text-sm font-bold">{length(@app.features)}</span>
              </div>
              <div class="flex flex-col">
                <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Sub-Apps</label>
                <span class="text-sm font-bold">{length(@app.children)}</span>
              </div>
            </div>
         </div>

         <div class="space-y-8">
            <%= if @app.pr_link do %>
              <div class="flex flex-col">
                <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest mb-1">Repository</label>
                <a href={@app.pr_link} target="_blank" class="text-sm font-bold text-primary hover:underline flex items-center gap-2 uppercase tracking-tighter">
                   <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.042-1.416-4.042-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                   Source Code
                </a>
              </div>
            <% end %>

            <%= if @app.custom_fields && map_size(@app.custom_fields) > 0 do %>
              <div class="flex flex-col gap-4">
                 <label class="text-[10px] font-black uppercase text-gray-400 tracking-widest">Technical Metadata</label>
                 <div class="space-y-3 max-h-80 overflow-y-auto">
                   <%= for {key, value} <- @app.custom_fields do %>
                     <div class="flex flex-col border-l-2 border-base-200 pl-3 py-0.5">
                        <span class="text-[9px] font-black uppercase text-gray-400 leading-none mb-1">{key}</span>
                        <div>
                         <%= if String.contains?(value, "http") do %>
                           <a href={value} target="_blank" class="text-primary hover:underline text-xs font-mono font-bold tracking-tight line-clamp-1">{value}</a>
                         <% else %>
                         <span class="text-xs font-mono font-bold tracking-tight line-clamp-1">
                           {value}
                         </span>
                         <% end %>
                        </div>
                     </div>
                   <% end %>
                 </div>
              </div>
            <% end %>
         </div>
      </div>

      <div

      :if={!@app.parent_app_id}
      class="mb-10">
      <!--
      -->
        <div class="flex justify-between items-center border-b pb-2 mb-2">
           <h2 class="text-lg font-bold">Sub-Components</h2>
           <%= if @can_edit do %>
             <.link navigate={~p"/apps/new?parent_app_id=#{@app.id}"} class="text-[10px] font-black uppercase text-primary">+ Add</.link>
           <% end %>
        </div>
        <div class="overflow-x-auto">
          <table class="table table-sm">
            <thead>
              <tr>
                <th class="text-[10px] uppercase text-base-content/60">Name</th>
                <th class="text-[10px] uppercase text-base-content/60">Status</th>
                <th class="text-[10px] uppercase text-base-content/60">Category</th>
                <th class="text-[10px] uppercase text-base-content/60">Labels</th>
              </tr>
            </thead>
            <tbody>
              <%= for child <- @app.children do %>
                <tr phx-click={JS.navigate(~p"/apps/#{child}")} class="cursor-pointer hover:bg-base-200">
                  <td class="font-medium">
                    <div class="flex items-center gap-2">
                      <span class="text-primary">
                        <.icon name={if child.icon, do: "hero-#{child.icon}", else: "hero-cube"} class="w-4 h-4" />
                      </span>
                      {child.name}
                    </div>
                  </td>
                  <td class="text-xs">
                    <span class="font-bold border rounded-sm px-1 py-[0.5px]"><%= child.status %></span>
                  </td>
                  <td class="text-xs text-base-content/70">{child.category}</td>
                  <td>
                    <span :for={l <- child.labels || []} class="text-[9px] px-1.5 py-0.5 rounded mr-0.5" style={"background:#{l.color}22;color:#{l.color}"}>{l.title}</span>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <div class="mb-10">
        <div class="flex justify-between items-center border-b pb-2 mb-2">
           <h2 class="text-lg font-bold">Features</h2>
           <%= if @can_edit do %>
             <.link navigate={~p"/features/new?app_id=#{@app.id}&return_to=app"} class="text-[10px] font-black uppercase text-primary">+ New Feature</.link>
           <% end %>
        </div>
        <div class="overflow-x-auto">
          <table class="table table-sm">
            <thead>
              <tr>
                <th class="text-[10px] uppercase text-base-content/60">Title</th>
                <th class="text-[10px] uppercase text-base-content/60">Description</th>
                <th class="text-[10px] uppercase text-base-content/60">Status</th>
                <th class="text-[10px] uppercase text-base-content/60">Time</th>
                <th class="text-[10px] uppercase text-base-content/60">Date</th>
                <th class="text-[10px] uppercase text-base-content/60">Last updated</th>
                <th class="text-[10px] uppercase text-base-content/60 w-12">Git</th>
              </tr>
            </thead>
            <tbody>
              <%= for feature <- @app.features do %>
                <tr phx-click={JS.navigate(~p"/features/#{feature}")} class="cursor-pointer hover:bg-base-200">
                  <td class="font-medium">
                    <div class="flex items-center gap-2">
                      <span class="text-primary">
                        <.icon name={if feature.icon, do: "hero-#{feature.icon}", else: "hero-bolt"} class="w-4 h-4" />
                      </span>
                      {feature.title}
                    </div>
                  </td>
                  <td class="text-xs max-w-[100px] truncate">{feature.description || "—"}</td>
                  <td class="text-xs">
                    <span class="font-bold border rounded-sm px-1 py-[0.5px]"><%= feature.status %></span>
                  </td>
                  <td class="text-xs">{feature.time_estimate || "—"}</td>
                  <td class="text-xs">{if feature.implementation_date, do: feature.implementation_date, else: "—"}</td>
                  <td class="text-xs text-base-content/70">{if Ecto.assoc_loaded?(feature.last_updated_by) && feature.last_updated_by, do: feature.last_updated_by.email, else: "—"}</td>
                  <td class="text-xs" phx-click-stop>
                    <%= if feature.pr_link && feature.pr_link != "" do %>
                      <a href={feature.pr_link} target="_blank" rel="noopener noreferrer" class="font-black text-primary hover:underline">GIT</a>
                    <% else %>
                      <span class="text-base-content/40">—</span>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        <%= if Enum.empty?(@app.features) do %>
          <p class="py-8 text-center text-sm text-base-content/60">No features yet.</p>
        <% end %>
      </div>

      <%= if @is_owner && is_nil(@app.parent_app_id) && @app.visibility == "private" do %>
        <div class="border-t pt-8">
          <h2 class="text-lg font-bold mb-2">Team access</h2>
          <p class="text-xs text-base-content/60 mb-3">Only the owner can add or remove users. Invite by email so others can view or edit this project.</p>
          <form phx-submit="add-member" class="flex gap-2 mb-4">
            <input type="email" name="member_email" placeholder="user@example.com" class="input input-bordered input-sm flex-1 max-w-xs" required />
            <select name="member_role" class="select select-bordered select-sm w-24">
              <option value="viewer">Viewer</option>
              <option value="editor">Editor</option>
            </select>
            <button type="submit" class="btn btn-sm btn-primary">Add</button>
          </form>
          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th class="text-[10px] uppercase text-base-content/60">Email</th>
                  <th class="text-[10px] uppercase text-base-content/60">Role</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for m <- @app_members do %>
                  <tr>
                    <td class="text-sm">{m.user.email}</td>
                    <td class="text-xs">{m.role}</td>
                    <td>
                      <button type="button" phx-click="remove-member" phx-value-user_id={m.user_id} class="btn btn-ghost btn-xs text-error">Remove</button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  def breadcrumb_items_app_show(app) do
    base = [%{label: "Projects", path: ~p"/apps"}]

    with_parent =
      if app.parent_app_id && app.parent_app do
        base ++ [%{label: app.parent_app.name, path: ~p"/apps/#{app.parent_app_id}"}]
      else
        base
      end

    with_parent ++ [%{label: app.name, path: nil}]
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(AppPlanner.PubSub, "app_updates")
    user = socket.assigns.current_scope.user

    case Planner.get_app(id, user) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "This project is no longer available.")
         |> push_navigate(to: ~p"/apps")}

      app ->
        app_members = Planner.list_app_members(app)

        {:ok,
         socket
         |> assign(:page_title, app.name)
         |> assign(:app, app)
         |> assign(:app_members, app_members)
         |> assign(:current_user, user)
         |> assign(:is_owner, app.user_id == user.id)
         |> assign(:can_edit, Planner.can_edit_app?(app, user))}
    end
  end

  @impl true
  def handle_event("toggle-like", _, socket) do
    user = socket.assigns.current_user || socket.assigns.current_scope.user
    app = socket.assigns.app

    if Planner.liked_by?(app, user) do
      Planner.unlike_app(app.id, user.id)
    else
      Planner.like_app(app.id, user.id)
    end

    case Planner.get_app(app.id, user) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "This project is no longer available.")
         |> push_navigate(to: ~p"/apps")}

      updated_app ->
        {:noreply, assign(socket, app: updated_app)}
    end
  end

  @impl true
  def handle_event("add-member", %{"member_email" => email, "member_role" => role}, socket) do
    user = socket.assigns.current_scope.user
    app = socket.assigns.app
    unless app.user_id == user.id, do: raise("Only the owner can add members")

    case AppPlanner.Accounts.get_user_by_email(String.trim(email)) do
      nil ->
        {:noreply, put_flash(socket, :error, "No user found with that email.")}

      member_user ->
        case Planner.add_app_member(app, member_user, role) do
          {:ok, _} ->
            case Planner.get_app(app.id, user) do
              nil ->
                {:noreply,
                 socket
                 |> put_flash(:error, "This project is no longer available.")
                 |> push_navigate(to: ~p"/apps")}

              refreshed ->
                {:noreply,
                 socket
                 |> put_flash(:info, "Added #{member_user.email}")
                 |> assign(:app, refreshed)
                 |> assign(:app_members, Planner.list_app_members(refreshed))}
            end

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "User already has access.")}
        end
    end
  end

  @impl true
  def handle_event("remove-member", %{"user_id" => user_id}, socket) do
    user = socket.assigns.current_scope.user
    app = socket.assigns.app
    unless app.user_id == user.id, do: raise("Only the owner can remove members")
    Planner.remove_app_member(app, String.to_integer(user_id))

    case Planner.get_app(app.id, user) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "This project is no longer available.")
         |> push_navigate(to: ~p"/apps")}

      refreshed ->
        {:noreply,
         socket
         |> put_flash(:info, "Member removed")
         |> assign(:app, refreshed)
         |> assign(:app_members, Planner.list_app_members(refreshed))}
    end
  end

  @impl true
  def handle_event("fork", _, socket) do
    user = socket.assigns.current_scope.user
    original_app = socket.assigns.app

    cond do
      original_app.user_id == user.id ->
        {:noreply, put_flash(socket, :error, "You already own this project.")}

      String.downcase(original_app.visibility || "") != "public" ->
        {:noreply, put_flash(socket, :error, "Only public projects can be cloned.")}

      true ->
        case Planner.duplicate_app(original_app, user) do
          {:ok, new_app} ->
            {:noreply,
             socket
             |> put_flash(:info, "App cloned successfully!")
             |> push_navigate(to: ~p"/apps/#{new_app}")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not clone app")}
        end
    end
  end

  @impl true
  def handle_info({:app_updated, id}, socket) do
    app = socket.assigns.app

    if app.id == id do
      case Planner.get_app(id, socket.assigns.current_user) do
        nil ->
          {:noreply,
           socket
           |> put_flash(:error, "This project is no longer available.")
           |> push_navigate(to: ~p"/apps")}

        updated_app ->
          {:noreply, assign(socket, app: updated_app)}
      end
    else
      {:noreply, socket}
    end
  end
end
