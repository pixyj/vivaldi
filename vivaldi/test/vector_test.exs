defmodule VectorTest do
  use ExUnit.Case
  
  alias Vivaldi.Simulation.Vector

  test "Vector Distance" do
    points_and_results = [
     {[0, 0], [0, 0], 0},
     {[0, 0], [0, 1], 1},
     {[0, 0], [0, 2], 2},
     {[0, 3], [4, 0], 5},
     {[0, 1], [1, 0], :math.sqrt(2)}
    ]

    Enum.each(points_and_results, fn {p1, p2, expected_distance} ->
      result = Vector.distance(p1, p2)
      assert abs(result - expected_distance) < 0.00001
    end)
  end
end