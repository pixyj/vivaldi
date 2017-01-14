defmodule ControllerTest do
  use ExUnit.Case
  

  alias Vivaldi.Peer.ExperimentCoordinator

  alias Vivaldi.Experiment.Controller

  test "generate_peer_configs" do
    peers = [
      {:a, :"a@127.0.0.1"},
      {:b, :"b@127.0.0.1"},
      {:c, :"c@127.0.0.1"},
    ]
    
    configs = Controller.generate_peer_configs(peers, [session_id: 1])
    Enum.zip(peers, configs)
    |> Enum.map(fn {{peer_id, peer_name}, config} ->
      assert config[:node_id] == peer_id
      assert config[:node_name] == peer_name
      assert config[:session_id] == 1
      assert config[:zero_threshold] == 1.0e-6
    end)
  end

  test "connect" do
    Node.start :"a@127.0.0.1"
    # Without sleep, Node.connect doesn't work.
    :timer.sleep(30)

    peers = [
      {:a, :"a@127.0.0.1"},
      {:b, :"a@127.0.0.1"},
      {:c, :"a@127.0.0.1"},
    ]


    #Happy case
    configs = Controller.generate_peer_configs(peers, [session_id: 1])
    assert Controller.connect(peers) == true

    # Error case: Assign random name to :b
    peers = [
      {:a, :"a@127.0.0.1"},
      {:b, :"dd@127.0.0.1"},
      {:c, :"a@127.0.0.1"},
    ]
    assert Controller.connect(peers) == false
  end


  
end
