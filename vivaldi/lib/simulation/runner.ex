defmodule Vivaldi.Simulation.Runner do
  @moduledoc """
  Implements all the boilerplate stuff required for both the centralized and distributed algorithm. 
  """

  alias Vivaldi.Simulation.Vector

  def run(n, radius, compute_next_x_i_func) do
    points = create_coordinate_cluster(n, type: :circular, radius: radius)
    latencies = get_latency_matrix(points)

    initial_x = get_initial_x(n, radius)
    computed_x = compute_coordinates(n, latencies, initial_x, 0.1,
                                     2000, 0, compute_next_x_i_func)

    computed_x_list = Enum.map(0..(n-1), fn i -> computed_x[i] end)
    computed_latencies = get_latency_matrix(computed_x_list)
    error = compute_total_error(n, latencies, computed_latencies)
    {computed_x_list, computed_latencies, error}
  end

  def compute_coordinates(n, latencies, x, t,
                          max_iterations, iteration,
                          compute_next_x_i_func) do
    # Print Total Error
    # x_list = Enum.map(0..(n-1), fn i -> x[i] end)
    # computed_latencies = get_latency_matrix(x_list)
    # cost = compute_total_error(n, latencies, computed_latencies)
    # IO.puts "Iteration: #{iteration}, Error: #{cost}"

    if iteration == max_iterations do
      x
    else
      i = rem(iteration, n)
      next_x_i = compute_next_x_i_func.(n, latencies, x, i, t)
      x = Map.put(x, i, next_x_i)
      compute_coordinates(n, latencies, x, t,
                          max_iterations, iteration + 1,
                          compute_next_x_i_func)
    end
  end

  def compute_total_error(n, expected_latencies, computed_latencies) do
    pairwise_errors = for i <- 0..(n-1) do
      a_i = Enum.at(expected_latencies, i)
      b_i = Enum.at(computed_latencies, i)
      for j <- 0..i do
        a_ij = Enum.at(a_i, j)
        b_ij = Enum.at(b_i, j)
        if a_ij != 0 do
          abs(a_ij - b_ij) / a_ij
        else
          0
        end
      end
    end
    pairwise_errors = List.flatten(pairwise_errors)
    Enum.sum(pairwise_errors) / (Enum.count(pairwise_errors) - n)
  end

  def get_initial_x(n, radius) do
    0..(n-1)
    |> Enum.map(fn i ->
      {i, [radius * :rand.uniform() - 0.5, radius * :rand.uniform() - 0.5]} 
    end)
    |> Enum.into(%{})
  end

  def create_coordinate_cluster(n, type: :circular, radius: r) do
    angle_step = 2 * :math.pi / n
    0..(n-1)
    |> Enum.map(fn i ->
      angle = i * angle_step
      [r * :math.cos(angle), r * :math.sin(angle)]
    end)
  end

  def get_latency_matrix(coordinates) do
    count = Enum.count(coordinates)
    Enum.map(0..(count-1), fn i ->
      x_i = Enum.at(coordinates, i)
      Enum.map(0..(count-1), fn j ->
        x_j = Enum.at(coordinates, j)
        Vector.distance(x_i, x_j)
      end)
    end)
  end

end