defmodule Vivaldi.Peer.Coordinate do
  @moduledoc """
  Contains the core logic, where the coordinate of a peer is updated
  when it communicates with another peer
  Ported from [hashicorp/serf](https://github.com/hashicorp/serf/tree/master/coordinate)
  """

  use GenServer

  require Logger
  
  alias Vivaldi.Peer.{CoordinateStash, CoordinateLogger}
  alias Vivaldi.Simulation.Vector


  def start_link(config) do
    node_id = config[:node_id]
    coordinate = CoordinateStash.get_coordinate(node_id)
    GenServer.start_link(__MODULE__, {config, coordinate}, name: get_name(node_id))
  end

  def update_coordinate(my_node_id, other_node_id, other_coordinate, rtt) do
    GenServer.call(get_name(my_node_id),
                          {:update_coordinate, my_node_id, other_node_id,
                           other_coordinate, rtt})
  end

  # For testing purposes only... 
  def handle_call(:get_coordinate, _from, {config, coordinate}) do
    {:reply, coordinate, {config, coordinate}}
  end

  def handle_call({:update_coordinate, my_node_id, other_node_id, other_coordinate, rtt},
                  _from, {config, my_coordinate}) do
    
    my_new_coordinate = vivaldi(config, my_coordinate, other_coordinate, rtt)

    unless config[:local_mode?] do
      # Send coordinate-update event
      event = %{
        i: my_node_id,
        j: other_node_id,
        x_i: my_coordinate,
        x_j: other_coordinate,
        x_i_next: my_new_coordinate,
        rtt: rtt
      }
      CoordinateLogger.log(my_node_id, event)
    end
    Logger.info "#{my_node_id} - coordinate changed from #{inspect my_coordinate} to #{inspect my_new_coordinate}"
    {:reply, :ok, {config, my_new_coordinate}}
  end

  def terminate(_reason, {config, coordinate}) do
    node_id = config[:node_id]
    CoordinateStash.set_coordinate(node_id, coordinate)
  end

  def get_name(node_id) do
    :"#{node_id}-coordinate"
  end

  def new(dimension, height, error) do
    %{vector: Vector.zero(dimension), height: height, error: error}
  end

  def vivaldi(config, x_i, x_j, rtt) do
    dist = distance(x_i, x_j)
    rtt = max(rtt, config[:zero_threshold])
    wrongness = abs(dist - rtt) / dist

    total_error = x_i[:error] + x_j[:error]
    total_error = max(total_error, config[:zero_threshold])
    weight = x_i[:error] / total_error

    error_next = config[:vivaldi_ce] * weight * wrongness + x_i[:error] * (1.0 - config[:vivaldi_ce] * weight)
    error_next = max(error_next, config[:vivaldi_error_max])

    delta = config[:vivaldi_cc] * weight
    force = delta * (rtt - dist)
    {vec_next, height_next} = apply_force(config, x_i, x_j, force)

    %{vector: vec_next, height: height_next, error: error_next}
  end

  def apply_force(config, x_i, x_j, force) do
    unit = Vector.unit_vector_at(x_i[:vector], x_j[:vector])
    mag = Vector.diff(x_i[:vector], x_j[:vector]) |> Vector.magnitude()

    force_vec = Vector.scale(unit, force)
    vec_next = Vector.add(x_i[:vector], force_vec)

    height_next = case mag > config[:zero_threshold] do
      true ->
        h = (x_i[:height] + x_j[:height]) * force / mag + x_i[:height]
        max(h, config[:height_min])
      false ->
        x_i[:height]
    end

    {vec_next, height_next}
  end

  def distance(%{vector: a_vec, height: a_height, error: _}, %{vector: b_vec, height: b_height, error: _}) do
    vector_dist = Vector.distance(a_vec, b_vec)
    height_dist = a_height + b_height
    vector_dist + height_dist
  end

end