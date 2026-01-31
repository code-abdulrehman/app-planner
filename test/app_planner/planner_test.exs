defmodule AppPlanner.PlannerTest do
  use AppPlanner.DataCase

  alias AppPlanner.Planner

  describe "apps" do
    alias AppPlanner.Planner.App

    import AppPlanner.PlannerFixtures

    @invalid_attrs %{name: nil, description: nil, icon: nil}

    test "list_apps/0 returns all apps" do
      app = app_fixture()
      assert Planner.list_apps() == [app]
    end

    test "get_app!/1 returns the app with given id" do
      app = app_fixture()
      assert Planner.get_app!(app.id) == app
    end

    test "create_app/1 with valid data creates a app" do
      valid_attrs = %{name: "some name", description: "some description", icon: "some icon"}

      assert {:ok, %App{} = app} = Planner.create_app(valid_attrs)
      assert app.name == "some name"
      assert app.description == "some description"
      assert app.icon == "some icon"
    end

    test "create_app/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Planner.create_app(@invalid_attrs)
    end

    test "update_app/2 with valid data updates the app" do
      app = app_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", icon: "some updated icon"}

      assert {:ok, %App{} = app} = Planner.update_app(app, update_attrs)
      assert app.name == "some updated name"
      assert app.description == "some updated description"
      assert app.icon == "some updated icon"
    end

    test "update_app/2 with invalid data returns error changeset" do
      app = app_fixture()
      assert {:error, %Ecto.Changeset{}} = Planner.update_app(app, @invalid_attrs)
      assert app == Planner.get_app!(app.id)
    end

    test "delete_app/1 deletes the app" do
      app = app_fixture()
      assert {:ok, %App{}} = Planner.delete_app(app)
      assert_raise Ecto.NoResultsError, fn -> Planner.get_app!(app.id) end
    end

    test "change_app/1 returns a app changeset" do
      app = app_fixture()
      assert %Ecto.Changeset{} = Planner.change_app(app)
    end
  end

  describe "features" do
    alias AppPlanner.Planner.Feature

    import AppPlanner.PlannerFixtures

    @invalid_attrs %{description: nil, title: nil, cons: nil, how_to_add: nil, why: nil, pros: nil, implementation_date: nil, how_to_implement: nil, why_need: nil, time_estimate: nil}

    test "list_features/0 returns all features" do
      feature = feature_fixture()
      assert Planner.list_features() == [feature]
    end

    test "get_feature!/1 returns the feature with given id" do
      feature = feature_fixture()
      assert Planner.get_feature!(feature.id) == feature
    end

    test "create_feature/1 with valid data creates a feature" do
      valid_attrs = %{description: "some description", title: "some title", cons: "some cons", how_to_add: "some how_to_add", why: "some why", pros: "some pros", implementation_date: ~D[2026-01-29], how_to_implement: "some how_to_implement", why_need: "some why_need", time_estimate: "some time_estimate"}

      assert {:ok, %Feature{} = feature} = Planner.create_feature(valid_attrs)
      assert feature.description == "some description"
      assert feature.title == "some title"
      assert feature.cons == "some cons"
      assert feature.how_to_add == "some how_to_add"
      assert feature.why == "some why"
      assert feature.pros == "some pros"
      assert feature.implementation_date == ~D[2026-01-29]
      assert feature.how_to_implement == "some how_to_implement"
      assert feature.why_need == "some why_need"
      assert feature.time_estimate == "some time_estimate"
    end

    test "create_feature/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Planner.create_feature(@invalid_attrs)
    end

    test "update_feature/2 with valid data updates the feature" do
      feature = feature_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", cons: "some updated cons", how_to_add: "some updated how_to_add", why: "some updated why", pros: "some updated pros", implementation_date: ~D[2026-01-30], how_to_implement: "some updated how_to_implement", why_need: "some updated why_need", time_estimate: "some updated time_estimate"}

      assert {:ok, %Feature{} = feature} = Planner.update_feature(feature, update_attrs)
      assert feature.description == "some updated description"
      assert feature.title == "some updated title"
      assert feature.cons == "some updated cons"
      assert feature.how_to_add == "some updated how_to_add"
      assert feature.why == "some updated why"
      assert feature.pros == "some updated pros"
      assert feature.implementation_date == ~D[2026-01-30]
      assert feature.how_to_implement == "some updated how_to_implement"
      assert feature.why_need == "some updated why_need"
      assert feature.time_estimate == "some updated time_estimate"
    end

    test "update_feature/2 with invalid data returns error changeset" do
      feature = feature_fixture()
      assert {:error, %Ecto.Changeset{}} = Planner.update_feature(feature, @invalid_attrs)
      assert feature == Planner.get_feature!(feature.id)
    end

    test "delete_feature/1 deletes the feature" do
      feature = feature_fixture()
      assert {:ok, %Feature{}} = Planner.delete_feature(feature)
      assert_raise Ecto.NoResultsError, fn -> Planner.get_feature!(feature.id) end
    end

    test "change_feature/1 returns a feature changeset" do
      feature = feature_fixture()
      assert %Ecto.Changeset{} = Planner.change_feature(feature)
    end
  end
end
