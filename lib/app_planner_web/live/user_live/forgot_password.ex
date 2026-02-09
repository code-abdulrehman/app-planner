defmodule AppPlannerWeb.UserLive.ForgotPassword do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto py-24 px-6 text-center">
       <div class="mb-12">
          <div class="w-16 h-16 bg-primary rounded-xl flex items-center justify-center text-primary-content font-black text-2xl shadow-lg shadow-primary/20 mx-auto mb-6">A</div>
          <h1 class="text-3xl font-black tracking-tight text-base-content mb-2">Reset Password</h1>
          <p class="text-sm text-base-content/40 font-medium italic">
            <span class="opacity-50">Remembered?</span> <.link navigate={~p"/users/log-in"} class="text-primary hover:underline font-bold">Return to Log In</.link>
          </p>
       </div>

       <div class="bg-base-50/50 border border-base-200 rounded-lg p-8">
          <.form for={@form} id="forgot_form" phx-submit="send_link" class="space-y-6">
            <div class="form-control text-left">
               <label class="label"><span class="label-text text-[10px] font-black uppercase tracking-widest text-base-content/40">Email Address</span></label>
               <.input field={@form[:email]} type="email" placeholder="name@example.com" autocomplete="email" required phx-mounted={JS.focus()} class="input input-bordered w-full rounded-lg bg-base-100 font-bold" />
            </div>

            <button type="submit" class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">
              Send Reset Link
            </button>
          </.form>
       </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => ""}, as: "user")
    {:ok, assign(socket, form: form)}
  end

  @impl true
  def handle_event("send_link", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(user, &url(~p"/users/log-in/#{&1}"))
    end

    info = "If your email is in our system, you will receive a login link shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end
end
