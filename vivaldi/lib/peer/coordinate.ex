defmodule Vivaldi.Peer.Coordinate do
  @moduledoc """
  Contains the core logic, where the coordinate of a peer is updated
  when it communicates with another peer
  Ported from [hashicorp/serf](https://github.com/hashicorp/serf/tree/master/coordinate)
  """

  use GenServer
  
  alias Vivaldi.Peer.{CoordinateStash, CoordinateLogger}
  alias Vivaldi.Simulation.Vector

  # Vivaldi protocol tuning parameters. 
  @height_min 10.0e-6
  @vivaldi_ce 0.25
  @vivaldi_cc 0.25
  @vivaldi_error_max 1.5
  @zero_threshold 1.0e-6

  def start_link(config) do
    {node_id, session_id} = {config[:node_id], config[:session_id]}
    coordinate = CoordinateStash.get_coordinate(node_id)
    GenServer.start_link(__MODULE__, {node_id, session_id, coordinate}, name: get_name(node_id))
  end

  def update_coordinate(my_node_id, other_node_id, other_coordinate, rtt) do
    GenServer.call(get_name(my_node_id),
                          {:update_coordinate, my_node_id, other_node_id,
                           other_coordinate, rtt})
  end

  def handle_call({:update_coordinate, my_node_id, other_node_id, other_coordinate, rtt},
                  _from, {_my_node_id, session_id, my_coordinate}) do
    
    my_new_coordinate = vivaldi(my_node_id, other_node_id, my_coordinate, other_coordinate, rtt)
    CoordinateLogger.log(my_node_id, {my_node_id, other_node_id, other_coordinate,
                         rtt, my_coordinate, my_new_coordinate})
    {:reply, :ok, {my_node_id, session_id, my_new_coordinate}}
  end

  def terminate(_reason, {node_id, _session_id, coordinate}) do
    CoordinateStash.set_coordinate(node_id, coordinate)
  end

  def get_name(node_id) do
    :"#{node_id}-coordinate"
  end

  def new(dimension, height) do
    %{vector: Vector.zero(dimension), height: height}
  end

  def vivaldi(my_node_id, other_node_id, my_coordinate, other_coordinate, rtt) do
    my_coordinate
  end

  def distance(%{vector: a_vec, height: a_height}, %{vector: b_vec, height: b_height}) do
    vector_dist = Vector.distance(a_vec, b_vec)
    height_dist = a_height + b_height

    vector_dist + height_dist
  end

end