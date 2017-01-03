defmodule Vivaldi.Simulation.Vector do
  @moduledoc """
  Vector functions. All functions assume dimensions match.
  """

  def distance(p1, p2) do
    diff(p1, p2)
    |> magnitude()
  end

  def diff(p1, p2) do
    Enum.zip(p1, p2)
    |> Enum.map(fn {a, b} -> (a - b) end)
  end

  def add(p1, p2) do
    Enum.zip(p1, p2)
    |> Enum.map(fn {a, b} -> (a + b) end)
  end

  def magnitude(p1) do
    p1
    |> Enum.map(&(&1 * &1))
    |> Enum.reduce(&(&1 + &2))
    |> :math.sqrt()
  end

  def scale(p1, factor) do
    Enum.map(p1, fn a -> a * factor end)
  end

  def unit_vector_at(p1, p2) do
    # Return zero vector if p1 == p2
    if p1 == p2 do
      Enum.map(1..(Enum.count(p1)), fn _ -> 0 end)
    else
      d = diff(p1, p2)
      mag = magnitude(d)
      scale(d, 1 / mag)
    end
  end
end
