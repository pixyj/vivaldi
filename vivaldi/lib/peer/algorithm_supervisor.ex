defmodule Vivaldi.Peer.AlgorithmSupervisor do
  @moduledoc """
  Supervises all Vivaldi algorithm related processes, i.e. doesn't care about experiment setup
  Scaffolding copied from https://hexdocs.pm/elixir/Supervisor.html
  """

  use Supervisor

  alias Vivaldi.Peer.{Connections, Coordinate, CoordinateLogger, CoordinateStash, PingClient, PingServer}

  def start_link(config) do
    Supervisor.start_link(__MODULE__, [config])
  end

  def init([config]) do
    children = [
      worker(Connections, [config]),
      worker(CoordinateStash, [config]),
      worker(CoordinateLogger, [config]),
      worker(Coordinate, [config]),
      worker(PingServer, [config]),
      worker(PingClient, [config])
    ]
    
    supervise(children, strategy: :one_for_one)
  end

end


