defmodule AppPlannerWeb.ScopeFromPath do
  @moduledoc false

  # LiveView can receive stale or partial route params (e.g. longpoll reconnect).
  # Always prefer ids parsed from the real browser path over existing param keys.

  alias AppPlanner.Accounts
  alias AppPlanner.Planner.Workspace
  alias AppPlanner.Workspaces

  @spec merge_scoped_params(map()) :: map()
  def merge_scoped_params(params) when is_map(params) do
    merge_scoped_params(params, nil)
  end

  @doc """
  Merges route params with ids parsed from `uri_or_path` (path or full URL).

  Do not call `Phoenix.LiveView.get_connect_info/2` here — it is only valid inside
  the owning LiveView's `mount/3`. Pass the URI from `handle_params/3`'s `url`
  argument, or read `get_connect_info(:uri)` in `mount/3` and pass it in.
  """
  @spec merge_scoped_params(map(), String.t() | URI.t() | nil) :: map()
  def merge_scoped_params(params, uri_or_path) when is_map(params) do
    merge_from_uri(params, uri_or_path)
  end

  @spec align_current_workspace(Phoenix.LiveView.Socket.t(), map()) :: Phoenix.LiveView.Socket.t()
  def align_current_workspace(socket, params) do
    wid = Map.get(params, "workspace_id")
    user = socket.assigns.current_scope.user
    current = socket.assigns[:current_workspace]

    cond do
      is_nil(wid) ->
        socket

      is_struct(current, Workspace) and to_string(current.id) == to_string(wid) ->
        socket

      true ->
        try do
          workspace = Workspaces.get_workspace!(wid)

          if Workspaces.can_view?(user, workspace) or Accounts.super_admin?(user) do
            Phoenix.Component.assign(socket, :current_workspace, workspace)
          else
            socket
          end
        rescue
          _ -> socket
        end
    end
  end

  defp merge_from_uri(params, nil), do: params

  defp merge_from_uri(params, uri_or_path) do
    path = to_path(uri_or_path)
    if path == "", do: params, else: merge_path(params, path)
  end

  defp to_path(nil), do: ""

  defp to_path(%URI{path: p}) when is_binary(p), do: p
  defp to_path(%URI{path: nil}), do: ""

  defp to_path(s) when is_binary(s) do
    if String.starts_with?(s, "/") do
      s
    else
      case URI.parse(s) do
        %URI{path: p} when is_binary(p) -> p
        _ -> ""
      end
    end
  end

  defp merge_path(params, path) do
    cond do
      m = Regex.run(~r{^/workspaces/([^/]+)/apps/([^/]+)/features/([^/]+)/edit$}, path) ->
        [_p, ws, app_id, id] = m
        params |> Map.put("workspace_id", ws) |> Map.put("app_id", app_id) |> Map.put("id", id)

      m = Regex.run(~r{^/workspaces/([^/]+)/apps/([^/]+)/features/new$}, path) ->
        [_p, ws, app_id] = m
        params |> Map.put("workspace_id", ws) |> Map.put("app_id", app_id)

      m =
          Regex.run(
            ~r{^/workspaces/([^/]+)/apps/([^/]+)/features/([^/]+)/tasks},
            path
          ) ->
        [_p, ws, app_id, feature_id] = m

        params
        |> Map.put("workspace_id", ws)
        |> Map.put("app_id", app_id)
        |> Map.put("feature_id", feature_id)

      m = Regex.run(~r{^/workspaces/([^/]+)/apps/([^/]+)/edit$}, path) ->
        [_p, ws, app_id] = m
        params |> Map.put("workspace_id", ws) |> Map.put("id", app_id)

      m = Regex.run(~r{^/workspaces/([^/]+)/apps/new$}, path) ->
        [_p, ws] = m
        Map.put(params, "workspace_id", ws)

      true ->
        params
    end
  end
end
