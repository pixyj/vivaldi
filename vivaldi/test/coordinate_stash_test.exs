defmodule CoordinateStashTest do
  use ExUnit.Case

  alias Vivaldi.Peer.CoordinateStash

  test "Test get and set" do
    one = %{vector: [2, 3], height: 1.0e-6}
    two = %{vector: [3, 2], height: 10.0e-6}
    node_id = 1
    node_id_2 = 2
    CoordinateStash.start_link(node_id, one)
    CoordinateStash.start_link(node_id_2, two)

    assert CoordinateStash.get_coordinate(node_id) == one
    assert CoordinateStash.get_coordinate(node_id_2) == two

    CoordinateStash.set_coordinate(node_id, two)
    CoordinateStash.set_coordinate(node_id_2, one)

    assert CoordinateStash.get_coordinate(node_id) == two
    assert CoordinateStash.get_coordinate(node_id_2) == one

  end

end