defmodule AppPlannerWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AppPlannerWeb, :html

  # Embed all files in layouts/* within this module.
  embed_templates("layouts/*")

  @doc """
  Renders your app layout.
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:current_scope, :map, default: nil)
  attr(:current_workspace, :map, default: nil)
  attr(:inner_content, :any, required: true)

  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 flex flex-col transition-colors duration-300">
      <header class="h-14 border-b border-base-200 bg-base-100/80 backdrop-blur-md shrink-0 flex items-center justify-between px-6 sticky top-0 z-40">
        <div class="flex items-center gap-4">
           <.link navigate={~p"/workspaces"} class="flex items-center gap-2 group">
              <div class="w-8 h-8 bg-primary rounded-lg flex items-center justify-center text-primary-content font-black text-sm shadow-sm group-hover:-rotate-20 transition-transform">A</div>
              <span class="font-black tracking-tighter text-lg text-base-content">AppPlanner</span>
           </.link>
           <div class="flex items-center gap-3 ml-4 pl-4 border-l border-base-200">
              <AppPlannerWeb.WorkspaceSelector.workspace_selector
                :if={@current_scope && @current_scope.user}
                current_user={@current_scope.user}
                current_workspace={@current_workspace}
              />
           </div>
        </div>

        <div class="flex items-center gap-6">
           <.theme_toggle />

           <div class="dropdown dropdown-end">
              <label tabindex="0" class="btn btn-ghost btn-circle btn-sm avatar flex items-center justify-center border bg-base-300 rounded-full">
                 <div class="w-8 h-5 rounded-lg flex items-center justify-center text-base-content/60 font-black text-xs border border-base-300 shadow-inner">
                   <%= if @current_scope && @current_scope.user do %>
                     {String.at(@current_scope.user.email, 0) |> String.upcase()}
                   <% else %>
                     <.icon name="hero-user" class="w-4 h-4" />
                   <% end %>
                 </div>
              </label>
              <ul tabindex="0" class="mt-2 z-[1] p-1 shadow-xl menu menu-sm dropdown-content bg-base-100 rounded-lg w-52 border border-base-200">
                <li><.link navigate={~p"/workspaces"} class="py-2.5 font-bold text-base-content/70"><.icon name="hero-rectangle-stack" class="w-4 h-4 mr-2" /> Workspaces</.link></li>
                <li><.link navigate={~p"/users/settings"} class="py-2.5 font-bold text-base-content/70"><.icon name="hero-cog-8-tooth" class="w-4 h-4 mr-2" /> Settings</.link></li>
                <div class="divider my-0 opacity-10"></div>
                <li><.link href={~p"/users/log-out"} method="delete" class="py-2.5 font-bold text-error"><.icon name="hero-arrow-right-start-on-rectangle" class="w-4 h-4 mr-2" /> Sign Out</.link></li>
              </ul>
           </div>
        </div>
      </header>

      <main class="flex-1 flex overflow-hidden">
        {@inner_content}
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  attr(:flash, :map, required: true)
  attr(:id, :string, default: "flash-group")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border bg-base-300 rounded-full w-24 h-8 overflow-hidden">
      <div class="absolute w-1/3 h-full rounded-full bg-primary left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-all duration-300" />

      <button
        class="flex p-2 cursor-pointer w-1/3 justify-center z-10"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-3 text-base-content hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3 justify-center z-10"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-3 text-base-content hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3 justify-center z-10"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-3 text-base-content hover:opacity-100" />
      </button>
    </div>
    """
  end
end
