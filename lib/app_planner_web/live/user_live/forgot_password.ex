defmodule AppPlannerWeb.UserLive.ForgotPassword do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Forgot password?
            <:subtitle>
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                Back to Log in
              </.link>
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="forgot_form" phx-submit="send_link">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">Send me a login link</.button>
        </.form>
      </div>
    </Layouts.app>
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
