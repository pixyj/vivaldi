defmodule PingTest do
  use ExUnit.Case
  use Timex

  alias Vivaldi.Peer.{CoordinateStash, Connections, PingClient, PingServer}


  setup_all do
    # Simulate both client and server on same node.
    Node.start :"d@127.0.0.1"
    Node.set_cookie :"ping_test"
    client_node_id = :a
    server_node_id = :d
    peers = [
      {:d, :"d@127.0.0.1"}
    ]

    session_id = 1

    server_coordinate = %{vector: [2, 3], height: 1.0e-6}
    Connections.start_link(client_node_id, peers)
    CoordinateStash.start_link(server_node_id, server_coordinate)
    PingServer.start_link(server_node_id, session_id)
    :ok
  end

  test "Ping Once" do
    client_node_id = :a
    server_node_id = :d
    session_id = 1
    ping_id = 1
    server_coordinate = %{vector: [2, 3], height: 1.0e-6}
    {:ok, server_pid} = Connections.get_peer_ping_server(client_node_id, server_node_id)
    # Happy case
    {:pong, {_rtt, response_coordinate}} = PingClient.ping_once(client_node_id, session_id, server_node_id, server_pid, ping_id)
    assert response_coordinate == server_coordinate

    # Timeout
    {:error, _} = PingClient.ping_once(client_node_id, session_id, server_node_id, server_pid, ping_id, 0)

    # session_id mismatch
    {:pang, _} = PingServer.ping(client_node_id, 1000, server_node_id, server_pid, ping_id, 5000)

  end

  test "Ping Multi" do
    client_node_id = :a
    server_node_id = :d
    session_id = 1
    ping_id = 1
    
    server_coordinate = %{vector: [2, 3], height: 1.0e-6}
    {:ok, {_, result}} = PingClient.ping_multi(client_node_id, session_id, server_node_id)
    assert result == server_coordinate
  end

  test "get median rtt" do
    responses = [
      {0.5, %{vector: [2, 3], height: 1.0e-6}},
      {0.2, %{vector: [2, 4], height: 1.0e-6}},
      {0.1, %{vector: [2.5, 3], height: 1.0e-6}},
      {0.6, %{vector: [2.6, 3.5], height: 1.0e-6}}
    ]
    result = PingClient.get_median_rtt(responses)
    assert result == (0.5 + 0.2) / 2

    responses = [
      {0.5, %{vector: [2, 3], height: 1.0e-6}},
      {0.2, %{vector: [2, 4], height: 1.0e-6}},
      {0.1, %{vector: [2.5, 3], height: 1.0e-6}},
      {0.6, %{vector: [2.6, 3.5], height: 1.0e-6}},
      {0.7, %{vector: [2.6, 3.5], height: 1.0e-6}}
    ]

    result = PingClient.get_median_rtt(responses)
    assert result == 0.5
  end

  test "get last coordinate" do
    # last_coordinate = 
    responses = [
      {0.5, %{vector: [2, 3], height: 1.0e-6}},
      {0.2, %{vector: [2, 4], height: 1.0e-6}},
      {0.1, %{vector: [2.5, 3], height: 1.0e-6}},
      {0.6, %{vector: [2.6, 3.5], height: 1.0e-6}},
      {0.7, %{vector: [2.6, 3.5], height: 1.0e-6}}
    ]
    result = PingClient.get_last_coordinate(responses)
    assert result == %{vector: [2.6, 3.5], height: 1.0e-6}
  end

  test "calculate_rtt" do
    start = Duration.from_seconds(1484099996)
    finish = Duration.from_seconds(1484099997)
    result = PingClient.calculate_rtt(start, finish)
    assert result == 1.0

    start = Duration.now()
    :timer.sleep(20)
    finish = Duration.now()
    result = PingClient.calculate_rtt(start, finish)
    assert (result > 0.02 and result < 0.03)
  end
  
end