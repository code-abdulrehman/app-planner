defmodule AppPlannerWeb.UserLive.Admin do
  use AppPlannerWeb, :live_view

  on_mount({AppPlannerWeb.UserAuth, :require_super_admin})

  alias AppPlanner.Accounts

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()

    {:ok,
     socket
     |> assign(:users, users)
     |> assign(:editing_password_for, nil)
     |> assign(:password_form, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto py-12 px-6">
      <div class="mb-12">
        <h1 class="text-4xl font-black tracking-tight text-base-content mb-2">Admin – Users</h1>
        <p class="text-sm text-base-content/40 font-medium italic">Manage system users and security.</p>
      </div>

      <div class="bg-base-50/50 border border-base-200 rounded-lg overflow-hidden">
        <table class="table w-full">
          <thead>
            <tr class="bg-base-100 border-b border-base-200">
              <th class="text-[10px] font-black uppercase tracking-widest text-base-content/40 py-4 px-6">ID</th>
              <th class="text-[10px] font-black uppercase tracking-widest text-base-content/40 py-4 px-6">Email</th>
              <th class="text-[10px] font-black uppercase tracking-widest text-base-content/40 py-4 px-6">Full Name</th>
              <th class="text-[10px] font-black uppercase tracking-widest text-base-content/40 py-4 px-6">Role</th>
              <th class="text-[10px] font-black uppercase tracking-widest text-base-content/40 py-4 px-6">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-base-200">
            <%= for user <- @users do %>
              <tr id={"admin-user-#{user.id}"} class="hover:bg-base-100/50 transition-colors">
                <td class="py-4 px-6 font-mono text-xs">{user.id}</td>
                <td class="py-4 px-6 font-bold text-sm">{user.email}</td>
                <td class="py-4 px-6 text-sm text-base-content/60 italic">{user.full_name || "—"}</td>
                <td class="py-4 px-6">
                  <span class={[user.role == "super_admin" && "badge badge-primary badge-sm font-black uppercase text-[8px] tracking-widest rounded-md", user.role != "super_admin" && "badge badge-ghost badge-sm font-black uppercase text-[8px] tracking-widest rounded-md border-base-200 opacity-60"]}>{user.role}</span>
                </td>
                <td class="py-4 px-6">
                   <div class="flex gap-2">
                      <button
                        type="button"
                        phx-click="change-password"
                        phx-value-id={user.id}
                        class="btn btn-ghost btn-xs rounded-md font-black uppercase text-[9px] tracking-widest hover:bg-primary/5 hover:text-primary"
                      >
                        Change Password
                      </button>
                      <%= if user.role != "super_admin" do %>
                        <button
                          type="button"
                          phx-click="delete-user"
                          phx-value-id={user.id}
                          data-confirm="Delete this user? This cannot be undone."
                          class="btn btn-ghost btn-xs rounded-md font-black uppercase text-[9px] tracking-widest text-error hover:bg-error/5"
                        >
                          Delete
                        </button>
                      <% end %>
                   </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if @editing_password_for do %>
        <div class="modal modal-open backdrop-blur-sm">
          <div class="modal-box rounded-lg border border-base-200 p-8">
            <h3 class="font-black text-xl tracking-tight mb-2">Change password</h3>
            <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 mb-8 pb-4 border-b border-base-200">User: {@editing_password_for.email}</p>

            <.form for={@password_form} id="admin_password_form" phx-submit="save_password" phx-change="validate_password" class="space-y-6">
              <div class="form-control">
                 <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">New Password</span></label>
                 <.input field={@password_form[:password]} type="password" required class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
              </div>
              <div class="form-control">
                 <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Confirm Password</span></label>
                 <.input field={@password_form[:password_confirmation]} type="password" required class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
              </div>

              <div class="flex justify-end gap-3 pt-6">
                <button type="button" phx-click="cancel-password" class="btn btn-ghost rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200 px-6">Cancel</button>
                <button type="submit" class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-8 shadow-lg shadow-primary/20">Save</button>
              </div>
            </.form>
          </div>
          <div class="modal-backdrop bg-base-content/40 cursor-default" phx-click="cancel-password"></div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("change-password", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    form = to_form(Accounts.change_user_password(user, %{}, hash_password: false), as: "user")

    {:noreply,
     socket
     |> assign(:editing_password_for, user)
     |> assign(:password_form, form)}
  end

  def handle_event("cancel-password", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_password_for, nil)
     |> assign(:password_form, nil)}
  end

  def handle_event("validate_password", %{"user" => params}, socket) do
    user = socket.assigns.editing_password_for

    form =
      user
      |> Accounts.change_user_password(params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form(as: "user")

    {:noreply, assign(socket, :password_form, form)}
  end

  def handle_event("save_password", %{"user" => params}, socket) do
    admin = socket.assigns.current_scope.user
    user = socket.assigns.editing_password_for

    case Accounts.update_user_password_by_admin(admin, user, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password updated for #{user.email}")
         |> assign(:editing_password_for, nil)
         |> assign(:password_form, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         assign(socket, :password_form, to_form(changeset, action: :insert, as: "user"))}
    end
  end

  def handle_event("delete-user", %{"id" => id}, socket) do
    admin = socket.assigns.current_scope.user
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(admin, user)
    users = Enum.reject(socket.assigns.users, &(&1.id == user.id))

    {:noreply,
     socket
     |> put_flash(:info, "User #{user.email} deleted.")
     |> assign(:users, users)}
  end
end
