defmodule AppPlannerWeb.Router do
  use AppPlannerWeb, :router

  import AppPlannerWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AppPlannerWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_scope_for_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AppPlannerWeb do
    pipe_through(:browser)

    live_session :home,
      on_mount: [{AppPlannerWeb.UserAuth, :mount_current_scope}] do
      live("/", HomeLive, :index)
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:app_planner, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: AppPlannerWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", AppPlannerWeb do
    pipe_through([:browser, :require_authenticated_user])

    get("/workspaces/:workspace_id/apps", PageController, :redirect_workspace_apps)

    live_session :require_authenticated_user,
      on_mount: [
        {AppPlannerWeb.UserAuth, :require_authenticated},
        {AppPlannerWeb.WorkspaceSelector, :load_current_workspace}
      ],
      layout: {AppPlannerWeb.Layouts, :app} do
      live("/users/settings", UserLive.Settings, :edit)
      live("/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email)
      live("/users/admin", UserLive.Admin, :index)

      live("/workspaces", WorkspaceLive.Index, :index)
      live("/workspaces/new", WorkspaceLive.Form, :new)
      live("/workspaces/:id", WorkspaceLive.Show, :show)
      live("/workspaces/:id/edit", WorkspaceLive.Form, :edit)

      live("/board", TaskLive.Index, :index)
      live("/workspaces/:workspace_id/board", TaskLive.Index, :index)

      scope "/workspaces/:workspace_id", as: :workspace do
        live("/apps/new", AppLive.Form, :new)
        live("/apps/:id", AppLive.Show, :show)
        live("/apps/:id/edit", AppLive.Form, :edit)

        live("/apps/:app_id/features/new", FeatureLive.Form, :new)
        live("/apps/:app_id/features/:id", FeatureLive.Show, :show)
        live("/apps/:app_id/features/:id/edit", FeatureLive.Form, :edit)

        # Tasks nested under features (handled as modals on the board)
        live("/apps/:app_id/features/:feature_id/tasks", TaskLive.Index, :index)
        live("/apps/:app_id/features/:feature_id/tasks/add_column", TaskLive.Index, :add_column)

        live(
          "/apps/:app_id/features/:feature_id/tasks/rename_column",
          TaskLive.Index,
          :rename_column
        )

        live("/apps/:app_id/features/:feature_id/tasks/new", TaskLive.Index, :new_task)
        live("/apps/:app_id/features/:feature_id/tasks/:id", TaskLive.Index, :show_task)
        live("/apps/:app_id/features/:feature_id/tasks/:id/edit", TaskLive.Index, :edit_task)
      end
    end

    post("/users/update-password", UserSessionController, :update_password)
  end

  scope "/", AppPlannerWeb do
    pipe_through([:browser])

    live_session :current_user,
      on_mount: [{AppPlannerWeb.UserAuth, :mount_current_scope}],
      layout: {AppPlannerWeb.Layouts, :app} do
      live("/users/register", UserLive.Registration, :new)
      live("/users/log-in", UserLive.Login, :new)
      live("/users/log-in/:token", UserLive.Confirmation, :new)
      live("/users/forgot-password", UserLive.ForgotPassword, :new)
      live("/invite/:token", WorkspaceLive.InvitationAccept, :accept)
    end

    post("/users/log-in", UserSessionController, :create)
    delete("/users/log-out", UserSessionController, :delete)
  end
end
