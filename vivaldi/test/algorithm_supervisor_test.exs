defmodule AlgorithmSupervisorTest do
  use ExUnit.Case
  
  alias Vivaldi.Peer.{AlgorithmSupervisor, Config, PingClient}

  test "Just ensure nothing crashes :)" do
    Node.start :"a@127.0.0.1"
    Node.set_cookie :"hide_and_seek"

    peers = [
      {:a, :"a@127.0.0.1"},
      {:b, :"a@127.0.0.1"},
      {:c, :"a@127.0.0.1"}
    ]
    peers
    |> Enum.map(fn {node_id, node_name} ->
      conf = [
        node_id: node_id,
        node_name: node_name,
        session_id: 1,
        peers: other_peers(peers, node_id),
        ping_gap_interval: 20,
        local_mode?:  true
      ]
      Config.new(conf)
    end)
    |> Enum.map(fn config -> 
      {:ok, pid} = AlgorithmSupervisor.start_link(config)
      config
    end)
    |> Enum.map(fn config -> :timer.sleep(30); config end)
    |> Enum.map(fn config ->
      PingClient.begin_pings(config[:node_id])
    end)

    :timer.sleep(2000)

  end

  def other_peers(peers, my_node_id) do
    Enum.filter(peers, fn {other_node_id, _} ->
      my_node_id != other_node_id
    end)
  end
end
