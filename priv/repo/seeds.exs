# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
alias AppPlanner.Repo
alias AppPlanner.Accounts
alias AppPlanner.Planner

# Get or create a seed user so we can attach labels
user =
  case Accounts.get_user_by_email("seed@example.com") do
    nil ->
      case Accounts.register_user(%{email: "seed@example.com", password: "seedpassword123"}) do
        {:ok, u} -> u
        {:error, _} -> nil
      end
    u ->
      u
  end

# Seed default labels (only if user exists and has no labels yet)
if user && Enum.empty?(Planner.list_labels(user)) do
  [
    %{title: "Bug", color: "#d73a4a", description: "Something isn't working"},
    %{title: "Enhancement", color: "#a2eeef", description: "New feature or request"},
    %{title: "Documentation", color: "#0075ca", description: "Docs and guides"},
    %{title: "Urgent", color: "#b60205", description: "High priority"},
    %{title: "Done", color: "#0e8a16", description: "Completed"}
  ]
  |> Enum.each(fn attrs ->
    {:ok, _} = Planner.create_label(attrs, user)
  end)

  IO.puts("Seeded 5 default labels for seed@example.com")
end
