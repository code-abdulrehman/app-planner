defmodule AppPlanner.Planner.Label do
  use Ecto.Schema
  import Ecto.Changeset

  schema "labels" do
    field(:title, :string)
    field(:color, :string)
    field(:description, :string)
    belongs_to(:user, AppPlanner.Accounts.User)
    many_to_many(:apps, AppPlanner.Planner.App, join_through: "apps_labels")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:title, :color, :description, :user_id])
    |> validate_required([:title, :color, :user_id])
    |> unique_constraint([:user_id, :title], name: :labels_user_id_title_index)
  end
end
