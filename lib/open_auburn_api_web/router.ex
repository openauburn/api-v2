defmodule OpenAuburnApiWeb.Router do
  use OpenAuburnApiWeb, :router
  import Plug.Conn

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", OpenAuburnApiWeb do
    pipe_through :api
    get "/", DefaultController, :index
  end

  scope "/:table_name", OpenAuburnApiWeb do
    pipe_through :api
    get "/", DatasetController, :index
  end

end
