defmodule AppPlannerWeb.PageControllerTest do
  use AppPlannerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "App Planner"
  end

  test "GET /workspaces/:id/apps redirects to workspace overview", %{conn: conn} do
    user = AppPlanner.AccountsFixtures.user_fixture()
    conn = log_in_user(conn, user)
    assert [workspace | _] = AppPlanner.Workspaces.list_user_workspaces(user)

    conn = get(conn, ~p"/workspaces/#{workspace.id}/apps")
    assert redirected_to(conn) == ~p"/workspaces/#{workspace.id}"
  end
end
