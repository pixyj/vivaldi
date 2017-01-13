defmodule Vivaldi.Peer.CoordinateLogger do
  @moduledoc """
  All coordinate-update events are sent here. Events are logged to stdout.
  TODO: Also log events to a centralized log aggregator.
  """
  use GenServer
  
  require Logger

  # API

  def start_link(config) do
    node_id = config[:node_id]
    GenServer.start_link(__MODULE__, {}, name: get_name(node_id))
  end

  def log(node_id, event) do
    GenServer.cast(get_name(node_id), event)
  end

  # Implementation

  def get_name(node_id) do
    :"#{node_id}-coordinate-logger"
  end

  def handle_cast({:log}, _from,
                  {my_node_id, other_node_id, other_coordinate, rtt,
                   my_coordinate, my_new_coordinate}) do

    {:noreply, {}}
  end

end
