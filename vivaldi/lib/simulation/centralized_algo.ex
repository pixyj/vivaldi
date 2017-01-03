defmodule Vivaldi.Simulation.CentralizedAlgo do
  @moduledoc """
  The paper starts off with a description of the centralized version of the algorithm. 
  Let's test it out. 
  """

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
        distance(x_i, x_j)
      end)
    end)
  end

  def distance(x_i, x_j) do
    Enum.zip(x_i, x_j)
    |> Enum.map(fn {a, b} -> a - b end)
    |> Enum.map(&(&1 * &1))
    |> Enum.reduce(&(&1 + &2))
    |> :math.sqrt()
  end
  
end