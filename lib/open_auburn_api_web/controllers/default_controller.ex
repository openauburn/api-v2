defmodule OpenAuburnApiWeb.DefaultController do
  use OpenAuburnApiWeb, :controller

  def index(conn, _params) do
    text conn, "Hello World XP"
  end

end
