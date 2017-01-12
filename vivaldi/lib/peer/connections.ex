defmodule Vivaldi.Peer.Connections do
  @moduledoc """
  * Establishes connection with peers before pinging.  
  """

  use GenServer

  require Logger

  alias Vivaldi.Peer.PingServer

  @connection_setup_timeout 30_000

  # API

  def start_link(node_id, peers) do
    Logger.info "Starting Connections...."
    state = get_initial_state(node_id, peers)
    GenServer.start_link(__MODULE__, state, name: get_name(node_id))
  end

  @doc """
  If peer is connected, returns peer's ping_server.
  Else, connects to peer first, updates internal state and returns peer's ping_server. 
  If connection fails, returns `:undefined`. 
  """
  def get_peer_ping_server(node_id, peer_id) do
    GenServer.call(get_name(node_id),
                   {:get_peer_ping_server, peer_id},
                   @connection_setup_timeout)
  end

  # Implementation

  def handle_call({:get_peer_ping_server, peer_id}, _, {node_id, peer_names_by_id}) do
    peer_name = peer_names_by_id[peer_id]
    if peer_name in Node.list do
      Logger.info("Peer #{peer_name} CONNECTED already!")
      return_server_pid(peer_id, {node_id, peer_names_by_id})
    else
      Logger.info("Peer #{peer_name} NOT connected. Attempting to connect...!")
      case Node.connect(peer_name) do
        true ->
          Logger.info("CONNECTED to #{peer_name}!")
          # :global.whereis doesn't work without sleeping in my dev machine. 
          # TODO: How does this work under the hood?
          :timer.sleep(500)
          return_server_pid(peer_id, {node_id, peer_names_by_id})
        false ->
          Logger.error("Node.connect failed: NOT Connected to #{peer_name}!")
          {:reply, {:error, :pang}, {node_id, peer_names_by_id}}
      end
    end
  end

  def return_server_pid(peer_id, state) do
    pid = PingServer.get_server_pid(peer_id)
    if pid == :undefined do
      {:reply, {:error, :undefined}, state}
    else
      {:reply, {:ok, pid}, state}
    end
  end

  def get_initial_state(node_id, peers) do
    peer_names_by_id = Enum.map(peers, fn {peer_id, peer_name} ->
      {peer_id, peer_name}
    end)
    |> Enum.into(%{})

    {node_id, peer_names_by_id}
  end

  def get_name(node_id) do
    :"#{node_id}-connections"
  end
  
end