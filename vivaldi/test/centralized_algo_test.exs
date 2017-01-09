defmodule CentralizedAlgoTest do
  use ExUnit.Case
  
  alias Vivaldi.Simulation.CentralizedAlgo, as: CA
  alias Vivaldi.Simulation.Runner, as: Runner

  test "test compute_coordinates" do
    CA.run(4, 2)
  end

  test "create_coordinate_cluster" do
    points = Runner.create_coordinate_cluster 4, [type: :circular, radius: 2]
    expected_points = [[2, 0], [0, 2], [-2, 0], [0, -2]]

    Enum.zip(points, expected_points)
    |> Enum.each(fn {p1, p2} ->
      # For each point...
      Enum.zip(p1, p2)
      # Test if components are equal, ignoring floating-point errors. 
      |> Enum.map(fn {p1_i, p2_i} ->
        assert abs(p1_i - p2_i) < 0.0001
      end)
    end)
  end

  test "latency matrix" do
    points = Runner.create_coordinate_cluster 4, [type: :circular, radius: 1]
    latency_matrix = Runner.get_latency_matrix(points)
    expected = [
      [0, :math.sqrt(2), 2, :math.sqrt(2)],
      [:math.sqrt(2), 0, :math.sqrt(2), 2],
      [2, :math.sqrt(2), 0, :math.sqrt(2)],
      [:math.sqrt(2), 2, :math.sqrt(2), 0]
    ]

    Enum.zip(List.flatten(latency_matrix), List.flatten(expected))
    |> Enum.each(fn {a, b} ->
      assert abs(a - b) < 0.0001
    end)
  end
  
end
