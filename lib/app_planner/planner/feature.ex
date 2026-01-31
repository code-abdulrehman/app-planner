defmodule AppPlanner.Planner.Feature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "features" do
    field(:title, :string)
    field(:icon, :string)
    field(:description, :string)
    field(:how_to_add, :string)
    field(:why, :string)
    field(:pros, :string)
    field(:cons, :string)
    field(:implementation_date, :date)
    field(:how_to_implement, :string)
    field(:why_need, :string)
    field(:time_estimate, :string)
    field(:pr_link, :string)
    field(:status, :string, default: "Planned")
    field(:custom_fields, :map, default: %{})
    belongs_to(:app, AppPlanner.Planner.App)
    belongs_to(:user, AppPlanner.Accounts.User)
    belongs_to(:last_updated_by, AppPlanner.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(feature, attrs) do
    feature
    |> cast(attrs, [
      :title,
      :icon,
      :description,
      :how_to_add,
      :why,
      :pros,
      :cons,
      :implementation_date,
      :how_to_implement,
      :why_need,
      :time_estimate,
      :pr_link,
      :status,
      :custom_fields,
      :app_id,
      :user_id,
      :last_updated_by_id
    ])
    |> validate_required([:title, :description, :user_id])
  end
end
