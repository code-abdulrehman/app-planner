defmodule AppPlannerWeb.FeatureLiveTest do
  use AppPlannerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AppPlanner.PlannerFixtures

  @create_attrs %{description: "some description", title: "some title", cons: "some cons", how_to_add: "some how_to_add", why: "some why", pros: "some pros", implementation_date: "2026-01-29", how_to_implement: "some how_to_implement", why_need: "some why_need", time_estimate: "some time_estimate"}
  @update_attrs %{description: "some updated description", title: "some updated title", cons: "some updated cons", how_to_add: "some updated how_to_add", why: "some updated why", pros: "some updated pros", implementation_date: "2026-01-30", how_to_implement: "some updated how_to_implement", why_need: "some updated why_need", time_estimate: "some updated time_estimate"}
  @invalid_attrs %{description: nil, title: nil, cons: nil, how_to_add: nil, why: nil, pros: nil, implementation_date: nil, how_to_implement: nil, why_need: nil, time_estimate: nil}
  defp create_feature(_) do
    feature = feature_fixture()

    %{feature: feature}
  end

  describe "Index" do
    setup [:create_feature]

    test "lists all features", %{conn: conn, feature: feature} do
      {:ok, _index_live, html} = live(conn, ~p"/features")

      assert html =~ "Listing Features"
      assert html =~ feature.title
    end

    test "saves new feature", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/features")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Feature")
               |> render_click()
               |> follow_redirect(conn, ~p"/features/new")

      assert render(form_live) =~ "New Feature"

      assert form_live
             |> form("#feature-form", feature: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#feature-form", feature: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/features")

      html = render(index_live)
      assert html =~ "Feature created successfully"
      assert html =~ "some title"
    end

    test "updates feature in listing", %{conn: conn, feature: feature} do
      {:ok, index_live, _html} = live(conn, ~p"/features")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#features-#{feature.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/features/#{feature}/edit")

      assert render(form_live) =~ "Edit Feature"

      assert form_live
             |> form("#feature-form", feature: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#feature-form", feature: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/features")

      html = render(index_live)
      assert html =~ "Feature updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes feature in listing", %{conn: conn, feature: feature} do
      {:ok, index_live, _html} = live(conn, ~p"/features")

      assert index_live |> element("#features-#{feature.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#features-#{feature.id}")
    end
  end

  describe "Show" do
    setup [:create_feature]

    test "displays feature", %{conn: conn, feature: feature} do
      {:ok, _show_live, html} = live(conn, ~p"/features/#{feature}")

      assert html =~ "Show Feature"
      assert html =~ feature.title
    end

    test "updates feature and returns to show", %{conn: conn, feature: feature} do
      {:ok, show_live, _html} = live(conn, ~p"/features/#{feature}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/features/#{feature}/edit?return_to=show")

      assert render(form_live) =~ "Edit Feature"

      assert form_live
             |> form("#feature-form", feature: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#feature-form", feature: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/features/#{feature}")

      html = render(show_live)
      assert html =~ "Feature updated successfully"
      assert html =~ "some updated title"
    end
  end
end
