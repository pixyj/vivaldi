defmodule Vivaldi.Peer.Connections do
  @moduledoc """
  * Connects to peers just before ping. 
  * Maintains status of connections to other peers.
  * If a peer goes down, its connection-status is updated.
    An attempt to reconnect is made before the next ping to that peer.
  """

  use GenServer

  alias Vivaldi.Peer.PingServer

  # API

  def start_link(node_id, peers) do
    state = get_initial_state(peers)
    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: get_name(node_id))
    :ok = GenServer.call(pid, :start)
    {:ok, pid}
  end

  @doc """
  If peer is connected, returns peer's ping_server.
  Else, connects to peer first and returns peer's ping_server. 
  If connection fails, returns `:undefined`. 
  """
  def get_peer_ping_server(node_id, peer_id) do
    GenServer.call(get_name(node_id), {:get_peer_ping_server, peer_id})
  end

  # Implementation

  def handle_call(:start, _, state) do
    Process.flag(:trap_exit, true)
    start_monitor_peers()
    {:reply, :ok, state}
  end

  def handle_call({:nodedown, peer_name}, _, {peer_states, peer_ids_by_names}) do
    peer_id = peer_ids_by_names[peer_name]
    new_peer_states = Map.put(peer_states, peer_id, :not_connected)
    {:reply, :ok, {new_peer_states, peer_ids_by_names}}
  end

  def handle_call({:get_peer_ping_server, peer_id}, _, {peer_states, peer_ids_by_names}) do
    case peer_states[peer_id] do
      {peer_name, :connected} ->
        PingServer.get_server_pid(peer_id)
      {peer_name, :not_connected} ->
        case Node.ping(peer_name) do
          :ping ->
            PingServer.get_server_pid(peer_id)
          :pang ->
            :undefined
        end
    end
  end

  @doc """
  Restart monitor_peers in case it fails
  """
  def handle_info({:EXIT, pid, reason}, state) do
    start_monitor_peers()
    {:noreply, state}
  end

  def start_monitor_peers() do
    spawn_link(__MODULE__, :monitor_peers, [self])
  end

  def monitor_peers(parent) do
    receive do
      {:monitor_peer, ^parent, peer_name} ->
        Node.monitor(peer_name, true)

      {:nodedown, peer_name} ->
        GenServer.call(parent, {:nodedown, peer_name})
    end
  end

  def get_initial_state(peers) do
    connected_peer_names = Enum.map(Node.list(),
      fn peer_name -> {peer_name, :connected}
    end)
    |> Enum.into(%{})

    peer_states = Enum.map(peers, fn {peer_id, peer_name} ->
      case connected_peer_names[peer_name] do
        :connected ->
          {peer_id, {peer_name, :connected}}
        :nil ->
          {peer_id, {peer_name, :not_connected}}
      end
    end)
    |> Enum.into(%{})

    peer_ids_by_names = Enum.map(peers, fn {peer_id, peer_name} ->
      {peer_name, peer_id}
    end)
    |> Enum.into(%{})

    {peer_states, peer_ids_by_names}
  end

  def get_name(node_id) do
    :"#{node_id}-connections"
  end
  
end