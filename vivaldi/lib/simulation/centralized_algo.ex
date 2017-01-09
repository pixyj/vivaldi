defmodule Vivaldi.Simulation.CentralizedAlgo do
  @moduledoc """
  The paper starts off with a description of the centralized version of the algorithm. 
  Let's test it out. 
  """

  alias Vivaldi.Simulation.Runner
  alias Vivaldi.Simulation.Vector

  @doc """
  Run a simulation with n nodes distributed along the circumference of a circle. 
  See "Figure 1: The centralized algorithm" in the paper. 
  The error function decreases monotonically after each iteration, and reaches close to zero, 
  since we have ideal conditions here. 
  If the error oscillates, try changing the value of `t`
  """
  def run(n, radius) do
    Runner.run(n, radius, &compute_next_x_i/5)
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
end
