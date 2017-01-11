defmodule PingTest do
  use ExUnit.Case

  alias Vivaldi.Peer.{CoordinateStash, PingClient, PingServer}

  test "Ping Once" do
    client_node_id = 1
    server_node_id = 2
    session_id = 1
    ping_id = 1

    server_coordinate = %{vector: [2, 3], height: 1.0e-6}

    CoordinateStash.start_link(server_node_id, server_coordinate)
    PingServer.start_link(server_node_id, session_id)

    {:pong, {_rtt, response_coordinate}} = PingClient.ping_once(client_node_id, session_id, server_node_id, ping_id)
    assert response_coordinate == server_coordinate

    {:error, _} = PingClient.ping_once(client_node_id, session_id, server_node_id, ping_id, 0)
  end

  test "Ping Multi" do
    
  end
  
end