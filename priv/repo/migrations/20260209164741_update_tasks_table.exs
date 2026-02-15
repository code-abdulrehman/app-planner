defmodule AppPlanner.Repo.Migrations.UpdateTasksTable do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add(:due_date, :date)
      add(:time_estimate, :string)
      add(:git_link, :string)
      add(:user_flow, :text)
      add(:icon, :string)
      add(:rationale, :text)
      add(:strategy, :text)
      add(:pros, :text)
      add(:cons, :text)
      add(:custom_fields, :map, default: "{}")
      add(:category, :string)
    end
  end
end
