defmodule SimpleVivaldiTest do
  use ExUnit.Case

  alias Vivaldi.Simulation.SimpleVivaldi

  test "test simple vivaldi" do
    {_, _, error} = SimpleVivaldi.run(10, 4)
    assert error < 0.1
  end

end