defmodule AppPlannerWeb.UserLive.Admin do
  use AppPlannerWeb, :live_view

  on_mount {AppPlannerWeb.UserAuth, :require_super_admin}

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
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mb-8">
        <h1 class="text-2xl font-bold">Admin – Users</h1>
        <p class="text-sm text-base-content/70">Super admin: change password or delete users.</p>
      </div>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>ID</th>
              <th>Email</th>
              <th>Full name</th>
              <th>Role</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for user <- @users do %>
              <tr id={"admin-user-#{user.id}"}>
                <td>{user.id}</td>
                <td>{user.email}</td>
                <td>{user.full_name || "—"}</td>
                <td>
                  <span class={[user.role == "super_admin" && "badge badge-primary"]}>{user.role}</span>
                </td>
                <td class="flex gap-2">
                  <button
                    type="button"
                    phx-click="change-password"
                    phx-value-id={user.id}
                    class="btn btn-ghost btn-xs"
                  >
                    Change password
                  </button>
                  <%= if user.role != "super_admin" do %>
                    <button
                      type="button"
                      phx-click="delete-user"
                      phx-value-id={user.id}
                      data-confirm="Delete this user? This cannot be undone."
                      class="btn btn-ghost btn-xs text-error"
                    >
                      Delete
                    </button>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if @editing_password_for do %>
        <div class="modal modal-open">
          <div class="modal-box">
            <h3 class="font-bold text-lg">Change password for {@editing_password_for.email}</h3>
            <.form for={@password_form} id="admin_password_form" phx-submit="save_password" phx-change="validate_password">
              <.input field={@password_form[:password]} type="password" label="New password" required />
              <.input field={@password_form[:password_confirmation]} type="password" label="Confirm" required />
              <div class="modal-action">
                <button type="button" phx-click="cancel-password" class="btn btn-ghost">Cancel</button>
                <.button class="btn btn-primary">Save password</.button>
              </div>
            </.form>
          </div>
          <form method="dialog" class="modal-backdrop">
            <button type="button" phx-click="cancel-password">close</button>
          </form>
        </div>
      <% end %>
    </Layouts.app>
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
        {:noreply, assign(socket, :password_form, to_form(changeset, action: :insert, as: "user"))}
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
