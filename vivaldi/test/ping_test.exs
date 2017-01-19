defmodule PingTest do
  use ExUnit.Case
  use Timex

  alias Vivaldi.Peer.{Coordinate, CoordinateStash, Config, Connections, PingClient, PingServer}

  def get_config do
    peers = [
      {:d, :"d@127.0.0.1"}
    ]
    conf = [
      node_id: :a,
      node_name: :"d@127.0.0.1",
      session_id: 1,
      peers: peers,
      vivaldi_ce: 0.5,
      ping_repeat: 2,
      ping_gap_interval: 1
    ]
    Config.new(conf)
  end

  def server_config do
    peers = [
      {:a, :"d@127.0.0.1"}
    ]
    conf = [
      node_id: :d,
      node_name: :"d@127.0.0.1",
      session_id: 1,
      peers: peers,
      vivaldi_ce: 0.5
    ]
    Config.new(conf)
  end

  setup_all do
    # Simulate both client and server on same node.
    Node.start :"d@127.0.0.1"
    Node.set_cookie :"ping_test"
    client_node_id = :a
    server_node_id = :d

    config = get_config()

    server_coordinate = %{vector: [2, 3], height: 1.0e-6, error: 0.2}
    Connections.start_link(config)
    CoordinateStash.start_link(server_config())
    CoordinateStash.set_coordinate(server_node_id, server_coordinate)
    PingServer.start_link(server_config())
    :ok
  end

  test "Ping Once" do
    client_node_id = :a
    server_node_id = :d
    session_id = 1
    ping_id = 1
    server_coordinate = %{vector: [2, 3], height: 1.0e-6, error: 0.2}
    config = get_config()
    {:ok, server_pid} = Connections.get_peer_ping_server(client_node_id, server_node_id)
    # Happy case
    {:pong, {_rtt, response_coordinate}} = PingClient.ping_once(config, server_node_id, server_pid, ping_id)
    assert response_coordinate == server_coordinate

    # Timeout
    config = Keyword.merge(config, [ping_timeout: 0])
    {:error, _} = PingClient.ping_once(config, server_node_id, server_pid, ping_id)

    # session_id mismatch
    {:pang, _} = PingServer.ping(client_node_id, 1000, server_node_id, server_pid, ping_id, 5000)

  end

  test "Ping Multi" do
    client_node_id = :a
    server_node_id = :d
    session_id = 1
    ping_id = 1

    config = get_config()

    server_coordinate = %{vector: [2, 3], height: 1.0e-6, error: 0.2}
    {:ok, {_, result}} = PingClient.ping_multi(config, server_node_id)
    assert result == server_coordinate
  end
  
  test "Periodic pinger" do
    client_node_id = :a
    server_node_id = :d
    session_id = 1
    ping_id = 1

    config = get_config()

    CoordinateStash.start_link(config)
    Coordinate.start_link(config)

    pinger = spawn_link(fn -> PingClient.begin_periodic_pinger(config) end)

    # Wait for ping<->pong to do its job
    :timer.sleep(1000)

    # Check if coordinate is now updated.
    # We don't care about the exact value of the new coordinate here 
    # since we have separate tests for that.
    c1 = GenServer.call(Coordinate.get_name(:a), :get_coordinate)
    assert c1[:vec] != [0, 0]
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
