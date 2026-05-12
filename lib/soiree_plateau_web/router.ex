defmodule SoireePlateauWeb.Router do
  use SoireePlateauWeb, :router

  import SoireePlateauWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SoireePlateauWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SoireePlateauWeb do
    pipe_through :browser

    live "/", UserLive.Home, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", SoireePlateauWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:soiree_plateau, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SoireePlateauWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/users", SoireePlateauWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{SoireePlateauWeb.UserAuth, :require_authenticated}] do
      live "/settings", UserLive.Settings, :edit
      live "/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/games", UserLive.Game.ListGames, :index
      live "/games/:id", UserLive.Game.DetailGame, :show

      live "/soirees", SoireeLive.Index, :index
      live "/soirees/new", SoireeLive.Form, :new
      live "/soirees/:id", SoireeLive.Show, :show
      live "/soirees/:id/edit", SoireeLive.Form, :edit
    end

    post "/update-password", UserSessionController, :update_password
  end

  scope "/users", SoireePlateauWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{SoireePlateauWeb.UserAuth, :mount_current_scope}] do
      live "/register", UserLive.Registration, :new
      live "/log-in", UserLive.Login, :new
      live "/log-in/:token", UserLive.Confirmation, :new
    end

    post "/log-in", UserSessionController, :create
    delete "/log-out", UserSessionController, :delete
  end

  scope "/admin", SoireePlateauWeb do
    pipe_through [:browser]

    live_session :current_user_admin,
      on_mount: [{SoireePlateauWeb.UserAuth, :require_authenticated_admin}] do
      live "/games", GameLive.Index, :index
      live "/games/new", GameLive.Form, :new
      live "/games/:id", GameLive.Show, :show
      live "/games/:id/edit", GameLive.Form, :edit
    end
  end
end
