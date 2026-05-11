defmodule SoireePlateau.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SoireePlateauWeb.Telemetry,
      SoireePlateau.Repo,
      {DNSCluster, query: Application.get_env(:soiree_plateau, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SoireePlateau.PubSub},
      # Start a worker by calling: SoireePlateau.Worker.start_link(arg)
      # {SoireePlateau.Worker, arg},
      # Start to serve requests, typically the last entry
      SoireePlateauWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SoireePlateau.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SoireePlateauWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
