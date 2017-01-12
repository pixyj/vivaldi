defmodule ConfigTest do
  use ExUnit.Case
  
  alias Vivaldi.Peer.Config

  test "peer_names_by_id" do
    peers = [
      {:b, :"b@127.0.0.1"},
      {:c, :"c@127.0.0.1"}
    ]
    result = Config.get_peer_names_by_id(peers)
    Enum.each(peers, fn {peer_id, peer_name} ->
      assert result[peer_id] == peer_name
    end)
  end

  test "config override" do
    peers = [
      {:b, :"b@127.0.0.1"},
      {:c, :"c@127.0.0.1"}
    ]
    conf = [
      node_id: :a,
      node_name: :"a@127.0.0.1",
      session_id: 1,
      peers: peers,
      vivaldi_ce: 0.5
    ]
    config = Config.new(conf)
    assert config[:vivaldi_ce] == 0.5
    assert config[:peer_names_by_id][:b] == :"b@127.0.0.1"
    assert config[:peer_names_by_id][:c] == :"c@127.0.0.1"
  end
end
