defmodule AppPlannerWeb.FeatureLive.Form do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Planner
  alias AppPlanner.Planner.Feature
  alias AppPlannerWeb.IconHelper

  # Ensure edit form shows feature data: use form value or fall back to feature field
  defp edit_value(form, feature, field) when is_atom(field) do
    case Phoenix.HTML.Form.input_value(form, field) do
      nil -> feature_value(feature, field)
      "" -> feature_value(feature, field)
      val -> val
    end
  end

  defp feature_value(feature, :implementation_date) do
    case Map.get(feature, :implementation_date) do
      %Date{} = d -> Date.to_iso8601(d)
      _ -> ""
    end
  end

  defp feature_value(feature, field) do
    Map.get(feature, field) |> to_string_edit()
  end

  defp to_string_edit(nil), do: ""
  defp to_string_edit(v), do: to_string(v)

  # For :new use form value so phx-change doesn't clear other fields; for :edit use edit_value
  defp input_display_value(form, feature, field, :edit), do: edit_value(form, feature, field)

  defp input_display_value(form, _feature, field, :new) do
    case Phoenix.HTML.Form.input_value(form, field) do
      %Date{} = d -> Date.to_iso8601(d)
      v when v in [nil, ""] -> ""
      v -> to_string(v)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mb-10">
        <.breadcrumb items={breadcrumb_items_feature_form(@feature, @page_title, @live_action)} />
        <h1 class="text-2xl font-bold mb-1 mt-2">{@page_title}</h1>
        <p class="text-sm text-base-content/70">Feature details and roadmap.</p>
      </div>

      <.form for={@form} id="feature-form" phx-change="validate" phx-submit="save" class="space-y-8 max-w-4xl">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div class="space-y-6">
            <div class="form-control">
              <label class="label"><span class="label-text font-medium">Title</span></label>
              <.input field={@form[:title]} type="text" placeholder="e.g. Auth System" value={input_display_value(@form, @feature, :title, @live_action)} class="input input-bordered w-full" />
            </div>

            <div class="flex gap-4">
                <div class="form-control w-[48%] overflow-x-hidden text-ellipsis">
                  <label class="label"><span class="label-text font-medium">Project</span></label>
                  <div :if={!@feature.app_id}>
                    <.input field={@form[:app_id]} type="select" options={Enum.map(@apps, &{&1.name, &1.id})} prompt="Select project..." value={input_display_value(@form, @feature, :app_id, @live_action)} class="select select-bordered w-full overflow-x-hidden" />
                  </div>
                  <div :if={@feature.app_id} class="input input-bordered bg-base-200 flex items-center rounded-lg">
                    {@feature.app.name}
                    <input type="hidden" name="feature[app_id]" value={@feature.app_id} />
                  </div>
                </div>
                <div class="form-control w-[48%]">
                  <label class="label"><span class="label-text font-medium">Status</span></label>
                  <.input field={@form[:status]} type="select" options={["Idea", "Planned", "In Progress", "Completed", "Archived"]} value={input_display_value(@form, @feature, :status, @live_action)} class="select select-bordered w-full" />
                </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
               <div class="form-control">
                 <label class="label"><span class="label-text font-medium">Date</span></label>
                 <.input field={@form[:implementation_date]} type="date" value={input_display_value(@form, @feature, :implementation_date, @live_action)} class="input input-bordered w-full" />
               </div>
               <div class="form-control">
                 <label class="label"><span class="label-text font-medium">Time estimate</span></label>
                 <.input field={@form[:time_estimate]} type="text" placeholder="e.g. 2d" value={input_display_value(@form, @feature, :time_estimate, @live_action)} class="input input-bordered w-full" />
               </div>
            </div>
            <div class="form-control">
              <label class="label"><span class="label-text font-medium">Git / PR link</span></label>
              <.input field={@form[:pr_link]} type="text" placeholder="https://github.com/... or PR link" value={input_display_value(@form, @feature, :pr_link, @live_action)} class="input input-bordered w-full" />
            </div>
            <div class="form-control">
                <label class="label"><span class="label-text font-medium">User flow <span class="text-[10px] text-base-content/50 ml-1 font-normal">(Markdown supported)</span></span></label>
                <.input field={@form[:how_to_add]} type="textarea" placeholder="..." value={input_display_value(@form, @feature, :how_to_add, @live_action)} class="textarea textarea-bordered h-20 w-full" />
              </div>
          </div>

          <div class="space-y-6">
              <div class="form-control">
                <label class="label"><span class="label-text font-medium">Icon</span></label>
                <div class="flex items-center gap-4 mb-2">
                  <div class="w-7 h-7 border border-base-300 rounded-lg flex items-center justify-center bg-base-200">
                    <.icon name={if @icon_preview, do: "hero-#{@icon_preview}", else: "hero-bolt"} class="w-4 h-4" />
                  </div>
                  <div class="flex-1">
                    <input type="text" name="icon_search_query" phx-keyup="search-icons" phx-debounce="200"
                          placeholder="Search icons..." class="input input-bordered w-full input-sm" value={@icon_search} />
                  </div>
                </div>
                <div class="grid grid-cols-6 gap-1.5 p-2 border border-base-300 rounded-lg overflow-y-auto max-h-36">
                  <input type="hidden" name="feature[icon]" value={@icon_preview} />
                  <%= for icon <- @filtered_icons do %>
                    <button type="button" phx-click="select-icon" phx-value-icon={icon}
                            class={"btn btn-square btn-sm #{if @icon_preview == icon, do: "btn-primary", else: "btn-ghost"}"}>
                      <.icon name={"hero-#{icon}"} class="w-4 h-4" />
                    </button>
                  <% end %>
                </div>
              </div>

             <div class="form-control">
               <label class="label"><span class="label-text font-medium">Rationale <span class="text-[10px] text-base-content/50 ml-1 font-normal">(Markdown supported)</span></span></label>
               <.input field={@form[:why_need]} type="textarea" placeholder="Why add this?" value={input_display_value(@form, @feature, :why_need, @live_action)} class="textarea textarea-bordered h-24 w-full" />
             </div>
             <div class="form-control">
               <label class="label"><span class="label-text font-medium">Description <span class="text-[10px] text-base-content/50 ml-1 font-normal">(Markdown supported)</span></span></label>
               <.input field={@form[:description]} type="textarea" placeholder="Details..." value={input_display_value(@form, @feature, :description, @live_action)} class="textarea textarea-bordered h-36 w-full" />
             </div>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
           <div class="space-y-6">
              <div class="form-control">
                <label class="label"><span class="label-text font-medium">Strategy <span class="text-[10px] text-base-content/50 ml-1 font-normal">(Markdown supported)</span></span></label>
                <.input field={@form[:how_to_implement]} type="textarea" placeholder="..." value={input_display_value(@form, @feature, :how_to_implement, @live_action)} class="textarea textarea-bordered h-20 w-full" />
              </div>
              <div class="form-control pt-6 border-t">
          <label class="label flex flex-wrap items-center justify-between gap-2">
            <span class="label-text font-medium">Custom fields</span>
            <button type="button" phx-click="add-feature-custom-field" class="link link-primary text-sm">Add field</button>
          </label>
          <div class="space-y-2">
            <%= for {field, i} <- Enum.with_index(@feature_custom_fields) do %>
              <div class="flex gap-2 items-start group">
                <input type="text" name={"feature_custom_fields[#{i}][key]"} value={field["key"]} placeholder="Key" class="input input-bordered input-sm w-1/3 font-bold uppercase tracking-tighter" />
                <input type="text" name={"feature_custom_fields[#{i}][value]"} value={field["value"]} placeholder="Value" class="input input-bordered input-sm flex-1" />
                <button type="button" phx-click="remove-feature-custom-field" phx-value-index={i} class="btn btn-ghost btn-xs text-error p-2 h-7 group-hover:opacity-100">×</button>
              </div>
            <% end %>
          </div>
        </div>
           </div>
           <div class="space-y-6">
              <div class="form-control">
                <label class="label"><span class="label-text font-medium">Pros <span class="text-[10px] text-base-content/50 ml-1 font-normal">(Markdown supported)</span></span></label>
                <.input field={@form[:pros]} type="textarea" placeholder="..." value={input_display_value(@form, @feature, :pros, @live_action)} class="textarea textarea-bordered h-20 w-full" />
              </div>
              <div class="form-control">
                <label class="label"><span class="label-text font-medium">Cons <span class="text-[10px] text-base-content/50 ml-1 font-normal">(Markdown supported)</span></span></label>
                <.input field={@form[:cons]} type="textarea" placeholder="..." value={input_display_value(@form, @feature, :cons, @live_action)} class="textarea textarea-bordered h-20 w-full" />
              </div>
           </div>
        </div>


        <div class="flex gap-3 pt-6 border-t">
          <.button phx-disable-with="Saving..." class="btn btn-primary">Save</.button>
          <.link navigate={return_path(@return_to, @feature)} class="btn btn-ghost">Cancel</.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    params = normalize_route_params(params)

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:icon_search, "")
     |> assign(:filtered_icons, Enum.take(IconHelper.list_icons(), 12))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    params = normalize_route_params(params)
    id = params["id"]

    case {socket.assigns.live_action, id} do
      {:edit, id} when is_binary(id) and id != "" ->
        {:noreply, apply_action(socket, :edit, params)}

      _ ->
        {:noreply, socket}
    end
  end

  def breadcrumb_items_feature_form(feature, page_title, _live_action) do
    base = [%{label: "Projects", path: ~p"/apps"}]

    with_app =
      if feature.app_id && feature.app do
        base ++ [%{label: feature.app.name, path: ~p"/apps/#{feature.app_id}"}]
      else
        base
      end

    with_app ++ [%{label: page_title, path: nil}]
  end

  defp return_to("show"), do: "show"
  defp return_to("app"), do: "app"
  defp return_to(_), do: "index"

  defp normalize_route_params(params) when is_map(params) do
    id = Map.get(params, "id") || Map.get(params, :id)
    if id, do: Map.put(params, "id", to_string(id)), else: params
  end

  defp normalize_route_params(params), do: params || %{}

  defp apply_action(socket, :edit, params) do
    id = params["id"] || params[:id]
    id || raise "edit action requires id in params"

    user = socket.assigns.current_scope.user
    feature = Planner.get_feature!(to_string(id), user)
    app = Planner.get_app(feature.app_id, user)

    if app == nil do
      socket
      |> put_flash(:error, "This project is no longer available.")
      |> push_navigate(to: ~p"/apps")
    else
      feature = %{feature | app: app}
      apply_action_edit_feature(socket, feature, user)
    end
  end

  defp apply_action_edit_feature(socket, feature, user) do
    feature_custom_fields =
      (feature.custom_fields || %{})
      |> Enum.map(fn {k, v} -> %{"key" => to_string(k), "value" => to_string(v)} end)

    apps =
      Planner.list_apps(user)
      |> Enum.filter(&Planner.can_edit_app?(&1, user))

    # Pre-fill form with existing feature data so all fields show old values
    feature_params = feature_to_form_params(feature)

    form =
      feature
      |> Planner.change_feature(feature_params)
      |> to_form()

    socket
    |> assign(:page_title, "Edit Feature")
    |> assign(:feature, feature)
    |> assign(:apps, apps)
    |> assign(:feature_custom_fields, feature_custom_fields)
    |> assign(:icon_preview, feature.icon)
    |> assign(:last_feature_params, feature_to_form_params(feature))
    |> assign(:form, form)
  end

  defp apply_action(socket, :new, params) do
    user = socket.assigns.current_scope.user

    app_id =
      case params["app_id"] do
        nil -> nil
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

    feature = %Feature{app_id: app_id}

    if app_id != nil do
      case Planner.get_app(app_id, user) do
        nil ->
          socket
          |> put_flash(:error, "This project is no longer available.")
          |> push_navigate(to: ~p"/apps")

        app ->
          feature = %{feature | app: app}
          apply_action_new_feature(socket, feature, user)
      end
    else
      apply_action_new_feature(socket, feature, user)
    end
  end

  defp apply_action_new_feature(socket, feature, user) do
    apps = Planner.list_apps(user) |> Enum.filter(&Planner.can_edit_app?(&1, user))

    socket
    |> assign(:page_title, "New Feature")
    |> assign(:feature, feature)
    |> assign(:apps, apps)
    |> assign(:feature_custom_fields, [])
    |> assign(:icon_preview, nil)
    |> assign(:last_feature_params, feature_to_form_params(feature))
    |> assign(:form, to_form(Planner.change_feature(feature)))
  end

  # Pre-fill form params from feature so edit form shows all existing data (strings for form inputs)
  defp feature_to_form_params(%Feature{} = feature) do
    base = %{
      "title" => to_string_or_nil(feature.title),
      "icon" => to_string_or_nil(feature.icon),
      "description" => to_string_or_nil(feature.description),
      "how_to_add" => to_string_or_nil(feature.how_to_add),
      "pros" => to_string_or_nil(feature.pros),
      "cons" => to_string_or_nil(feature.cons),
      "how_to_implement" => to_string_or_nil(feature.how_to_implement),
      "why_need" => to_string_or_nil(feature.why_need),
      "time_estimate" => to_string_or_nil(feature.time_estimate),
      "pr_link" => to_string_or_nil(feature.pr_link),
      "status" => to_string_or_nil(feature.status) || "Planned",
      "app_id" => feature.app_id
    }

    date_param =
      case feature.implementation_date do
        %Date{} = d -> %{"implementation_date" => Date.to_iso8601(d)}
        _ -> %{}
      end

    Map.merge(base, date_param)
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(v), do: to_string(v)

  # Merge with last known params; only update the field in _target so unfocused (empty) inputs don't overwrite
  defp merge_feature_params(socket, incoming, target) do
    base = socket.assigns[:last_feature_params] || feature_to_form_params(socket.assigns.feature)

    case target_field(target) do
      field when is_binary(field) ->
        # Only update the field that triggered phx-change; keep all others from base
        Map.put(base, field, Map.get(incoming, field, base[field]))

      nil ->
        # _target missing or unknown: merge but never overwrite with empty (unfocused fields send "")
        Map.merge(base, incoming, fn _k, base_val, in_val ->
          if present?(in_val), do: in_val, else: base_val
        end)
    end
  end

  # _target can be ["feature", "title"] (list) or "feature[title]" (string from meta)
  defp target_field(["feature", field]) when is_binary(field), do: field

  defp target_field("feature[" <> rest) do
    case String.split(rest, "]", parts: 2) do
      [field, _] -> field
      _ -> nil
    end
  end

  defp target_field(_), do: nil

  defp present?(nil), do: false
  defp present?(v) when is_binary(v), do: String.trim(v) != ""
  defp present?(%Date{}), do: true
  defp present?(v) when is_integer(v), do: true
  defp present?(_), do: true

  defp normalize_app_id(nil), do: nil
  defp normalize_app_id(""), do: nil
  defp normalize_app_id(id) when is_integer(id), do: id

  defp normalize_app_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp normalize_app_id(_), do: nil

  @impl true
  def handle_event("validate", params, socket) do
    user = socket.assigns.current_scope.user
    incoming = params["feature"] || %{}
    target = params["_target"] || []
    # Only update the field that triggered phx-change so empty unfocused fields don't overwrite
    feature_params = merge_feature_params(socket, incoming, target)

    feature_params =
      if socket.assigns[:icon_preview],
        do: Map.put(feature_params, "icon", socket.assigns.icon_preview),
        else: feature_params

    raw_custom = params["feature_custom_fields"] || %{}

    feature_custom_fields =
      if map_size(raw_custom) > 0,
        do: parse_custom_fields(raw_custom),
        else: socket.assigns.feature_custom_fields

    feature_params = put_custom_fields_map(feature_params, feature_custom_fields)
    changeset = Planner.change_feature(socket.assigns.feature, feature_params)
    icon_search = Map.get(params, "icon_search_query", socket.assigns.icon_search)

    # Sync the preloaded app for the breadcrumb if app_id changes
    raw_app_id = feature_params["app_id"]
    feature = socket.assigns.feature

    app_id_int = normalize_app_id(raw_app_id)

    {feature, redirect_socket} =
      if app_id_int && (feature.app_id || 0) != app_id_int do
        case Planner.get_app(app_id_int, user) do
          nil ->
            {feature,
             socket
             |> put_flash(:error, "This project is no longer available.")
             |> push_navigate(to: ~p"/apps")}

          app ->
            {%{feature | app_id: app_id_int, app: app}, nil}
        end
      else
        {feature, nil}
      end

    if redirect_socket do
      {:noreply, redirect_socket}
    else
      {:noreply,
       socket
       |> assign(:feature, feature)
       |> assign(:feature_custom_fields, feature_custom_fields)
       |> assign(:icon_search, icon_search)
       |> assign(:icon_preview, feature_params["icon"] || socket.assigns[:icon_preview])
       |> assign(:last_feature_params, feature_params)
       |> assign(:form, to_form(changeset, action: :validate))}
    end
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

  def handle_event("add-feature-custom-field", _, socket) do
    fields = socket.assigns.feature_custom_fields ++ [%{"key" => "", "value" => ""}]
    {:noreply, assign(socket, :feature_custom_fields, fields)}
  end

  def handle_event("remove-feature-custom-field", %{"index" => index}, socket) do
    i = String.to_integer(index)
    fields = List.delete_at(socket.assigns.feature_custom_fields, i)
    {:noreply, assign(socket, :feature_custom_fields, fields)}
  end

  def handle_event("save", params, socket) do
    # Merge with last_feature_params so unfocused (empty) fields from form submit don't wipe typed data
    incoming = params["feature"] || %{}
    feature_params = merge_feature_params(socket, incoming, [])

    feature_params =
      if socket.assigns[:icon_preview],
        do: Map.put(feature_params, "icon", socket.assigns.icon_preview),
        else: feature_params

    custom_fields = parse_custom_fields(params["feature_custom_fields"] || %{})
    feature_params = put_custom_fields_map(feature_params, custom_fields)
    save_feature(socket, socket.assigns.live_action, feature_params)
  end

  defp save_feature(socket, :edit, feature_params) do
    user = socket.assigns.current_scope.user

    case Planner.update_feature(socket.assigns.feature, feature_params, user) do
      {:ok, feature} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feature updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, feature))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_feature(socket, :new, feature_params) do
    user = socket.assigns.current_scope.user

    case Planner.create_feature(feature_params, user) do
      {:ok, feature} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feature created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, feature))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", nil), do: ~p"/features"

  defp return_path("index", feature) when is_struct(feature) do
    if feature.app_id && is_nil(feature.id) do
      ~p"/apps/#{feature.app_id}"
    else
      ~p"/features"
    end
  end

  # After add feature from app page: redirect to that app's page (features section)
  defp return_path("app", feature) when is_struct(feature) and not is_nil(feature.app_id) do
    ~p"/apps/#{feature.app_id}"
  end

  defp return_path("show", feature) when is_struct(feature) and not is_nil(feature.id) do
    ~p"/features/#{feature}"
  end

  defp return_path("show", feature) when is_struct(feature) do
    if feature.app_id, do: ~p"/apps/#{feature.app_id}", else: ~p"/features"
  end

  defp return_path(_, _), do: ~p"/features"

  defp parse_custom_fields(params) when is_map(params) do
    params
    |> Enum.sort_by(fn {k, _} ->
      case Integer.parse(to_string(k)) do
        {i, _} -> i
        :error -> 0
      end
    end)
    |> Enum.map(fn {_, v} -> v end)
  end

  defp put_custom_fields_map(feature_params, list) do
    map =
      Enum.reduce(list, %{}, fn %{"key" => k, "value" => v}, acc ->
        if is_binary(k) && String.trim(k) != "", do: Map.put(acc, String.trim(k), v), else: acc
      end)

    Map.put(feature_params, "custom_fields", map)
  end
end
