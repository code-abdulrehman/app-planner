defmodule AppPlanner.Repo do
  use Ecto.Repo,
    otp_app: :app_planner,
    adapter: Ecto.Adapters.Postgres
end
