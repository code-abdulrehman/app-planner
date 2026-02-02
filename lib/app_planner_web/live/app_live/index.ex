defmodule AppPlannerWeb.AppLive.Index do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col md:flex-row justify-between items-end gap-4 mb-8">
        <div>
          <h1 class="text-3xl font-black tracking-tighter">Projects & Frameworks</h1>
          <p class="text-gray-500 text-sm">Manage your software architecture and feature roadmap.</p>
        </div>
        <div class="flex gap-2">
          <.button variant="primary" navigate={~p"/apps/new"} class="p-2 shadow-lg hover:shadow-primary/30 transition-all">
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> New Project
          </.button>
        </div>
      </div>

      <div class="flex gap-8 mb-8 overflow-x-auto border-b">
        <.link patch={~p"/apps?tab=my_apps"}
           class={["pb-2 font-bold transition-all ", @active_tab == :my_apps && "border-b-2 border-primary text-primary", @active_tab != :my_apps && "text-gray-400"]}>
           My Library  <span class="text-[10px] ml-1 bg-base-200 px-1.5 rounded">{@my_apps_count}</span>
        </.link>
        <.link patch={~p"/apps?tab=public_apps"}
           class={["pb-2 font-bold transition-all ", @active_tab == :public_apps && "border-b-2 border-primary text-primary", @active_tab != :public_apps && "text-gray-400"]}>
           Public Assets <span class="text-[10px] ml-1 bg-base-200 px-1.5 rounded">{@public_apps_count}</span>
        </.link>
      </div>

      <input type="text" name="app_search" placeholder="Search by name, category, or status..." phx-keyup="search-apps" phx-debounce="200" value={@app_search} class="input input-bordered input-sm w-full max-w-md mb-4" />

      <div class={[@active_tab != :my_apps && "hidden"]} id="my-apps-list">
        <%= if filter_apps_by_search(@my_apps_list, @app_search) == [] do %>
          <.empty_state
            title={if @app_search == "", do: "No projects yet", else: "No matches found"}
            description={if @app_search == "", do: "Get started by creating your first architectural framework or project specification.", else: "Try adjusting your search or filters to find what you're looking for."}
            icon="hero-cube-transparent"
          >
            <:action :if={@app_search == ""}>
              <.button variant="primary" navigate={~p"/apps/new"} class="shadow-lg">
                <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Create Your First Project
              </.button>
            </:action>
            <:action :if={@app_search != ""}>
              <button phx-click={JS.set_attribute({"value", ""}, to: "input[name='app_search']") |> JS.push("search-apps", value: %{"value" => ""})} class="btn btn-ghost">
                Clear Search
              </button>
            </:action>
          </.empty_state>
        <% else %>
          <div :for={app <- filter_apps_by_search(@my_apps_list, @app_search)} id={"my_apps-#{app.id}"} class="group border-b border-base-200 hover:bg-base-100 transition-all py-4 flex items-center justify-between gap-4">
              <div class="flex items-center gap-4 cursor-pointer flex-1" phx-click={JS.navigate(~p"/apps/#{app}")}>
                 <div class="text-primary opacity-40 group-hover:opacity-100 transition-opacity">
                    <.icon name={if app.icon, do: "hero-#{app.icon}", else: "hero-cube"} class="w-5 h-5" />
                 </div>
                  <div class="flex flex-col">
                    <div class="flex items-center gap-2 flex-wrap">
                      <span class="text-sm font-bold tracking-tight">{app.name}</span>
                      <span class={["text-[9px] uppercase font-black px-1.5 py-0.5 rounded", (app.visibility || "private") == "public" && "bg-primary/20 text-primary", (app.visibility || "private") == "private" && "bg-base-300 text-base-content/60"]}>
                         <%= if String.contains?( app.visibility ,"public") do %>
                            <.icon name="hero-globe-alt" class="w-3 h-3" />
                            {app.visibility}
                            <%else%>
                            <.icon name="hero-lock-closed" class="w-3 h-3" />
                            {app.visibility}
                          <% end %>
                      </span>
                    </div>
                    <div class="flex gap-2 items-center flex-wrap text-[10px] text-gray-400">
                      <span class="uppercase font-black">{app.category}</span>
                      <span>•</span>
                      <span class="font-bold border rounded-sm px-1 py-[0.5px]"><%= app.status %></span>
                      <span>•</span>
                      <span><%= length(app.features) %> Features</span>

                      <%= if app.pr_link do %>
                      <span>•</span>
                        <a href={app.pr_link} target="_blank" class="text-gray-400 hover:text-primary font-black" phx-click-stop>GIT</a>
                      <% end %>
                    </div>
                 </div>
              </div>

              <div class="flex items-center gap-2" phx-click-stop>
                <%!-- Like button: standalone, NOT inside dropdown so click always fires --%>
                <button type="button" phx-click="toggle-like" phx-value-id={app.id} class={[" cursor-pointer px-1 btn-xs shrink-0", if(Planner.liked_by?(app, @current_user), do: "text-error", else: "text-gray-300")]} title="Like">
                  <.icon name={if Planner.liked_by?(app, @current_user), do: "hero-heart-solid", else: "hero-heart"} class="w-4 h-4" />
                  <span class="text-[10px]"><%= length(app.likes || []) %></span>
                </button>

                <div class="dropdown dropdown-hover dropdown-end">
                  <label tabindex="0" class="btn btn-ghost btn-xs text-base-content/70 cursor-pointer">
                    <.icon name="hero-user-group" class="w-4 h-4" />
                    <span class="text-[10px]"><%= length(app.app_members || []) + 1 %></span>
                  </label>
                  <div tabindex="0" class="dropdown-content z-[100] p-3 shadow bg-base-100 rounded-lg border w-52 max-h-[200px] overflow-y-auto">
                    <p class="text-[10px] font-black uppercase text-gray-400 mb-2">Access</p>
                    <ul class="text-xs space-y-1.5">
                      <li class="truncate flex justify-between gap-2">
                        <span>{if app.user, do: app.user.email, else: "—"}</span>
                        <span class="text-[9px] uppercase text-primary shrink-0">Owner</span>
                      </li>
                      <%= for m <- app.app_members || [] do %>
                        <li class="truncate flex justify-between gap-2">
                          <span>{if Ecto.assoc_loaded?(m.user) && m.user, do: m.user.email, else: "—"}</span>
                          <span class="text-[9px] uppercase text-base-content/60 shrink-0">{m.role}</span>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                </div>

                <div class="dropdown dropdown-end">
                  <label tabindex="0" class="btn btn-ghost btn-xs text-gray-400 cursor-pointer">
                    <.icon name="hero-ellipsis-vertical" class="w-4 h-4" />
                  </label>
                  <ul tabindex="0" class="dropdown-content z-[100] menu p-2 shadow bg-base-100 rounded border w-40">
                    <li><.link navigate={~p"/apps/#{app}"}>View</.link></li>
                    <li :if={Planner.can_edit_app?(app, @current_user)}><.link navigate={~p"/apps/#{app}/edit"}>Edit</.link></li>
                    <li :if={app.user_id == @current_user.id}>
                      <.link phx-click={JS.push("delete", value: %{id: app.id})} data-confirm="Delete this project?">
                        <span class="text-error">Delete</span>
                      </.link>
                    </li>
                  </ul>
                </div>
              </div>
          </div>
        <% end %>
      </div>

      <div class={[@active_tab != :public_apps && "hidden"]} id="public-apps-list">
        <%= if filter_apps_by_search(@public_apps_list, @app_search) == [] do %>
          <.empty_state
            title={if @app_search == "", do: "No public assets", else: "No matches found"}
            description={if @app_search == "", do: "Publicly shared frameworks and architectures will appear here for you to explore and clone.", else: "Try adjusting your search or filters to find what you're looking for."}
            icon="hero-globe-alt"
          >
            <:action :if={@app_search != ""}>
              <button phx-click={JS.set_attribute({"value", ""}, to: "input[name='app_search']") |> JS.push("search-apps", value: %{"value" => ""})} class="btn btn-ghost">
                Clear Search
              </button>
            </:action>
          </.empty_state>
        <% else %>
          <div :for={app <- filter_apps_by_search(@public_apps_list, @app_search)} id={"public_apps-#{app.id}"} class="group border-b border-base-200 hover:bg-base-100 transition-all py-4 flex items-center justify-between gap-4">
              <div class="flex items-center gap-4 cursor-pointer flex-1" phx-click={JS.navigate(~p"/apps/#{app}")}>
                 <div class="text-gray-300 group-hover:text-primary transition-colors">
                    <.icon name={if app.icon, do: "hero-#{app.icon}", else: "hero-cube"} class="w-5 h-5" />
                 </div>
                 <div class="flex flex-col">
                    <div class="flex items-center gap-2 flex-wrap">
                      <span class="text-sm font-bold tracking-tight">{app.name}</span>
                      <span class={["text-[9px] uppercase font-black px-1.5 py-0.5 rounded", (app.visibility || "private") == "public" && "bg-primary/20 text-primary", (app.visibility || "private") == "private" && "bg-base-300 text-base-content/60"]}>
                        {app.visibility || "private"}
                      </span>
                    </div>
                    <div class="flex gap-2 items-center flex-wrap text-[9px] text-gray-400">
                      <span class="font-black uppercase tracking-widest">by {app.user.email}</span>
                      <span>•</span>
                      <span class="font-bold">{length(app.features)} features</span>
                      <%= if app.pr_link do %>
                        <a href={app.pr_link} target="_blank" class="text-gray-400 hover:text-primary font-black ml-1" phx-click-stop>GIT</a>
                      <% end %>
                    </div>
                 </div>
              </div>

              <div class="flex items-center gap-3" phx-click-stop>
                <%!-- Like button: standalone, NOT inside dropdown so click always fires --%>
                <button type="button" phx-click="toggle-like" phx-value-id={app.id} class={["btn btn-ghost btn-xs shrink-0", if(Planner.liked_by?(app, @current_user), do: "text-error", else: "text-gray-300")]} title="Like">
                  <.icon name={if Planner.liked_by?(app, @current_user), do: "hero-heart-solid", else: "hero-heart"} class="w-4 h-4" />
                  <span class="text-[10px]"><%= length(app.likes || []) %></span>
                </button>

                <div class="dropdown dropdown-hover dropdown-end">
                  <label tabindex="0" class="btn btn-ghost btn-xs text-base-content/70 cursor-pointer">
                    <.icon name="hero-user-group" class="w-4 h-4" />
                    <span class="text-[10px]"><%= length(app.app_members || []) + 1 %></span>
                  </label>
                  <div tabindex="0" class="dropdown-content z-[100] p-3 shadow bg-base-100 rounded-lg border w-52 max-h-[200px] overflow-y-auto">
                    <p class="text-[10px] font-black uppercase text-gray-400 mb-2">Access</p>
                    <ul class="text-xs space-y-1.5">
                      <li class="truncate flex justify-between gap-2">
                        <span>{if app.user, do: app.user.email, else: "—"}</span>
                        <span class="text-[9px] uppercase text-primary shrink-0">Owner</span>
                      </li>
                      <%= for m <- app.app_members || [] do %>
                        <li class="truncate flex justify-between gap-2">
                          <span>{if Ecto.assoc_loaded?(m.user) && m.user, do: m.user.email, else: "—"}</span>
                          <span class="text-[9px] uppercase text-base-content/60 shrink-0">{m.role}</span>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                </div>

                <%= if app.user_id == @current_user.id do %>
                  <span class="text-[8px] font-black uppercase text-gray-400">Owner</span>
                <% else %>
                  <button phx-click="fork" phx-value-id={app.id} class="btn btn-xs btn-outline btn-primary rounded">Clone</button>
                <% end %>
              </div>
          </div>
        <% end %>
      </div>

    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(AppPlanner.PubSub, "app_updates")
    user = socket.assigns.current_scope.user

    apps = Planner.list_apps(user)

    # My Library: apps I own OR apps shared with me (I'm a member), no parent
    my_apps =
      Enum.filter(apps, fn app ->
        is_nil(app.parent_app_id) and
          (app.user_id == user.id or
             Enum.any?(app.app_members || [], fn m -> m.user_id == user.id end))
      end)

    # Public Library: public apps
    public_apps =
      Enum.filter(
        apps,
        &(String.downcase(&1.visibility || "") == "public" && is_nil(&1.parent_app_id))
      )

    {:ok,
     socket
     |> assign(:page_title, "Listing Apps")
     |> assign(:current_user, user)
     |> assign(:app_search, "")
     |> assign(:my_apps_list, my_apps)
     |> assign(:public_apps_list, public_apps)
     |> assign(:my_apps_count, length(my_apps))
     |> assign(:public_apps_count, length(public_apps))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab =
      case params["tab"] do
        "public_apps" -> :public_apps
        _ -> :my_apps
      end

    user = socket.assigns.current_scope.user
    apps = Planner.list_apps(user)

    my_apps =
      Enum.filter(apps, fn app ->
        is_nil(app.parent_app_id) and
          (app.user_id == user.id or
             Enum.any?(app.app_members || [], fn m -> m.user_id == user.id end))
      end)

    public_apps =
      Enum.filter(
        apps,
        &(String.downcase(&1.visibility || "") == "public" && is_nil(&1.parent_app_id))
      )

    socket =
      socket
      |> assign(:active_tab, tab)
      |> assign(:my_apps_list, my_apps)
      |> assign(:public_apps_list, public_apps)
      |> assign(:my_apps_count, length(my_apps))
      |> assign(:public_apps_count, length(public_apps))

    {:noreply, socket}
  end

  @impl true
  def handle_event("search-apps", %{"value" => value}, socket) do
    {:noreply, assign(socket, :app_search, value || "")}
  end

  @impl true
  def handle_event("stop_propagation", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("change-tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/apps?tab=#{tab}")}
  end

  @impl true
  def handle_event("toggle-like", %{"id" => id}, socket) when is_binary(id) or is_integer(id) do
    user = socket.assigns.current_user || socket.assigns.current_scope.user
    app_id = if is_binary(id), do: String.to_integer(id), else: id
    app = Planner.get_app(app_id, user)

    if app == nil do
      socket = remove_app_from_lists(socket, app_id)

      {:noreply,
       socket
       |> put_flash(:error, "This project is no longer available.")}
    else
      if Planner.liked_by?(app, user) do
        Planner.unlike_app(app.id, user.id)
      else
        Planner.like_app(app.id, user.id)
      end

      updated_app = Planner.get_app(app_id, user)

      if updated_app == nil do
        socket = remove_app_from_lists(socket, app_id)

        {:noreply,
         socket
         |> put_flash(:error, "This project is no longer available.")}
      else
        in_my_library =
          updated_app.user_id == user.id or
            Enum.any?(updated_app.app_members || [], fn m -> m.user_id == user.id end)

        socket =
          if in_my_library do
            my_apps =
              Enum.map(socket.assigns.my_apps_list, fn a ->
                if a.id == updated_app.id, do: updated_app, else: a
              end)

            assign(socket, :my_apps_list, my_apps)
          else
            public_apps =
              Enum.map(socket.assigns.public_apps_list, fn a ->
                if a.id == updated_app.id, do: updated_app, else: a
              end)

            assign(socket, :public_apps_list, public_apps)
          end

        {:noreply, socket}
      end
    end
  end

  def handle_event("toggle-like", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    app_id = if is_binary(id), do: String.to_integer(id), else: id
    app = Planner.get_app(app_id, user)

    if app == nil do
      socket = remove_app_from_lists(socket, app_id)

      {:noreply,
       socket
       |> put_flash(:error, "This project is no longer available.")}
    else
      unless app.user_id == user.id, do: raise("Only the owner can delete this project")
      {:ok, _} = Planner.delete_app(app)
      my_apps = Enum.reject(socket.assigns.my_apps_list, fn a -> a.id == app.id end)

      {:noreply,
       assign(socket, :my_apps_list, my_apps) |> assign(:my_apps_count, length(my_apps))}
    end
  end

  @impl true
  def handle_event("fork", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    app_id = if is_binary(id), do: String.to_integer(id), else: id
    original_app = Planner.get_app(app_id, user)

    if original_app == nil do
      socket = remove_app_from_lists(socket, app_id)

      {:noreply,
       socket
       |> put_flash(:error, "This project is no longer available.")}
    else
      cond do
        original_app.user_id == user.id ->
          {:noreply, put_flash(socket, :error, "You already own this project.")}

        String.downcase(original_app.visibility || "") != "public" ->
          {:noreply, put_flash(socket, :error, "Only public projects can be cloned.")}

        true ->
          case Planner.duplicate_app(original_app, user) do
            {:ok, new_app} ->
              my_apps = [new_app | socket.assigns.my_apps_list]

              {:noreply,
               socket
               |> put_flash(:info, "App cloned successfully!")
               |> assign(:my_apps_list, my_apps)
               |> assign(:my_apps_count, length(my_apps))
               |> push_patch(to: ~p"/apps?tab=my_apps")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to clone app.")}
          end
      end
    end
  end

  @impl true
  def handle_info({:app_updated, id}, socket) do
    user = socket.assigns.current_user || socket.assigns.current_scope.user
    app = Planner.get_app(id, user)

    if app == nil do
      socket = remove_app_from_lists(socket, id)

      {:noreply,
       socket
       |> put_flash(:error, "This project is no longer available.")}
    else
      in_my_library =
        app.user_id == user.id or
          Enum.any?(app.app_members || [], fn m -> m.user_id == user.id end)

      socket =
        if in_my_library do
          my_apps =
            Enum.map(socket.assigns.my_apps_list, fn a -> if a.id == app.id, do: app, else: a end)

          assign(socket, :my_apps_list, my_apps)
        else
          if String.downcase(app.visibility || "") == "public" do
            public_apps =
              Enum.map(socket.assigns.public_apps_list, fn a ->
                if a.id == app.id, do: app, else: a
              end)

            assign(socket, :public_apps_list, public_apps)
          else
            public_apps = Enum.reject(socket.assigns.public_apps_list, fn a -> a.id == app.id end)

            assign(socket, :public_apps_list, public_apps)
            |> assign(:public_apps_count, length(public_apps))
          end
        end

      {:noreply, socket}
    end
  end

  defp remove_app_from_lists(socket, app_id) do
    my_apps = Enum.reject(socket.assigns.my_apps_list, fn a -> a.id == app_id end)
    public_apps = Enum.reject(socket.assigns.public_apps_list, fn a -> a.id == app_id end)

    socket
    |> assign(:my_apps_list, my_apps)
    |> assign(:my_apps_count, length(my_apps))
    |> assign(:public_apps_list, public_apps)
    |> assign(:public_apps_count, length(public_apps))
  end

  def filter_apps_by_search(apps, search) when is_binary(search) do
    q = String.downcase(String.trim(search))

    if q == "" do
      apps
    else
      Enum.filter(apps, fn app ->
        name = String.downcase(app.name || "")
        category = String.downcase(app.category || "")
        status = String.downcase(app.status || "")
        String.contains?(name, q) or String.contains?(category, q) or String.contains?(status, q)
      end)
    end
  end

  def filter_apps_by_search(apps, _), do: apps

  defp empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-20 px-4 text-center bg-base-100/30 border-2 border-dashed border-base-200 rounded-3xl mt-4">
      <div class="w-20 h-20 bg-base-100 rounded-full flex items-center justify-center mb-6 shadow-sm ring-1 ring-base-200">
        <.icon name={@icon} class="w-10 h-10 text-base-content/20" />
      </div>
      <h3 class="text-xl font-black tracking-tight mb-2">{@title}</h3>
      <p class="text-sm text-gray-400 max-w-sm mb-8 leading-relaxed">{@description}</p>
      <div class="flex flex-wrap items-center justify-center gap-4">
        {render_slot(@action)}
      </div>
    </div>
    """
  end
end
