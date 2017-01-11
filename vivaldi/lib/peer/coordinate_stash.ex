defmodule Vivaldi.Peer.CoordinateStash do
  @moduledoc """
  Save coordinate state in case of crash. 
  """
  use GenServer
  
  # API
  def start_link(node_id, initial_coordinate) do
    GenServer.start_link(__MODULE__, initial_coordinate, name: get_name(node_id))
  end

  def set_coordinate(node_id, coordinate) do
    GenServer.call(get_name(node_id), {:set_coordinate, coordinate})
  end

  def get_coordinate(node_id) do
    GenServer.call(get_name(node_id), {:get_coordinate})
  end

  # Implementation
  def get_name(node_id) do
    :"#{node_id}-coordinate-stash"
  end

  def handle_call({:get_coordinate}, _from, coordinate) do
    {:reply, coordinate, coordinate}
  end

  def handle_call({:set_coordinate, new_coordinate}, _from, _new_coordinate) do
    {:reply, new_coordinate, new_coordinate}
  end
end
