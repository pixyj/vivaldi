defmodule Vivaldi.Peer.Connections do
  @moduledoc """
  * Establishes connection with peers before pinging.  
  """

  use GenServer

  require Logger

  alias Vivaldi.Peer.PingServer

  @connection_setup_timeout 30_000

  # API

  def start_link(config) do
    node_id = config[:node_id]
    Logger.info "#{node_id} - starting Connections..."
    GenServer.start_link(__MODULE__, config, name: get_name(node_id))
  end

  @doc """
  If peer is connected, returns peer's ping_server.
  Else, connects to peer first, updates internal state and returns peer's ping_server. 
  If connection fails, returns `:undefined`. 
  """
  def get_peer_ping_server(node_id, peer_id) do
    GenServer.call(get_name(node_id), {:get_peer_ping_server, peer_id}, @connection_setup_timeout)
  end

  # Implementation

  def handle_call({:get_peer_ping_server, peer_id}, _, config) do
    case config[:local_mode?] do
      true ->
        return_server_pid(peer_id, config)
      false ->
        get_remote_server_pid(peer_id, config)
    end
  end

  def get_remote_server_pid(peer_id, config) do
    node_id = config[:node_id]
    peer_names_by_id = config[:peer_names_by_id]
    peer_name = peer_names_by_id[peer_id]

    if peer_name in Node.list do
      Logger.info("#{node_id} - peer:#{peer_name} CONNECTED already!")
      return_server_pid(peer_id, config)
    else
      Logger.info("#{node_id} - peer:#{peer_name} NOT connected. Attempting to connect...")
      case Node.connect(peer_name) do
        true ->
          Logger.info("#{node_id} - CONNECTED to #{peer_name}!")
          # :global.whereis doesn't work without sleeping in my dev machine. 
          # TODO: How does this work under the hood?
          :timer.sleep(config[:whereis_name_wait_interval])
          return_server_pid(peer_id, config)
        false ->
          Logger.error("#{node_id} - Node.connect failed: NOT Connected to #{peer_name}!")
          {:reply, {:error, :pang}, config}
        _ ->
          Logger.error("#{node_id} - Node.connect failed: NOT Connected to #{peer_name}!")
          {:reply, {:error, :pang}, config}
      end
    end
  end

  def return_server_pid(peer_id, config) do
    pid = PingServer.get_server_pid(peer_id)
    if pid == :undefined do
      {:reply, {:error, :undefined}, config}
    else
      {:reply, {:ok, pid}, config}
    end
  end

  def get_name(node_id) do
    :"#{node_id}-connections"
  end
  
end