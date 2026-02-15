defmodule AppPlannerWeb.WorkspaceLive.InvitationAccept do
  use AppPlannerWeb, :live_view

  alias AppPlanner.Workspaces

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    current_user = socket.assigns.current_scope.user

    case Workspaces.accept_invite_link(token, current_user) do
      {:ok, _user, workspace} ->
        # Successfully added to workspace
        {:ok,
         socket
         |> put_flash(:info, "You have successfully joined the workspace '#{workspace.name}'.")
         |> push_navigate(to: ~p"/workspaces/#{workspace.id}/board")}

      {:prompt_register, invited_email, workspace} ->
        # User needs to register, redirect to registration with invite_token
        {:ok,
         socket
         |> put_flash(:info, "Please create an account to join '#{workspace.name}'.")
         |> push_navigate(to: ~p"/users/register?email=#{invited_email}&invite_token=#{token}")}

      {:error, :invalid_or_expired_token} ->
        {:ok,
         socket
         |> put_flash(:error, "The invitation link is invalid or has expired.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, :email_mismatch} ->
        {:ok,
         socket
         |> put_flash(
           :error,
           "The invited email does not match your logged-in account. Please log in with the correct email or register."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, reason} ->
        {:ok,
         socket
         |> put_flash(:error, "Failed to accept invitation: #{inspect(reason)}")
         |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm text-center">
      <.header>Processing Invitation...</.header>
      <p class="mt-4 text-sm text-gray-700">Please wait while we process your invitation.</p>
    </div>
    """
  end
end
