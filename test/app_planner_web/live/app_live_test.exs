defmodule AppPlannerWeb.AppLiveTest do
  use AppPlannerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AppPlanner.PlannerFixtures

  @create_attrs %{name: "some name", description: "some description", icon: "some icon"}
  @update_attrs %{name: "some updated name", description: "some updated description", icon: "some updated icon"}
  @invalid_attrs %{name: nil, description: nil, icon: nil}
  defp create_app(_) do
    app = app_fixture()

    %{app: app}
  end

  describe "Index" do
    setup [:create_app]

    test "lists all apps", %{conn: conn, app: app} do
      {:ok, _index_live, html} = live(conn, ~p"/apps")

      assert html =~ "Listing Apps"
      assert html =~ app.name
    end

    test "saves new app", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/apps")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New App")
               |> render_click()
               |> follow_redirect(conn, ~p"/apps/new")

      assert render(form_live) =~ "New App"

      assert form_live
             |> form("#app-form", app: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#app-form", app: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/apps")

      html = render(index_live)
      assert html =~ "App created successfully"
      assert html =~ "some name"
    end

    test "updates app in listing", %{conn: conn, app: app} do
      {:ok, index_live, _html} = live(conn, ~p"/apps")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#apps-#{app.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/apps/#{app}/edit")

      assert render(form_live) =~ "Edit App"

      assert form_live
             |> form("#app-form", app: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#app-form", app: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/apps")

      html = render(index_live)
      assert html =~ "App updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes app in listing", %{conn: conn, app: app} do
      {:ok, index_live, _html} = live(conn, ~p"/apps")

      assert index_live |> element("#apps-#{app.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#apps-#{app.id}")
    end
  end

  describe "Show" do
    setup [:create_app]

    test "displays app", %{conn: conn, app: app} do
      {:ok, _show_live, html} = live(conn, ~p"/apps/#{app}")

      assert html =~ "Show App"
      assert html =~ app.name
    end

    test "updates app and returns to show", %{conn: conn, app: app} do
      {:ok, show_live, _html} = live(conn, ~p"/apps/#{app}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/apps/#{app}/edit?return_to=show")

      assert render(form_live) =~ "Edit App"

      assert form_live
             |> form("#app-form", app: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#app-form", app: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/apps/#{app}")

      html = render(show_live)
      assert html =~ "App updated successfully"
      assert html =~ "some updated name"
    end
  end
end
