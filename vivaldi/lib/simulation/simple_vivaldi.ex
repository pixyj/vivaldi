defmodule Vivaldi.Simulation.SimpleVivaldi do
  @moduledoc """
  Implementation of the simplified version of the Vivaldi algorithm.
  Explained in Section 2.4 
  """

  alias Vivaldi.Simulation.Runner
  alias Vivaldi.Simulation.Vector

  def run(n, radius) do
    Runner.run(n, radius, &compute_next_x_i/5)
  end

  def compute_next_x_i(n, latencies, x, i, t) do
    x_i = x[i]
    l_i = Enum.at(latencies, i)

    # Choose a random co-ordinate to speak to
    j = :rand.uniform(n) - 1
    l_ij = Enum.at(l_i, j)
    x_j = x[j]

    # Return updated x_i
    update_x_i(x_i, x_j, l_ij, t)
  end

  @doc """
  See Figure 2. Returns next version of coordinate, `x_i` after it communicates with another coordinate, `x_j`
  In the centralized algorithm, `x_i` is updated after calculating the resultant force due to all other coordinates.
  
  However, in the distributed algorithm, `x_i` is updated after it communicates with a *single* co-coordinate.
  The system converges in this case too! 
  """
  def update_x_i(x_i, x_j, rtt, delta) do
    # Compute error of this sample
    e = rtt - Vector.distance(x_i, x_j)

    # Find the direction of the force the error is causing
    dir = Vector.unit_vector_at(x_i, x_j)

    # The force vector is proportional to the error (3)
    f = Vector.scale(dir, e)
    delta_f = Vector.scale(f, delta)

    # Move a a small step in the direction of the force. (4)
    Vector.add(x_i, delta_f)
  end
    
end