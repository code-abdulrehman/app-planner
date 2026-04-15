defmodule AppPlanner.Planner.App do
  use Ecto.Schema
  import Ecto.Changeset

  schema "apps" do
    field(:name, :string)
    field(:icon, :string)
    field(:description, :string)
    field(:status, :string, default: "Idea")
    field(:status_config, :map)

    belongs_to(:user, AppPlanner.Accounts.User)
    belongs_to(:last_updated_by, AppPlanner.Accounts.User)
    belongs_to(:workspace, AppPlanner.Planner.Workspace)
    has_many(:features, AppPlanner.Planner.Feature, on_delete: :delete_all)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> cast(attrs, [
      :name,
      :icon,
      :description,
      :user_id,
      :last_updated_by_id,
      :status,
      :workspace_id,
      :status_config
    ])
    |> validate_required([:name, :status, :workspace_id])
    |> validate_inclusion(
      :status,
      ["Idea", "Planned", "In Progress", "Completed", "Archived"]
    )
  end
end
