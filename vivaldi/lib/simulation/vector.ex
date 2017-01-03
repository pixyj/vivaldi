defmodule Vivaldi.Simulation.Vector do

  @doc """
    Calculates vector distance.
    Assumes `x_i` and `x_j` dimensions match. 
  """
  def distance(x_i, x_j) do
    Enum.zip(x_i, x_j)
    |> Enum.map(fn {a, b} -> a - b end)
    |> Enum.map(&(&1 * &1))
    |> Enum.reduce(&(&1 + &2))
    |> :math.sqrt()
  end
  
end