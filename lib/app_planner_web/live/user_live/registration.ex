defmodule AppPlannerWeb.UserLive.Registration do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Accounts
  alias AppPlanner.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto py-24 px-6 text-center">
      <div class="mb-12">
        <div class="w-16 h-16 bg-primary rounded-xl flex items-center justify-center text-primary-content font-black text-2xl shadow-lg shadow-primary/20 mx-auto mb-6">
          <.icon name="hero-cursor-arrow-ripple" class="w-4 h-4" />
        </div>
        <h1 class="text-3xl font-black tracking-tight text-base-content mb-2">Register</h1>
        <p class="text-sm text-base-content/40 font-medium italic">
          Already have an account?
          <.link navigate={~p"/users/log-in"} class="text-primary hover:underline font-bold">
            Log in
          </.link>
        </p>
      </div>

      <div class="bg-base-50/50 border border-base-200 rounded-lg p-3 w-[400px]">
        <.form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-debounce="blur"
          class="space-y-6"
        >
          <div class="form-control text-left space-y-4">
            <.input
              field={@form[:full_name]}
              type="text"
              label="Full name"
              placeholder="John Doe"
              autocomplete="name"
              id="registration_form_full_name"
            />

            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="name@example.com"
              autocomplete="username"
              required
              id="registration_form_email"
            />

            <div
              class="relative"
              id="registration-password-toggle"
              phx-hook="PasswordToggle"
              data-password-toggle-input="#registration_form_password"
              data-password-toggle-button="#registration-password-toggle-btn"
            >
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                placeholder="••••••••"
                autocomplete="new-password"
                required
                id="registration_form_password"
              />

              <button
                type="button"
                id="registration-password-toggle-btn"
                class="absolute right-3 top-9 text-base-content/50 hover:text-base-content/80 transition-colors"
                aria-label="Show password"
              >
                <span data-password-icon="show">
                  <.icon name="hero-eye" class="w-4 h-4" />
                </span>
                <span data-password-icon="hide" class="hidden">
                  <.icon name="hero-eye-slash" class="w-4 h-4" />
                </span>
              </button>
            </div>
          </div>

          <button
            type="submit"
            phx-disable-with="Creating account..."
            class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20"
          >
            Register
          </button>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(
        %{"email" => email_param, "invite_token" => invite_token_param} = _params,
        _session,
        socket
      ) do
    if socket.assigns.current_scope.user do
      {:ok, push_navigate(socket, to: AppPlannerWeb.UserAuth.signed_in_path(socket))}
    else
      changeset =
        Accounts.User.registration_changeset(%Accounts.User{}, %{email: email_param},
          hash_password: false
        )
        |> Map.put(:action, :insert)

      socket =
        socket
        |> assign(:last_registration_params, %{"email" => email_param})
        |> assign_form(changeset)
        |> assign(:invite_token, invite_token_param)

      {:ok, socket}
    end
  end

  def mount(_params, _session, socket) do
    if socket.assigns.current_scope.user do
      {:ok, push_navigate(socket, to: AppPlannerWeb.UserAuth.signed_in_path(socket))}
    else
      changeset =
        Accounts.User.registration_changeset(%Accounts.User{}, %{}, hash_password: false)

      socket =
        socket
        |> assign(:last_registration_params, %{})
        |> assign_form(changeset)
        |> assign(:invite_token, nil)

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Auto-confirm user
        {:ok, _confirmed_user} = Accounts.confirm_user(user)

        if invite_token = socket.assigns.invite_token do
          case Workspaces.accept_invite_link(invite_token, user) do
            {:ok, _user, workspace} ->
              {:noreply,
               socket
               |> put_flash(:info, "Account created and workspace joined successfully!")
               |> push_navigate(to: ~p"/workspaces/#{workspace.id}/board")}

            {:error, reason} ->
              {:noreply,
               socket
               |> put_flash(
                 :error,
                 "Account created, but failed to join workspace: #{inspect(reason)}. Please contact support."
               )
               |> push_navigate(to: ~p"/users/log-in")}
          end
        else
          {:noreply,
           socket
           |> put_flash(
             :info,
             "Account created successfully! You can now log in with your email and password."
           )
           |> push_navigate(to: ~p"/users/log-in")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    previous =
      socket.assigns[:last_registration_params]
      |> normalize_string_keys()

    merged = Map.merge(previous, user_params)

    changeset =
      %Accounts.User{}
      |> Accounts.User.registration_changeset(merged, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:last_registration_params, merged)
     |> assign_form(changeset)}
  end

  defp normalize_string_keys(nil), do: %{}

  defp normalize_string_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
