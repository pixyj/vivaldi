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

  def zero(dimension) do
    Enum.map(1..dimension, fn _ -> 0 end)
  end

  def rand(dimension) do
    Enum.map(1..dimension, fn _ -> :rand.uniform - 0.5 end)
  end

  @doc """
  According to the paper:
  > Because all nodes start at the same location, Vivaldi must separate them somehow.
  > Vivaldi does this by defining u(0) to be a unit-length vector in a randomly chosen direction
  When p1 and p2 are non-zero vectors, then the conventional definition of a unit vector is used.
  """
  def unit_vector_at(p1, p2) do
    dimension = Enum.count(p1)
    if p1 == zero(dimension) and p2 == zero(dimension) do
      u = rand(dimension)
      scale(u, 1 / magnitude(u))
    else
      if p1 == p2 do
        Enum.map(1..dimension, fn _ -> 0 end)
      else
        d = diff(p1, p2)
        mag = magnitude(d)
        scale(d, 1 / mag)
      end
    end
  end
end
