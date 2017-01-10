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

  test "Vector Diff" do
    points_and_results = [
     {[0, 0], [0, 0], [0, 0]},
     {[0, 1], [0, 0], [0, 1]},
     {[2, 1], [1, 2], [1, -1]},
     {[0, 3], [4, 0], [-4, 3]},
    ]

    Enum.each(points_and_results, fn {p1, p2, expected} ->
      result = Vector.diff(p1, p2)
      assert expected == result
    end)
  end

  test "Vector Magnitude" do
    points_and_results = [
     {[0, 0], 0},
     {[0, 3, 4], 5},
     {[1, 1], :math.sqrt(2)},
     {[-1, -1], :math.sqrt(2)},
    ]

    Enum.each(points_and_results, fn {p1, expected} ->
      result = Vector.magnitude(p1)
      assert expected == result
    end)
  end

  test "Vector Scale" do
    inputs_and_results = [
     {[0, 0], 100, [0, 0]},
     {[0, 3, 4], 2, [0, 6, 8]},
     {[1, 1], -4, [-4, -4]},
     {[-1, -1], -4, [4, 4]},
    ]

    Enum.each(inputs_and_results, fn {p1, factor, expected} ->
      result = Vector.scale(p1, factor)
      assert expected == result
    end)
  end

  test "Unit vector at" do
    inputs_and_results = [
     {[1, 1], [0, 0], [:math.cos(:math.pi/4), :math.sin(:math.pi/4)]},
     {[2, 1], [2, 0], [0, 1]}
    ]

    Enum.each(inputs_and_results, fn {p1, p2, expected} ->
      result = Vector.unit_vector_at(p1, p2)
      Enum.zip(result, expected)
      |> Enum.map(fn {r, e} ->
        assert abs(r - e) < 0.0001
      end)
    end)

    rand_unit_vector = Vector.unit_vector_at([0, 0], [0, 0])
    assert abs(Vector.magnitude(rand_unit_vector) - 1.0) < 0.00001
  end
end