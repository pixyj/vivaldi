defmodule Vivaldi.Experiment.Controller do

@moduledoc """
* Broadcasts configuration parameters to all peers, and kicks off experiment.

## Note

Vivaldi is a purely decentralized protocol, and doesn't require a central agent. 
This module exists purely to accelerate debugging
"""

  require Logger

  alias Vivaldi.Peer.{Config, ExperimentCoordinator}

  def connect(peers) do
    peers
    |> Enum.map(fn {_peer_id, peer_name} ->
      status = Node.connect(peer_name)
      if status != true do
        Logger.error "controller - Not connected to #{peer_name}"
      end
      status
    end)
    |> Enum.filter(fn status -> status == true end)
    |> (fn connected -> Enum.count(connected) == Enum.count(peers) end).()
  end

  def get_status(peers, expected_status) do
    peers
    |> Enum.map(fn {peer_id, _} ->
      name = ExperimentCoordinator.get_name(peer_id)
      case :global.whereis_name(name) do
        :undefined ->
          Logger.error "controller - #{name} not found through :global.whereis_name"
          :error
        pid ->
          {:ok, status} = GenServer.call(pid, :get_status)
          if status != expected_status do
            Logger.error "controller - #{name} is in #{status}"
          end
          status
      end
    end)
  end

  def send_command(peers_and_commands) do
    peers_and_commands
    |> Enum.map(fn {{peer_id, _}, command} ->
      name = ExperimentCoordinator.get_name(peer_id)
      case :global.whereis_name(name) do
        :undefined ->
          Logger.error "controller - #{name} not found through :global.whereis_name"
          :error
        pid ->
          Logger.info "controller - sending command #{inspect command}"
          result = GenServer.call(pid, command)
          {peer_id, result}
      end
    end)
  end

  def generate_peer_configs(peers, base_config) do
    Enum.map(peers, fn {peer_id, peer_name} ->
      peer_config = [node_id: peer_id,
                     node_name: peer_name,
                     peers: other_nodes(peers, peer_id)
                    ]
      Keyword.merge(base_config, peer_config) |> Config.new()
    end)
  end

  defp other_nodes(peers, peer_id) do
    peers
    |> Enum.filter(fn {other_id, _peer_name} ->
      peer_id != other_id
    end)
    |> Enum.into([])
  end
  
end