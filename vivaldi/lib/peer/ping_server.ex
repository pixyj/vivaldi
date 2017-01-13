defmodule Vivaldi.Peer.PingServer do
  @moduledoc """
  Responds to ping requests from other coordinates with a :pong. 
  Along with the :pong, the current coordinate state is also sent so that the other node can use it to update its coordinates. 
  """
  use GenServer

  require Logger

  alias Vivaldi.Peer.CoordinateStash

  def start_link(config) do
    {node_id, session_id} = {config[:node_id], config[:session_id]}
    {:ok, pid} = GenServer.start_link(__MODULE__, {node_id, session_id})
    name = get_name(node_id)
    :global.register_name(name, pid)
    {:ok, pid}
  end

  @doc """
  Client API

  **TODO**: How to avoid try catch 
  and use some version of receive... after instead, similar to http://bit.ly/2j1PuY7
  """
  def ping(client_node_id, client_session_id, server_node_id, server_pid, ping_id, timeout) do
    # As shown at http://bit.ly/2idCMnc
    try do
      GenServer.call(server_pid,
                    {:ping,
                     [node_id: client_node_id, session_id: client_session_id, ping_id: ping_id]},
                     timeout)
    catch
      :exit, reason ->
        Logger.warn("#{inspect reason}")
        {:error, reason}
    end
  end

  # Implementation
  def handle_call({:ping, [node_id: _, session_id: other_session_id, ping_id: ping_id]},
                   _,
                  {my_node_id, my_session_id}) do
    if other_session_id == my_session_id do
      coordinate = CoordinateStash.get_coordinate(my_node_id)
      payload = [session_id: my_session_id, 
                 ping_id: ping_id,
                 node_id: my_node_id,
                 coordinate: coordinate
                ]
      {:reply, {:pong, payload}, {my_node_id, my_session_id}}
    else
      message = "session_ids don't match. Received #{other_session_id}, my_session_id is #{my_session_id}"
      Logger.error message 
      {:reply, {:pang, message}, {my_node_id, my_session_id}}
    end
  end

  def get_name(node_id) do
    :"#{node_id}-ping-server"
  end

  def get_server_pid(node_id) do
    get_name(node_id) |> :global.whereis_name()
  end
  
end