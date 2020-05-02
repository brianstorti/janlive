defmodule Janlive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      JanliveWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Janlive.PubSub},
      # Start the Endpoint (http/https)
      JanliveWeb.Endpoint,
      {Registry, keys: :unique, name: Janlive.GameRegistry},
      JanliveWeb.RoomLiveMonitor,
      Janlive.GameSupervisor,

      # Start a worker by calling: Janlive.Worker.start_link(arg)
      # {Janlive.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Janlive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    JanliveWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
