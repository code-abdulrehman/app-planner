defmodule AppPlannerWeb.PageController do
  use AppPlannerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
