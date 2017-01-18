defmodule VivaldiTest do
  use ExUnit.Case

  alias Vivaldi.Peer.{Config, Coordinate}

  test "Vivaldi" do
    test_n(4, 2)
    test_n(10, 4)
  end

  @doc """
  Test vivaldi with n coordinates spread uniformly 
  # on the circumference of a circle of radius r
  """
  def test_n(n, radius) do
    expected_coords = create_coordinate_cluster(n, radius)
    
    matrix = get_latency_matrix(expected_coords)
    config = get_config()

    # The simulation sometimes generates pathological cases. 
    # Hence, sometimes we get large errors. 
    # So we run the algorithm multiple times, and check if the lowest error is quite small.
    # With real-world values, this shouldn't be an issue.

    1..5
    |> Enum.map(fn _ -> run_vivaldi(n, config, matrix) end)
    |> Enum.sort()
    |> Enum.at(0)
    |> (fn error -> 
      # Vivaldi promises 90% accuracy. So we check if smallest error < 10%
      # Usually, error varies between 1.0e-5 and 0.25
      assert error < 0.1
    end).()
  end

  # Helper functions

  def get_config do
    peers = [
      {:d, :"d@127.0.0.1"}
    ]
    conf = [
      node_id: :a,
      node_name: :"d@127.0.0.1",
      session_id: 1,
      peers: peers,
      vivaldi_ce: 0.5
    ]
    Config.new(conf)
  end

  def create_coordinate_cluster(n, r) do
    angle_step = 2 * :math.pi / n
    0..(n-1)
    |> Enum.map(fn i ->
      angle = i * angle_step
      vec = [r * :math.cos(angle), r * :math.sin(angle)]
      %{vector: vec, height: 10.0e-6, error: 1.5}
    end)
  end

  def get_latency_matrix(coordinates) do
    count = Enum.count(coordinates)
    Enum.map(0..(count-1), fn i ->
      x_i = Enum.at(coordinates, i)
      Enum.map(0..(count-1), fn j ->
        x_j = Enum.at(coordinates, j)
        Coordinate.distance(x_i, x_j)
      end)
    end)
  end

  def run_vivaldi(n, config, matrix) do
    coords = Enum.map(1..n, fn _ -> 
      Coordinate.new(2, config[:height_min], config[:vivaldi_error_max])
    end)

    coords_map = Enum.zip(0..(n-1), coords) |> Enum.into(%{})
    final_coords_map = vivaldi_session(n, config, matrix, coords_map, 0, 5000)

    relative_error(n, matrix, final_coords_map)
  end

  def vivaldi_session(n, config, matrix, coords_map, iteration, max_iteration) do
    if iteration == max_iteration do
      coords_map
    else
      {i, j} = {:rand.uniform(n) - 1, :rand.uniform(n) - 1}
      next_coords_map = vivaldi_iter(config, coords_map, matrix, i, j)
      vivaldi_session(n, config, matrix, next_coords_map, iteration + 1, max_iteration)
    end
  end

  def vivaldi_iter(config, coords_map, matrix, i, j) do
    {x_i, x_j} = {coords_map[i], coords_map[j]}
    rtt = matrix |> Enum.at(i) |> Enum.at(j)
    x_i_next = Coordinate.vivaldi(config, x_i, x_j, rtt)
    # IO.puts "x_i_next: #{inspect x_i_next}"
    Map.put coords_map, i, x_i_next
  end

  def generate_pairs(n) do
    p = for i <- 1..(n-1) do
      for j <- 0..(i-1) do
        {i, j}
      end
    end
    List.flatten(p)
  end

  def relative_error(n, matrix, coords_map) do

    pairs = generate_pairs(n)

    pairs
    |> Enum.map(fn {i, j} ->
      rtt = matrix |> Enum.at(i) |> Enum.at(j)
      {x_i, x_j} = {coords_map[i], coords_map[j]}
      d = Coordinate.distance(x_i, x_j)
      abs(d - rtt) / rtt
    end)
    |> (fn errors ->
      Enum.sum(errors) / Enum.count(pairs)
    end).()
  end

end

