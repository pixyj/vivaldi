defmodule Vivaldi.Peer.Supervisor do
  @moduledoc """
  Supervises all Vivaldi algorithm related processes, i.e. doesn't care about experiment setup
  Scaffolding copied from https://hexdocs.pm/elixir/Supervisor.html
  """

  use Supervisor

  alias Vivaldi.Peer.ExperimentCoordinator

  def start_link(node_id) do
    Supervisor.start_link(__MODULE__, [node_id])
  end

  def init([node_id]) do
    {:ok, state_agent} = Agent.start_link fn -> {:not_started, nil} end, []
    children = [
      worker(ExperimentCoordinator, [node_id, state_agent]),
    ]
    supervise(children, strategy: :one_for_one)
  end

end


