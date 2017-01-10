defmodule SimpleVivaldiTest do
  use ExUnit.Case

  alias Vivaldi.Simulation.SimpleVivaldi

  test "test simple vivaldi" do
    {_, _, error} = SimpleVivaldi.run(10, 4)
    IO.puts "******** SimpleVivaldi error***************** #{error}"
    assert error < 0.05
  end

  # test "testsdfs" do
  #   Enum.map(1..20, fn _ -> IO.puts :random.uniform() end)
  # end
end