defmodule ConnectionsTest do
  use ExUnit.Case

  alias Vivaldi.Peer.Connections

  setup_all do
    Node.start :"a@127.0.0.1"
    Node.set_cookie :"hide_and_seek"
    spawn fn -> :os.cmd :"elixir test/peer_b.exs" end
    spawn fn -> :os.cmd :"elixir test/peer_c.exs" end
    IO.puts "Spawned peers!!!"
    :ok
  end

  test "connections" do
    :timer.sleep(500)
    IO.puts "Begin Testing...."
    node_id = :a
    peers = [
      {:b, :"b@127.0.0.1"},
      {:c, :"c@127.0.0.1"}
    ]
    Connections.start_link(node_id, peers)
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
  # Vivaldi.Peer.Connections.start_link(node_id, peers)
  # Vivaldi.Peer.Connections.get_peer_ping_server(:a, :b)


end
