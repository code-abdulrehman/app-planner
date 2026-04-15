defmodule AppPlannerWeb.UserLive.Login do
  use AppPlannerWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto py-24 px-6">
      <div class="text-center mb-10">
        <div class="w-14 h-14 bg-primary rounded-2xl flex items-center justify-center text-primary-content shadow-lg shadow-primary/20 mx-auto mb-5">
          <.icon name="hero-cursor-arrow-ripple" class="w-5 h-5" />
        </div>

        <h1 class="text-3xl font-black tracking-tight text-base-content">Log in</h1>

        <p class="mt-2 text-sm text-base-content/60 font-medium">
          Don’t have an account?
          <.link navigate={~p"/users/register"} class="text-primary hover:underline font-bold">
            Register
          </.link>
        </p>
      </div>

      <div class="bg-base-50/50 border border-base-200 rounded-xl p-6 space-y-5 w-[400px]">
        <p class="text-[10px] font-black uppercase tracking-widest text-base-content/40 text-left">
          Log in with email
        </p>

        <.form
          for={@password_form}
          id="login_form_password"
          action={
            if @invite_token,
              do: ~p"/users/log-in?invite_token=#{@invite_token}",
              else: ~p"/users/log-in"
          }
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
          class="space-y-4"
        >
          <.input
            field={@password_form[:email]}
            id="login_form_password_email"
            type="email"
            label="Email"
            required
            autocomplete="username"
          />

          <div
            class="relative"
            id="login-password-toggle"
            phx-hook="PasswordToggle"
            data-password-toggle-input="#login_form_password_password"
            data-password-toggle-button="#login-password-toggle-btn"
          >
            <.input
              field={@password_form[:password]}
              id="login_form_password_password"
              type="password"
              label="Password"
              required
              autocomplete="current-password"
            />

            <button
              type="button"
              id="login-password-toggle-btn"
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

          <label class="flex items-center gap-2 text-sm text-base-content/70 select-none">
            <input
              type="checkbox"
              name={@password_form[:remember_me].name}
              value="true"
              checked={@remember_me}
              phx-click="toggle_remember_me"
              class="h-4 w-4 rounded border-base-300 text-primary focus:ring-primary"
            /> Remember me
          </label>

          <button class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">
            Log In
          </button>
        </.form>

        <div class="text-center">
          <.link
            navigate={~p"/users/forgot-password"}
            class="text-[10px] font-black uppercase text-primary tracking-widest hover:underline"
          >
            Forgot your password?
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    email = params["email"] || Phoenix.Flash.get(socket.assigns.flash, :email)
    invite_token = params["invite_token"]

    password_form =
      to_form(%{"email" => email, "remember_me" => "true"}, as: "user")

    {:ok,
     assign(socket,
       password_form: password_form,
       trigger_submit: false,
       invite_token: invite_token,
       remember_me: true
     )}
  end

  @impl true
  def handle_event("submit_password", %{"user" => params}, socket) do
    socket =
      socket
      |> assign(:password_form, to_form(params, as: "user"))
      |> assign(:trigger_submit, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_remember_me", _params, socket) do
    socket =
      socket
      |> update(:remember_me, &(!&1))
      |> assign(
        :password_form,
        toggle_remember_me_in_form(socket.assigns.password_form, socket.assigns.remember_me)
      )

    {:noreply, socket}
  end

  defp toggle_remember_me_in_form(form, remember_me) do
    params =
      form.params
      |> Map.put("remember_me", if(remember_me, do: "true", else: "false"))

    to_form(params, as: "user")
  end
end
