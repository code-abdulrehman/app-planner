defmodule AppPlanner.Planner.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "app_likes" do
    belongs_to(:user, AppPlanner.Accounts.User)
    belongs_to(:app, AppPlanner.Planner.App)

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :app_id])
    |> validate_required([:user_id, :app_id])
    |> unique_constraint([:user_id, :app_id])
  end
end
