defmodule ConnectionsTest do
  use ExUnit.Case

  alias Vivaldi.Peer.{Config, Connections}

  setup_all do
    Node.start :"a@127.0.0.1"
    Node.set_cookie :"hide_and_seek"
    spawn fn -> :os.cmd :"elixir test/peer_b.exs" end
    spawn fn -> :os.cmd :"elixir test/peer_c.exs" end
    :ok
  end

  test "connections" do
    :timer.sleep(500)
    node_id = :a
    peers = [
      {:b, :"b@127.0.0.1"},
      {:c, :"c@127.0.0.1"}
    ]
    node_config = [
      node_id: node_id, 
      session_id: 1,
      node_name: :"a@127.0.0.1",
      peers: peers
    ]
    config = Config.new(node_config)

    Connections.start_link(config)
    {:ok, pid} = Connections.get_peer_ping_server(node_id, :b)
    assert pid != :undefined
    {:ok, pid} = Connections.get_peer_ping_server(node_id, :c)
    assert pid != :undefined

    :timer.sleep(2000)
    {:ok, pid} = Connections.get_peer_ping_server(node_id, :b)
    assert pid != :undefined
    {:error, _} = Connections.get_peer_ping_server(node_id, :c)
  end

  # ********* A snippet for debugging purposes. **********************
  # Node.start :"a@127.0.0.1"
  # Node.set_cookie :"hide_and_seek"
  # node_id = :a
  # peers = [
  #   {:b, :"b@127.0.0.1"},
  #   {:c, :"c@127.0.0.1"}
  # ]
  # node_config = [
  #   node_id: node_id, 
  #   session_id: 1,
  #   node_name: :"a@127.0.0.1",
  #   peers: peers
  # ]
  # config = Vivaldi.Peer.Config.new(node_config)
  # Vivaldi.Peer.Connections.start_link(config)
  # Vivaldi.Peer.Connections.get_peer_ping_server(:a, :b)


end
