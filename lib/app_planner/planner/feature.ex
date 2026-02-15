defmodule AppPlanner.Planner.Feature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "features" do
    field(:title, :string)
    field(:icon, :string)
    field(:description, :string)

    belongs_to(:app, AppPlanner.Planner.App)
    belongs_to(:user, AppPlanner.Accounts.User)
    belongs_to(:last_updated_by, AppPlanner.Accounts.User)

    has_many(:tasks, AppPlanner.Planner.Task, on_delete: :delete_all)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feature, attrs) do
    feature
    |> cast(attrs, [
      :title,
      :icon,
      :description,
      :app_id,
      :user_id,
      :last_updated_by_id
    ])
    |> validate_required([:title, :description, :user_id, :app_id])
  end
end
