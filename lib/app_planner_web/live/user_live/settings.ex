defmodule AppPlannerWeb.UserLive.Settings do
  use AppPlannerWeb, :live_view

  on_mount {AppPlannerWeb.UserAuth, :require_sudo_mode}

  alias AppPlanner.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="max-w-3xl mx-auto py-12 px-6">
        <div class="mb-10">
          <div class="flex items-center gap-2 text-[10px] font-black uppercase text-base-content/30 tracking-widest mb-2">
            <.link navigate={~p"/workspaces"} class="hover:text-primary transition-colors">
              Workspace
            </.link>
            <span>/</span>
            <span class="text-base-content/80">Account</span>
          </div>
          <h1 class="text-3xl font-black text-base-content tracking-tight">Account Settings</h1>
          <p class="text-sm text-base-content/50 font-medium mt-2 italic">
            Manage your profile, email, and password.
          </p>
        </div>

        <div class="space-y-6">
          <section class="bg-base-50/50 border border-base-200 rounded-lg p-6">
            <div class="mb-6">
              <h2 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Profile
              </h2>
              <p class="text-xs text-base-content/50 font-medium mt-1">
                Update your display name.
              </p>
            </div>

            <.form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
              class="space-y-4"
            >
              <.input
                field={@profile_form[:full_name]}
                type="text"
                label="Full name"
                placeholder="Your name"
                autocomplete="name"
                class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              />
              <div class="flex justify-end pt-2">
                <.button
                  variant="primary"
                  phx-disable-with="Saving..."
                  class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-8 shadow-lg shadow-primary/20"
                >
                  Save
                </.button>
              </div>
            </.form>
          </section>

          <section class="bg-base-50/50 border border-base-200 rounded-lg p-6">
            <div class="mb-6">
              <h2 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Email
              </h2>
              <p class="text-xs text-base-content/50 font-medium mt-1">
                Change your email address (we’ll send a confirmation link).
              </p>
            </div>

            <.form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
              class="space-y-4"
            >
              <.input
                field={@email_form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
                class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              />
              <div class="flex justify-end pt-2">
                <.button
                  variant="primary"
                  phx-disable-with="Changing..."
                  class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-8 shadow-lg shadow-primary/20"
                >
                  Change Email
                </.button>
              </div>
            </.form>
          </section>

          <section class="bg-base-50/50 border border-base-200 rounded-lg p-6">
            <div class="mb-6">
              <h2 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Password
              </h2>
              <p class="text-xs text-base-content/50 font-medium mt-1">
                Set a new password for your account.
              </p>
            </div>

            <.form
              for={@password_form}
              id="password_form"
              action={~p"/users/update-password"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                autocomplete="username"
                value={@current_email}
              />
              <.input
                field={@password_form[:password]}
                type="password"
                label="New password"
                autocomplete="new-password"
                required
                class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Confirm new password"
                autocomplete="new-password"
                class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              />
              <div class="flex justify-end pt-2">
                <.button
                  variant="primary"
                  phx-disable-with="Saving..."
                  class="btn btn-primary rounded-lg text-[10px] font-black uppercase tracking-widest px-8 shadow-lg shadow-primary/20"
                >
                  Save Password
                </.button>
              </div>
            </.form>
          </section>

          <section class="bg-base-50/50 border border-base-200 rounded-lg p-6">
            <div class="flex items-center justify-between gap-6">
              <div>
                <h2 class="text-[10px] font-black uppercase tracking-widest text-base-content/40">
                  Quick login
                </h2>
                <p class="text-xs text-base-content/50 font-medium mt-1">
                  Send a login link to your email.
                </p>
              </div>
              <button
                type="button"
                phx-click="send_login_link"
                class="btn btn-ghost rounded-lg text-[10px] font-black uppercase tracking-widest border border-base-200 px-6"
              >
                Send me a login link
              </button>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile_changeset = Accounts.change_user_profile(user, %{}) |> Map.put(:action, nil)
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:profile_form, to_form(profile_changeset, as: "user"))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", params, socket) do
    %{"user" => user_params} = params

    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form(as: "user")

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.update_user_profile(user, user_params) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated.")
         |> assign(:profile_form, to_form(Accounts.change_user_profile(updated, %{}), as: "user"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, action: :insert, as: "user"))}
    end
  end

  def handle_event("send_login_link", _params, socket) do
    user = socket.assigns.current_scope.user
    Accounts.deliver_login_instructions(user, &url(~p"/users/log-in/#{&1}"))
    {:noreply, put_flash(socket, :info, "Login link sent to #{user.email}.")}
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
