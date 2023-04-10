defmodule OpenAuburnApiWeb.Router do
  use OpenAuburnApiWeb, :router
  import Plug.Conn
  import Phoenix.LiveDashboard.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admins_only do
    plug :admin_basic_auth
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end


  scope "/api", OpenAuburnApiWeb do
    pipe_through :api
    get "/", DefaultController, :index
  end

  scope "/datasets/:table_name", OpenAuburnApiWeb do
    pipe_through :api
    get "/", DatasetController, :index
  end

  scope "/" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: OpenAuburnApiWeb.Telemetry
  end

  defp admin_basic_auth(conn, _opts) do
    username = System.fetch_env!("AUTH_USERNAME")
    password = System.fetch_env!("AUTH_PASSWORD")
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

end
