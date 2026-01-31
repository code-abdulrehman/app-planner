defmodule AppPlannerWeb.AppLive.Form do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Planner.App
  alias AppPlannerWeb.IconHelper

  # Ensure edit form shows app data: use form value or fall back to app field
  defp edit_value(form, app, field) when is_atom(field) do
    case Phoenix.HTML.Form.input_value(form, field) do
      nil -> Map.get(app, field) |> to_string_edit()
      "" -> Map.get(app, field) |> to_string_edit()
      val -> val
    end
  end

  defp to_string_edit(nil), do: ""
  defp to_string_edit(v), do: to_string(v)

  # For :new use form value so phx-change doesn't clear other fields; for :edit use edit_value
  defp input_display_value(form, app, field, :edit), do: edit_value(form, app, field)
  defp input_display_value(form, _app, field, :new) do
    case Phoenix.HTML.Form.input_value(form, field) do
      v when v in [nil, ""] -> ""
      v -> to_string(v)
    end
  end

  defp filtered_labels_for_modal(labels, search) when is_binary(search) do
    q = String.downcase(String.trim(search))
    if q == "" do
      labels
    else
      Enum.filter(labels, fn l -> String.contains?(String.downcase(l.title || ""), q) end)
    end
  end

  defp filtered_labels_for_modal(labels, _), do: labels

  defp changeset_constraint?(changeset, constraint_name) do
    Enum.any?(changeset.errors, fn
      {_field, {_, opts}} when is_list(opts) -> Keyword.get(opts, :constraint_name) == constraint_name
      _ -> false
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mb-10">
        <div :if={@app.parent_app_id} class="mb-2">
          <.link navigate={~p"/apps/#{@app.parent_app_id}"} class="text-xs font-bold text-gray-400 hover:text-primary flex items-center gap-1">
             <.icon name="hero-arrow-left" class="w-3 h-3" /> Back to {parent_app_name(@app)}
          </.link>
        </div>
        <div :if={!@app.parent_app_id} class="mb-2">
          <.link navigate={~p"/apps"} class="text-xs font-bold text-gray-400 hover:text-primary flex items-center gap-1">
             <.icon name="hero-arrow-left" class="w-3 h-3" /> Back to Projects
          </.link>
        </div>
        <h1 class="text-2xl font-bold mb-1">{@page_title}</h1>
        <p class="text-sm text-base-content/70">Project details and settings.</p>
      </div>

      <.form for={@form} id="app-form" phx-change="validate" phx-submit="save" class="space-y-8">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-10">
          <div class="space-y-6">
            <div class="form-control">
              <label class="label"><span class="label-text font-medium">Name</span></label>
              <.input field={@form[:name]} type="text" placeholder="e.g. My Project" value={input_display_value(@form, @app, :name, @live_action)} class="input input-bordered w-full" />
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label"><span class="label-text font-medium">Status</span></label>
                <.input field={@form[:status]} type="select" options={["Idea", "Planned", "In Progress", "Completed", "Archived"]} value={input_display_value(@form, @app, :status, @live_action)} class="select select-bordered w-full" />
              </div>
              <div class="form-control">
                <label class="label"><span class="label-text font-medium">Visibility</span></label>
                <.input field={@form[:visibility]} type="select" options={[{"Private", "private"}, {"Public", "public"}]} value={input_display_value(@form, @app, :visibility, @live_action)} class="select select-bordered w-full" />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label"><span class="label-text font-medium">Category</span></label>
                <.input field={@form[:category]} type="select" options={@category_options} prompt="Select..." value={input_display_value(@form, @app, :category, @live_action)} class="select select-bordered w-full" />
                <input :if={@category_other} type="text" name="app[category_custom]" placeholder="New category name" value={@category_custom_value} phx-blur="validate" class="input input-bordered input-sm w-full mt-2" />
              </div>
              <div :if={is_nil(@app.parent_app_id) && @live_action == :new} class="form-control">
                <label class="label"><span class="label-text font-medium">Parent project</span></label>
                <.input field={@form[:parent_app_id]} type="select" options={Enum.map(@parent_apps, &{&1.name, &1.id})} prompt="None" class="select select-bordered w-full" />
              </div>
            </div>

            <div class="form-control">
              <label class="label"><span class="label-text font-medium">Description</span></label>
              <.input field={@form[:description]} type="textarea" placeholder="Project details..." value={input_display_value(@form, @app, :description, @live_action)} class="textarea textarea-bordered h-32 w-full" />
            </div>

            <div class="form-control">
               <label class="label">
                 <span class="label-text font-medium">Labels</span>
               </label>
               <div class="flex flex-wrap items-center gap-2">
                 <%= for label <- Enum.filter(@existing_labels, fn l -> l.id in @selected_label_ids end) do %>
                   <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold border-2 transition-shadow"
                         style={"background: #{label.color}18; color: #{label.color}; border-color: #{label.color}"}
                         title={label.description || label.title}>
                     {label.title}
                     <button type="button" phx-click="toggle-label" phx-value-id={label.id} class="hover:opacity-70" aria-label="Remove label">
                       <.icon name="hero-x-mark" class="w-3 h-3" />
                     </button>
                   </span>
                 <% end %>
                 <button type="button" phx-click="open-labels-modal" class="btn btn-ghost btn-sm gap-1 text-primary">
                   <.icon name="hero-plus" class="w-4 h-4" /> Select labels
                 </button>
               </div>
            </div>
          </div>

          <div class="space-y-6">
            <div class="form-control">
              <label class="label"><span class="label-text font-medium">Icon</span></label>
              <div class="flex items-center gap-4 mb-2">
                <div class="w-8 h-8 border border-base-300 rounded-lg flex items-center justify-center bg-base-200">
                  <.icon name={if @icon_preview, do: "hero-#{@icon_preview}", else: "hero-cube"} class="w-6 h-6" />
                </div>
                <div class="flex-1">
                  <input type="text" name="icon_search_query" phx-keyup="search-icons" phx-debounce="200"
                         placeholder="Search icons..." class="input input-bordered w-full input-sm" value={@icon_search} />
                </div>
              </div>
              <div class="grid grid-cols-6 gap-1.5 p-2 border border-base-300 rounded-lg overflow-y-auto max-h-36">
                <input type="hidden" name="app[icon]" value={@icon_preview} />
                <%= for icon <- @filtered_icons do %>
                  <button type="button" phx-click="select-icon" phx-value-icon={icon}
                          class={"btn btn-square btn-sm #{if @icon_preview == icon, do: "btn-primary", else: "btn-ghost"}"}>
                    <.icon name={"hero-#{icon}"} class="w-4 h-4" />
                  </button>
                <% end %>
              </div>
            </div>

            <div class="form-control">
              <label class="label"><span class="label-text font-medium">Repository link</span></label>
              <.input field={@form[:pr_link]} type="text" placeholder="https://github.com/..." value={input_display_value(@form, @app, :pr_link, @live_action)} class="input input-bordered w-full" />
            </div>

            <div class="form-control">
               <label class="label flex flex-wrap items-center justify-between gap-2">
                 <span class="label-text font-medium">Metadata</span>
                 <button type="button" phx-click="add-custom-field" class="link link-primary text-sm">Add field</button>
               </label>
               <div class="space-y-2">
                 <%= for {field, i} <- Enum.with_index(@custom_fields) do %>
                   <div class="flex gap-2 items-start group">
                     <input type="text" name={"custom_fields[#{i}][key]"} value={field["key"]} placeholder="Key" class="input input-bordered input-xs w-1/3 font-black uppercase tracking-tighter" />
                     <input type="text" name={"custom_fields[#{i}][value]"} value={field["value"]} placeholder="Value" class="input input-bordered input-xs flex-1" />
                     <button type="button" phx-click="remove-custom-field" phx-value-index={i} class="btn btn-ghost btn-xs text-error opacity-0 group-hover:opacity-100">×</button>
                   </div>
                 <% end %>
               </div>
            </div>
          </div>
        </div>

        <div class="flex gap-3 pt-6 border-t">
          <.button phx-disable-with="Saving..." class="btn btn-primary">Save</.button>
          <.link navigate={return_path(@return_to, @app)} class="btn btn-ghost">Cancel</.link>
        </div>
      </.form>

      <% # Labels modal: only backdrop click closes so inputs don't close it %>
      <div id="labels-modal" class={["modal", @show_labels_modal && "modal-open"]}>
        <div class="modal-box max-w-lg shadow-xl relative z-10">
          <div class="flex justify-between items-center mb-4">
            <h3 class="font-bold text-lg">Select or create labels</h3>
            <button type="button" phx-click="close-labels-modal" class="btn btn-ghost btn-sm btn-circle" aria-label="Close">
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </div>
          <p class="text-sm text-base-content/70 mb-4">Click a label to toggle. Hover to see description.</p>
          <input type="text" name="label_search" placeholder="Search your labels..." phx-keyup="search-labels" phx-debounce="200" value={@label_search} class="input input-bordered input-sm w-full mb-3" />
          <div class="flex flex-wrap gap-2 mb-6 max-h-40 overflow-y-auto p-1">
            <%= for label <- filtered_labels_for_modal(@existing_labels, @label_search) do %>
              <button type="button" phx-click="toggle-label" phx-value-id={label.id}
                      class={["rounded-full border-2 px-3 py-1.5 text-xs font-semibold transition-all hover:ring-2 hover:ring-offset-2", label.id in @selected_label_ids && "ring-2 ring-primary ring-offset-2"]}
                      style={"background: #{label.color}22; color: #{label.color}; border-color: #{label.color}"}
                      title={label.description || label.title}>
                {label.title}
              </button>
            <% end %>
          </div>
          <div class="border-t border-base-200 pt-4">
            <p class="text-sm font-medium mb-2">Create new label</p>
            <form phx-submit="save-new-label" class="space-y-3">
              <div class="flex gap-2">
                <input type="text" name="new_label[title]" placeholder="Title" class="input input-bordered input-sm flex-1" value={@new_label_title} />
                <input type="color" name="new_label[color]" value={@new_label_color} class="w-9 h-8 rounded cursor-pointer border border-base-300" title="Color" />
              </div>
              <input type="text" name="new_label[description]" placeholder="Description (optional)" class="input input-bordered input-sm w-full" value={@new_label_description} />
              <div class="flex gap-2">
                <button type="submit" class="btn btn-primary btn-sm">Create label</button>
                <p :if={@new_label_error} class="text-error text-sm self-center">{@new_label_error}</p>
              </div>
            </form>
          </div>
          <div class="modal-action">
            <button type="button" phx-click="close-labels-modal" class="btn btn-primary">Done</button>
          </div>
        </div>
        <div class="modal-backdrop bg-black/50 cursor-pointer" phx-click="close-labels-modal" aria-hidden="true"></div>
      </div>

      <% # Team access: only on parent app; only owner can add/remove members %>
      <%= if @live_action == :edit && is_nil(@app.parent_app_id) && @app.visibility == "private" && @is_owner do %>
        <div class="border-t border-base-200 mt-10 pt-8">
          <h2 class="text-lg font-bold mb-1">Team access</h2>
          <p class="text-sm text-base-content/70 mb-3">Only you (owner) can add or remove users. Invite others by email so they can view or edit this project.</p>
          <form phx-submit="add-member" class="flex flex-wrap gap-2 items-end mb-4">
            <input type="email" name="member_email" placeholder="teammate@example.com" class="input input-bordered input-sm w-56" required />
            <select name="member_role" class="select select-bordered select-sm w-24">
              <option value="viewer">Viewer</option>
              <option value="editor">Editor</option>
            </select>
            <button type="submit" class="btn btn-sm btn-primary">Add member</button>
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

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_scope.user

    # Load labels and user's apps for parent selection
    existing_labels = Planner.list_labels(user)
    parent_apps = Enum.filter(Planner.list_apps(user), &(&1.user_id == user.id))

    # Normalize params so "id" works (path params may be string or atom key)
    params = normalize_route_params(params)

    categories = Planner.list_categories()
    category_options = Enum.map(categories, &{&1.name, &1.name}) ++ [{"Other", "__other__"}]

    socket =
      socket
      |> assign(:return_to, return_to(params["return_to"]))
      |> assign(:existing_labels, existing_labels)
      |> assign(:parent_apps, parent_apps)
      |> assign(:categories, categories)
      |> assign(:category_options, category_options)
      |> assign(:category_other, false)
      |> assign(:category_custom_value, "")
      |> assign(:icon_search, "")
      |> assign(:filtered_icons, Enum.take(IconHelper.list_icons(), 12))
      |> assign(:show_labels_modal, false)
      |> assign(:label_search, "")
      |> assign(:new_label_title, "")
      |> assign(:new_label_color, "#3b82f6")
      |> assign(:new_label_description, "")
      |> assign(:new_label_error, nil)
      |> apply_action(socket.assigns.live_action, params, user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # When navigating to edit, reload app and form so fields show existing data
    params = normalize_route_params(params)
    id = params["id"]

    case {socket.assigns.live_action, id} do
      {:edit, id} when is_binary(id) and id != "" ->
        user = socket.assigns.current_scope.user
        {:noreply, apply_action(socket, :edit, params, user)}

      _ ->
        {:noreply, socket}
    end
  end

  defp normalize_route_params(params) when is_map(params) do
    id = Map.get(params, "id") || Map.get(params, :id)
    if id, do: Map.put(params, "id", to_string(id)), else: params
  end

  defp normalize_route_params(params), do: params || %{}

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, params, user) do
    raw_id = params["id"] || params[:id]
    raw_id || raise "edit action requires id in params"
    id = if is_binary(raw_id), do: String.to_integer(raw_id), else: raw_id

    app = Planner.get_app!(id, user)
    categories = Planner.list_categories()
    category_options = Enum.map(categories, &{&1.name, &1.name}) ++ [{"Other", "__other__"}]
    socket = socket |> assign(:categories, categories) |> assign(:category_options, category_options)

    custom_fields =
      Enum.map(app.custom_fields || %{}, fn {k, v} ->
        %{"key" => to_string(k), "value" => to_string(v)}
      end)

    selected_label_ids = Enum.map(app.labels, & &1.id)
    category_other_edit = app.category && !Enum.any?(categories, fn c -> c.name == app.category end)
    initial_params = app_to_form_params(app)
    initial_params = if category_other_edit, do: Map.put(initial_params, "category", "__other__"), else: initial_params
    form =
      app
      |> Planner.change_app(initial_params)
      |> to_form()

    category_other = category_other_edit
    category_custom_value = if category_other, do: app.category || "", else: ""

    app_members = Planner.list_app_members(app)
    is_owner = app.user_id == user.id

    socket
    |> assign(:page_title, "Edit " <> (app.name || "Project"))
    |> assign(:app, app)
    |> assign(:app_members, app_members)
    |> assign(:is_owner, is_owner)
    |> assign(:custom_fields, custom_fields)
    |> assign(:selected_label_ids, selected_label_ids)
    |> assign(:category_other, category_other)
    |> assign(:category_custom_value, category_custom_value)
    |> assign(:show_labels_modal, false)
    |> assign(:label_search, "")
    |> assign(:new_label_params, %{})
    |> assign(:new_label_title, "")
    |> assign(:new_label_color, "#3b82f6")
    |> assign(:new_label_description, "")
    |> assign(:new_label_error, nil)
    |> assign(:icon_preview, app.icon)
    |> assign(:last_app_params, initial_params)
    |> assign(:form, form)
  end

  defp apply_action(socket, :new, params, user) do
    parent_app_id =
      case params["parent_app_id"] || params["app_id"] do
        nil -> nil
        id -> String.to_integer(id)
      end

    app = %App{custom_fields: %{}, parent_app_id: parent_app_id}
    # Preload parent app for breadcrumb
    app =
      if parent_app_id, do: %{app | parent_app: Planner.get_app!(parent_app_id, user)}, else: app

    socket
    |> assign(:page_title, "New Project")
    |> assign(:app, app)
    |> assign(:app_members, [])
    |> assign(:is_owner, true)
    |> assign(:custom_fields, [])
    |> assign(:selected_label_ids, [])
    |> assign(:show_labels_modal, false)
    |> assign(:new_label_title, "")
    |> assign(:new_label_color, "#3b82f6")
    |> assign(:new_label_description, "")
    |> assign(:new_label_error, nil)
    |> assign(:icon_preview, nil)
    |> assign(:label_search, "")
    |> assign(:last_app_params, app_to_form_params(app))
    |> assign(:form, to_form(Planner.change_app(app)))
  end

  @impl true
  def handle_event("validate", params, socket) do
    incoming = params["app"] || %{}
    target = params["_target"] || []
    # Only update the field that triggered phx-change so empty unfocused fields don't overwrite
    app_params = merge_app_params(socket, incoming, target)
    category = app_params["category"]
    category_other = category == "__other__"
    category_custom_value = app_params["category_custom"] || socket.assigns[:category_custom_value] || ""
    app_params = if category_other && category_custom_value != "", do: Map.put(app_params, "category", String.trim(category_custom_value)), else: app_params
    app_params = if socket.assigns[:icon_preview], do: Map.put(app_params, "icon", socket.assigns.icon_preview), else: app_params
    custom_fields_params = Map.get(params, "custom_fields", %{})

    custom_fields =
      custom_fields_params
      |> Enum.sort_by(fn {k, _} ->
        case Integer.parse(k) do
          {i, _} -> i
          :error -> k
        end
      end)
      |> Enum.map(fn {_, v} -> v end)

    selected_label_ids =
      case params["label_ids"] || params["label_ids[]"] do
        nil -> socket.assigns.selected_label_ids
        [] -> socket.assigns.selected_label_ids
        ids -> List.wrap(ids) |> Enum.map(&String.to_integer/1)
      end

    changeset = Planner.change_app(socket.assigns.app, app_params)

    # If icon search query is present in params, update it
    icon_search = Map.get(params, "icon_search_query", socket.assigns.icon_search)

    # Capture new label params if present
    new_label = params["new_label"]

    socket =
      socket
      |> assign(:custom_fields, custom_fields)
      |> assign(:selected_label_ids, selected_label_ids)
      |> assign(:category_other, category_other)
      |> assign(:category_custom_value, category_custom_value)
      |> assign(:new_label_params, new_label)
      |> assign(:icon_search, icon_search)
      |> assign(:icon_preview, app_params["icon"] || socket.assigns.icon_preview)
      |> assign(:last_app_params, app_params)
      |> assign(:form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("search-icons", %{"value" => search}, socket) do
    all_icons = IconHelper.list_icons()
    search_lower = String.downcase(search || "")

    filtered =
      if search_lower == "" do
        top = Enum.take(all_icons, 12)

        if socket.assigns.icon_preview && socket.assigns.icon_preview not in top do
          [socket.assigns.icon_preview | top] |> Enum.uniq()
        else
          top
        end
      else
        matches = all_icons |> Enum.filter(&String.contains?(&1, search_lower))

        results =
          if socket.assigns.icon_preview &&
               String.contains?(socket.assigns.icon_preview, search_lower) do
            [socket.assigns.icon_preview | matches] |> Enum.uniq()
          else
            matches
          end

        Enum.take(results, 30)
      end

    {:noreply, assign(socket, icon_search: search, filtered_icons: filtered)}
  end

  def handle_event("select-icon", %{"icon" => icon}, socket) do
    {:noreply, assign(socket, icon_preview: icon)}
  end

  def handle_event("open-labels-modal", _, socket) do
    {:noreply, assign(socket, show_labels_modal: true)}
  end

  def handle_event("close-labels-modal", _, socket) do
    {:noreply, assign(socket, show_labels_modal: false)}
  end

  def handle_event("search-labels", %{"value" => value}, socket) do
    {:noreply, assign(socket, label_search: value || "")}
  end

  def handle_event("toggle-label", %{"id" => id}, socket) do
    id = String.to_integer(id)
    current = socket.assigns.selected_label_ids
    selected = if id in current, do: List.delete(current, id), else: [id | current]
    {:noreply, assign(socket, selected_label_ids: selected)}
  end

  def handle_event("save-new-label", params, socket) do
    raw = params["new_label"]
    new_label_params = if is_map(raw), do: raw, else: %{}
    title = (new_label_params["title"] || new_label_params[:title] || "") |> to_string() |> String.trim()
    raw_color = new_label_params["color"] || new_label_params[:color] || "#3b82f6"
    color = raw_color |> to_string() |> String.trim() |> then(&(if &1 == "", do: "#3b82f6", else: &1))
    description = (new_label_params["description"] || "") |> to_string() |> String.trim()

    if title == "" do
      {:noreply,
       socket
       |> assign(:new_label_error, "Title is required.")
       |> assign(:new_label_title, title)
       |> assign(:new_label_color, color)
       |> assign(:new_label_description, description)}
    else
      attrs = %{"title" => title, "color" => color, "description" => (description != "" && description) || nil}
      user = socket.assigns.current_scope.user

      case Planner.create_label(attrs, user) do
        {:ok, label} ->
          existing_labels = socket.assigns.existing_labels ++ [label]
          selected_label_ids = socket.assigns.selected_label_ids ++ [label.id]

          {:noreply,
           socket
           |> assign(:existing_labels, existing_labels)
           |> assign(:selected_label_ids, selected_label_ids)
           |> assign(:new_label_title, "")
           |> assign(:new_label_color, "#3b82f6")
           |> assign(:new_label_description, "")
           |> assign(:new_label_error, nil)
           |> put_flash(:info, "Label added.")}

        {:error, %Ecto.Changeset{} = changeset} ->
          error_msg =
            if changeset_constraint?(changeset, :labels_user_id_title_index) do
              "A label with this name already exists."
            else
              changeset
              |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
              |> Enum.flat_map(fn {_field, msgs} -> msgs end)
              |> List.first() || "Could not create label."
            end

          {:noreply,
           socket
           |> assign(:new_label_error, error_msg)
           |> assign(:new_label_title, title)
           |> assign(:new_label_color, color)
           |> assign(:new_label_description, description)}
      end
    end
  end

  def handle_event("add-custom-field", _, socket) do
    custom_fields = socket.assigns.custom_fields ++ [%{"key" => "", "value" => ""}]
    {:noreply, assign(socket, :custom_fields, custom_fields)}
  end

  def handle_event("remove-custom-field", %{"index" => index}, socket) do
    index = String.to_integer(index)
    custom_fields = List.delete_at(socket.assigns.custom_fields, index)
    {:noreply, assign(socket, :custom_fields, custom_fields)}
  end

  def handle_event("add-member", %{"member_email" => email, "member_role" => role}, socket) do
    user = socket.assigns.current_scope.user
    app = socket.assigns.app
    unless app.user_id == user.id, do: raise "Only the owner can add members"
    case AppPlanner.Accounts.get_user_by_email(String.trim(email)) do
      nil ->
        {:noreply, put_flash(socket, :error, "No user found with that email. They must register first.")}
      member_user ->
        case Planner.add_app_member(app, member_user, role) do
          {:ok, _} ->
            app_members = Planner.list_app_members(app)
            {:noreply,
             socket
             |> put_flash(:info, "Added #{member_user.email}")
             |> assign(:app_members, app_members)}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "User already has access.")}
        end
    end
  end

  def handle_event("remove-member", %{"user_id" => user_id}, socket) do
    user = socket.assigns.current_scope.user
    app = socket.assigns.app
    unless app.user_id == user.id, do: raise "Only the owner can remove members"
    Planner.remove_app_member(app, String.to_integer(user_id))
    app_members = Planner.list_app_members(app)
    {:noreply,
     socket
     |> put_flash(:info, "Member removed")
     |> assign(:app_members, app_members)}
  end

  def handle_event("save", params, socket) do
    # Merge with last_app_params so unfocused (empty) fields from form submit don't wipe typed data
    incoming = params["app"] || %{}
    app_params = merge_app_params(socket, incoming, [])

    category = app_params["category"]
    category = if category == "__other__", do: String.trim(app_params["category_custom"] || ""), else: category
    if category != "" && category, do: Planner.ensure_category_by_name(category)
    app_params = Map.put(app_params, "category", category)

    custom_fields_params = Map.get(params, "custom_fields", %{})
    custom_fields_map =
      Enum.reduce(custom_fields_params, %{}, fn
        {_, %{"key" => k, "value" => v}}, acc when is_binary(k) and k != "" ->
          Map.put(acc, k, v)
        _, acc ->
          acc
      end)
    app_params = Map.put(app_params, "custom_fields", custom_fields_map)

    label_ids = socket.assigns.selected_label_ids |> Enum.map(&to_string/1)
    labels = socket.assigns.existing_labels |> Enum.filter(fn l -> to_string(l.id) in label_ids end)

    save_app(socket, socket.assigns.live_action, app_params, labels)
  end

  defp save_app(socket, :edit, app_params, labels) do
    user = socket.assigns.current_scope.user
    case Planner.update_app(socket.assigns.app, app_params, labels, user) do
      {:ok, app} ->
        {:noreply,
         socket
         |> put_flash(:info, "App updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, app))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_app(socket, :new, app_params, labels) do
    user = socket.assigns.current_scope.user

    case Planner.create_app(app_params, user, labels) do
      {:ok, app} ->
        {:noreply,
         socket
         |> put_flash(:info, "App created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, app))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _app), do: ~p"/apps"
  defp return_path("show", app), do: ~p"/apps/#{app}"

  # Pre-fill form params from app so edit form shows all existing data (strings for form inputs)
  defp app_to_form_params(%App{} = app) do
    %{
      "name" => to_string_default(app.name, ""),
      "icon" => to_string_default(app.icon, ""),
      "description" => to_string_default(app.description, ""),
      "status" => to_string_default(app.status, "Idea"),
      "visibility" => to_string_default(app.visibility, "private"),
      "category" => to_string_default(app.category, ""),
      "pr_link" => to_string_default(app.pr_link, ""),
      "parent_app_id" => app.parent_app_id
    }
  end

  defp to_string_default(nil, default), do: default
  defp to_string_default(v, _default), do: to_string(v)

  # Merge with last known params; only update the field in _target so empty unfocused fields don't overwrite
  defp merge_app_params(socket, incoming, target) do
    base = socket.assigns[:last_app_params] || app_to_form_params(socket.assigns.app)
    case target do
      ["app", field] when is_binary(field) ->
        Map.put(base, field, Map.get(incoming, field, base[field]))
      _ ->
        Map.merge(base, incoming, fn _k, base_val, in_val ->
          if app_param_present?(in_val), do: in_val, else: base_val
        end)
    end
  end

  defp app_param_present?(nil), do: false
  defp app_param_present?(v) when is_binary(v), do: true
  defp app_param_present?(v) when is_integer(v), do: true
  defp app_param_present?(_), do: true

  defp parent_app_name(%App{parent_app: %Ecto.Association.NotLoaded{}}), do: "Parent"
  defp parent_app_name(%App{parent_app: nil}), do: "Parent"
  defp parent_app_name(%App{parent_app: parent}) when is_struct(parent), do: parent.name
  defp parent_app_name(_), do: "Parent"
end
