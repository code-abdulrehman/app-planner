defmodule AppPlannerWeb.PageController do
  use AppPlannerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  @doc "Legacy project library URL; workspace overview lists projects."
  def redirect_workspace_apps(conn, %{"workspace_id" => workspace_id}) do
    redirect(conn, to: ~p"/workspaces/#{workspace_id}")
  end
end
