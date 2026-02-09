defmodule AppPlanner.Planner.CustomField do
  use Ecto.Schema
  import Ecto.Changeset

  alias AppPlanner.Planner.Workspace

  schema "custom_fields" do
    field :name, :string
    field :field_type, :string # e.g., "text", "number", "select"
    field :options, :map # for select/multi-select fields
    belongs_to :workspace, Workspace

    timestamps()
  end

  @doc false
  def changeset(custom_field, attrs) do
    custom_field
    |> cast(attrs, [:name, :field_type, :options, :workspace_id])
    |> validate_required([:name, :field_type, :workspace_id])
    |> unique_constraint(:name, scope: [:workspace_id])
    |> validate_inclusion(:field_type, ["text", "number", "select", "checkbox", "date"]) # Example field types
  end
end
