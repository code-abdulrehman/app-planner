defmodule AppPlannerWeb.UserLive.Login do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto py-24 px-6 text-center">
       <div class="mb-12">
          <div class="w-16 h-16 bg-primary rounded-xl flex items-center justify-center text-primary-content font-black text-2xl shadow-lg shadow-primary/20 mx-auto mb-6">A</div>
          <h1 class="text-3xl font-black tracking-tight text-base-content mb-2">Welcome Back</h1>
          <p class="text-sm text-base-content/40 font-medium italic">
            <%= if @current_scope do %>
              Identity verification required
            <% else %>
              Don't have an account? <.link navigate={~p"/users/register"} class="text-primary hover:underline font-bold">Register</.link>
            <% end %>
          </p>
       </div>

       <div class="bg-base-50/50 border border-base-200 rounded-lg p-8 space-y-8">
          <.form
            :let={f}
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
            class="space-y-6"
          >
            <div class="form-control text-left">
               <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Email Address</span></label>
               <.input readonly={!!@current_scope} field={f[:email]} type="email" placeholder="name@example.com" required class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
            </div>
            <button type="submit" class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">
              Send Magic Link
            </button>
          </.form>

          <div class="divider text-[10px] font-black uppercase text-base-content/20 tracking-widest">or use password</div>

          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-6"
          >
            <div class="form-control text-left">
               <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Password</span></label>
               <.input field={@form[:password]} type="password" placeholder="••••••••" required class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
            </div>

            <div class="flex items-center justify-between">
               <div class="flex items-center gap-2">
                  <input type="checkbox" name={@form[:remember_me].name} value="true" class="checkbox checkbox-primary checkbox-xs rounded" />
                  <span class="text-[10px] font-black uppercase text-base-content/40 tracking-widest">Stay logged in</span>
               </div>
               <.link navigate={~p"/users/forgot-password"} class="text-[10px] font-black uppercase text-primary tracking-widest hover:underline">
                 Reset Password
               </.link>
            </div>

            <button type="submit" class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">
              Log In
            </button>
          </.form>
       </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:app_planner, AppPlanner.Mailer)[:adapter] == Swoosh.Adapters.Local
  end

  defp dev_mode? do
    Application.get_env(:app_planner, :dev_routes, false)
  end
end
