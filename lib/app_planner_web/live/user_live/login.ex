defmodule AppPlannerWeb.UserLive.Login do
  use AppPlannerWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto py-24 px-6 text-center">
      <div class="mb-12">
        <div class="w-16 h-16 bg-primary rounded-xl flex items-center justify-center text-primary-content font-black text-2xl shadow-lg shadow-primary/20 mx-auto mb-6">
           <.icon name="hero-cursor-arrow-ripple" class="w-4 h-4" />
        </div>
        <h1 class="text-3xl font-black tracking-tight text-base-content mb-2">Welcome Back</h1>
        <p class="text-sm text-base-content/40 font-medium italic">
          Don't have an account?
          <.link navigate={~p"/users/register"} class="text-primary hover:underline font-bold">
            Register
          </.link>
        </p>
      </div>

      <div class="bg-base-50/50 border border-base-200 rounded-lg p-3 w-[400px]">
        <.form
          for={@form}
          id="login_form"
          action={
            if @invite_token,
              do: ~p"/users/log-in?invite_token=#{@invite_token}",
              else: ~p"/users/log-in"
          }
          phx-change="validate"
          phx-submit="submit"
          phx-trigger-action={@trigger_submit}
          class="space-y-6"
        >
          <div class="form-control text-left">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Email Address
              </span>
            </label>
            <.input
              field={@form[:email]}
              type="email"
              placeholder="name@example.com"
              required
              class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              autocomplete="username"
            />
          </div>

          <div class="form-control text-left">
            <label class="label">
              <span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">
                Password
              </span>
            </label>
            <.input
              field={@form[:password]}
              type="password"
              placeholder="••••••••"
              required
              class="input input-bordered w-full rounded-lg bg-base-100 font-bold"
              autocomplete="current-password"
            />
          </div>

        <!--  <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <input
                type="checkbox"
                name={@form[:remember_me].name}
                value="true"
                class="checkbox checkbox-primary checkbox-xs rounded"
              />
              <span class="text-[10px] font-black uppercase text-base-content/40 tracking-widest">
                Stay logged in
              </span>
            </div>
            <.link
              navigate={~p"/users/forgot-password"}
              class="text-[10px] font-black uppercase text-primary tracking-widest hover:underline"
            >
              Reset Password
            </.link>
          </div> -->

          <button
            type="submit"
            class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20"
          >
            Log In
          </button>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    email = params["email"] || Phoenix.Flash.get(socket.assigns.flash, :email)
    invite_token = params["invite_token"]
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form, trigger_submit: false, invite_token: invite_token)}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"))}
  end

  @impl true
  def handle_event("submit", %{"user" => _params}, socket) do
    # For password login, we need to pass the invite_token to the controller
    # This might require adding a hidden field to the form
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  @impl true
  def handle_event("send_magic_link", _params, socket) do
    email = socket.assigns.form[:email].value
    invite_token = socket.assigns.invite_token

    if email && email != "" do
      # If we have an invite_token, we want to redirect to /invite/:token after login
      # We can't easily pass 'return_to' through magic links without building it into the token context
      # But we can append it as a param to the confirmation URL
      magic_link_url =
        if invite_token do
          &url(~p"/users/log-in/#{&1}?invite_token=#{invite_token}")
        else
          &url(~p"/users/log-in/#{&1}")
        end

      case AppPlanner.Accounts.register_or_login_with_magic_link(email, magic_link_url) do
        {:ok, _user} ->
          {:noreply,
           socket
           |> put_flash(:info, "Check your email for a secure login link.")
           |> push_navigate(to: ~p"/users/log-in")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Something went wrong. Please check your email and try again.")}
      end
    else
      {:noreply, socket |> put_flash(:error, "Please enter your email address first.")}
    end
  end
end
