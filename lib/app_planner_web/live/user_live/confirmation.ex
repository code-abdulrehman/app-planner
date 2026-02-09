defmodule AppPlannerWeb.UserLive.Confirmation do
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
            You're signing in as <span class="text-primary font-bold">{@user.email}</span>
          </p>
       </div>

       <div class="bg-base-50/50 border border-base-200 rounded-lg p-8 space-y-6">
          <.form
            :if={!@user.confirmed_at}
            for={@form}
            id="confirmation_form"
            phx-mounted={JS.focus_first()}
            phx-submit="submit"
            action={~p"/users/log-in?_action=confirmed"}
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <button type="submit" name={@form[:remember_me].name} value="true" phx-disable-with="Confirming..." class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">
              Confirm & Secure Session
            </button>
            <button type="submit" phx-disable-with="Confirming..." class="btn btn-outline w-full rounded-lg text-[10px] font-black uppercase tracking-widest border-base-200">
              Confirm for this session only
            </button>
          </.form>

          <.form
            :if={@user.confirmed_at}
            for={@form}
            id="login_form"
            phx-submit="submit"
            phx-mounted={JS.focus_first()}
            action={~p"/users/log-in"}
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
            <%= if @current_scope do %>
              <button type="submit" phx-disable-with="Logging in..." class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">
                Log In
              </button>
            <% else %>
              <button type="submit" name={@form[:remember_me].name} value="true" phx-disable-with="Logging in..." class="btn btn-primary w-full rounded-lg text-[10px] font-black uppercase tracking-widest shadow-lg shadow-primary/20">
                Secure Log In
              </button>
              <button type="submit" phx-disable-with="Logging in..." class="btn btn-outline w-full rounded-lg text-[10px] font-black uppercase tracking-widest border-base-200">
                Log in for this session only
              </button>
            <% end %>
          </.form>
       </div>

       <div :if={!@user.confirmed_at} class="mt-8 p-4 bg-base-100 border border-base-200 rounded-lg">
          <p class="text-[9px] font-black uppercase text-base-content/40 tracking-widest leading-relaxed">
            Tip: You can enable password-based login in your account settings once confirmed.
          </p>
       </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
