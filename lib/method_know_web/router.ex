defmodule MethodKnowWeb.Router do
  use MethodKnowWeb, :router

  import MethodKnowWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MethodKnowWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", MethodKnowWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:method_know, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MethodKnowWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MethodKnowWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MethodKnowWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/resources", ResourceLive.Index, :index
      live "/my/resources", ResourceLive.Index, :my
      live "/resources/new", ResourceLive.Form, :new
      live "/resources/:id", ResourceLive.Show, :show
      live "/resources/:id/edit", ResourceLive.Form, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", MethodKnowWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{MethodKnowWeb.UserAuth, :mount_current_scope}] do
      live "/", ResourceLive.Index, :index
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    get "/users/confirm-registration/:token", UserSessionController, :confirm_registration
    delete "/users/log-out", UserSessionController, :delete

    # Catch-all route for 404s to ensure the browser pipeline (session) is loaded
    get "/*path", ErrorController, :not_found
  end
end
