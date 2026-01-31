defmodule AppPlanner.PlannerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AppPlanner.Planner` context.
  """

  @doc """
  Generate a app.
  """
  def app_fixture(attrs \\ %{}) do
    {:ok, app} =
      attrs
      |> Enum.into(%{
        description: "some description",
        icon: "some icon",
        name: "some name"
      })
      |> AppPlanner.Planner.create_app()

    app
  end

  @doc """
  Generate a feature.
  """
  def feature_fixture(attrs \\ %{}) do
    {:ok, feature} =
      attrs
      |> Enum.into(%{
        cons: "some cons",
        description: "some description",
        how_to_add: "some how_to_add",
        how_to_implement: "some how_to_implement",
        implementation_date: ~D[2026-01-29],
        pros: "some pros",
        time_estimate: "some time_estimate",
        title: "some title",
        why: "some why",
        why_need: "some why_need"
      })
      |> AppPlanner.Planner.create_feature()

    feature
  end
end
