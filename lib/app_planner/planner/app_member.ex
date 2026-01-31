defmodule AppPlanner.Planner.AppMember do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(viewer editor)

  schema "app_members" do
    field :role, :string, default: "viewer"

    belongs_to :app, AppPlanner.Planner.App
    belongs_to :user, AppPlanner.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:app_id, :user_id, :role])
    |> validate_required([:app_id, :user_id, :role])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:app_id, :user_id])
    |> foreign_key_constraint(:app_id)
    |> foreign_key_constraint(:user_id)
  end
end
