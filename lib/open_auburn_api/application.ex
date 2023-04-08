defmodule OpenAuburnApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      OpenAuburnApiWeb.Telemetry,
      # Start the Ecto repository
      OpenAuburnApi.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: OpenAuburnApi.PubSub},
      # Start the Endpoint (http/https)
      OpenAuburnApiWeb.Endpoint
      # Start a worker by calling: OpenAuburnApi.Worker.start_link(arg)
      # {OpenAuburnApi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OpenAuburnApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OpenAuburnApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
