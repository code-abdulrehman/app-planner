defmodule AppPlanner.Planner.App do
  use Ecto.Schema
  import Ecto.Changeset

  schema "apps" do
    field(:name, :string)
    field(:icon, :string)
    field(:description, :string)
    field(:status, :string, default: "Idea")
    field(:visibility, :string, default: "private")
    field(:category, :string)
    field(:pr_link, :string)
    field(:custom_fields, :map, default: %{})

    belongs_to(:user, AppPlanner.Accounts.User)
    belongs_to(:parent_app, AppPlanner.Planner.App)
    belongs_to(:last_updated_by, AppPlanner.Accounts.User)
    has_many(:children, AppPlanner.Planner.App, foreign_key: :parent_app_id)
    has_many(:features, AppPlanner.Planner.Feature, on_delete: :delete_all)
    has_many(:likes, AppPlanner.Planner.Like, on_delete: :delete_all)
    has_many(:app_members, AppPlanner.Planner.AppMember, on_delete: :delete_all)

    many_to_many(:labels, AppPlanner.Planner.Label,
      join_through: "apps_labels",
      on_replace: :delete
    )

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
      :parent_app_id,
      :last_updated_by_id,
      :status,
      :visibility,
      :category,
      :pr_link,
      :custom_fields
    ])
    |> validate_required([:name, :description, :status, :visibility, :category])
    |> validate_inclusion(:visibility, ["private", "public"])
    |> validate_inclusion(:status, ~w(Idea Planned In\ Progress Completed Archived))
  end
end
