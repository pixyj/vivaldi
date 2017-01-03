defmodule Vivaldi.Simulation.CentralizedAlgo do
  @moduledoc """
  The paper starts off with a description of the centralized version of the algorithm. 
  Let's test it out. 
  """

  alias Vivaldi.Simulation.Vector

  def run(n) do
    points = create_coordinate_cluster(n, type: :circular, radius: n)
    latencies = get_latency_matrix(points)

    initial_x = get_initial_x(n)
    computed_x = compute_coordinates(n, latencies, initial_x, 0.05, 200, 0)

    computed_x = Enum.map(0..(n-1), fn i -> computed_x[i] end)
    computed_latencies = get_latency_matrix(computed_x)
    {computed_x, computed_latencies}

  end

  def get_initial_x(n) do
    0..(n-1)
    |> Enum.map(fn i -> {i, [:rand.uniform() - 0.5, :rand.uniform() - 0.5]} end)
    |> Enum.into(%{})
  end

  def compute_total_error(n, expected_latencies, computed_latencies) do
    pairwise_errors = for i <- 0..(n-1) do
      a_i = Enum.at(expected_latencies, i)
      b_i = Enum.at(computed_latencies, i)
      for j <- 0..i do
        a_ij = Enum.at(a_i, j)
        b_ij = Enum.at(b_i, j)
        diff = a_ij - b_ij
        diff * diff
      end
    end
    List.flatten(pairwise_errors) |> Enum.reduce(&(&1 + &2))
  end

  def compute_coordinates(n, latencies, x, t, max_iterations, iteration) do
    x_list = Enum.map(0..(n-1), fn i -> x[i] end)
    computed_latencies = get_latency_matrix(x_list)
    cost = compute_total_error(n, latencies, computed_latencies)
    IO.puts "Iteration: #{iteration}, Cost: #{cost}"
    # IO.puts "#{inspect x}"
    if iteration == max_iterations do
      x
    else
      i = rem(iteration, n)
      next_x_i = compute_next_x_i(n, latencies, x, i, t)
      x = Map.put(x, i, next_x_i)
      compute_coordinates(n, latencies, x, t, max_iterations, iteration + 1)
    end
  end

  def compute_next_x_i(n, latencies, x, i, t) do
    x_i = x[i]
    l_i = Enum.at(latencies, i)

    # Calculate total force on x_i
    f = Enum.map(0..(n-1), fn j ->
      l_ij = Enum.at(l_i, j)
      x_j = x[j]
      e = l_ij - Vector.distance(x_i, x_j)
      u = Vector.unit_vector_at(x_i, x_j)
      Vector.scale(u, e)
    end)
    |> Enum.reduce(&(Vector.add(&1, &2)))
    # Move x_i in direction of f.
    step = Vector.scale(f, t)
    Vector.add(x_i, step)
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
