defmodule CoordinateStashTest do
  use ExUnit.Case

  alias Vivaldi.Peer.{Config, CoordinateStash}

  test "Test get and set" do

    conf_one = [
      node_id: :a,
      node_name: :"a@127.0.0.1",
      session_id: 1,
      peers: [],
      vivaldi_ce: 0.5
    ]

    conf_two = [
      node_id: :b,
      node_name: :"b@127.0.0.1",
      session_id: 1,
      peers: [],
      vector_dimension: 3,
      vivaldi_ce: 0.5
    ]
    conf_one = Config.new(conf_one)
    conf_two = Config.new(conf_two)

    zero_one = %{vector: [0, 0], height: 10.0e-6, error: 1.5}
    zero_two = %{vector: [0, 0, 0], height: 10.0e-6, error: 1.5}

    CoordinateStash.start_link(conf_one)
    CoordinateStash.start_link(conf_two)

    assert CoordinateStash.get_coordinate(:a) == zero_one
    assert CoordinateStash.get_coordinate(:b) == zero_two

    one = %{vector: [1, 2], height: 100.0e-6}
    two = %{vector: [3, 2, 1], height: 100.0e-6}

    CoordinateStash.set_coordinate(:a, one)
    CoordinateStash.set_coordinate(:b, two)

    assert CoordinateStash.get_coordinate(:a) == one
    assert CoordinateStash.get_coordinate(:b) == two

  end

end