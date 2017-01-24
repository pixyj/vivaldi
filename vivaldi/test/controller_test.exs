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
      peers = config[:peers]
      assert Enum.count(peers) == 2
      Enum.map(peers, fn {other_id, _} ->
        assert other_id != peer_id
      end)
    end)

  end

  @tag c2: true
  test "connect and get_status" do
    Node.start :"a@127.0.0.1"
    # Without sleep, Node.connect doesn't work.
    :timer.sleep(100)

    peers = [
      {:a, :"a@127.0.0.1"},
      {:b, :"a@127.0.0.1"},
      {:c, :"a@127.0.0.1"},
    ]

    # Start peers. 
    Enum.map(peers, fn {peer_id, _} ->
      {:ok, state_agent} = Agent.start_link fn -> {:not_started, nil} end, []
      {:ok, _pid} = ExperimentCoordinator.start_link(peer_id, state_agent)
    end)

    #Happy case
    assert Controller.connect(peers) == {:ok, peers}
    assert Controller.verify_status(peers, :not_started) == {:ok, peers}

    # Error case: Assign random name to :b
    peers = [
      {:a, :"a@127.0.0.1"},
      {:b, :"dd@127.0.0.1"},
      {:c, :"a@127.0.0.1"},
    ]
    {:error, _} = Controller.connect(peers)
  end

  test "commands" do
    Node.start :"a@127.0.0.1"
    # Without sleep, Node.connect doesn't work.
    :timer.sleep(30)

    # Setup data structures
    peers = [
      {:a, :"a@127.0.0.1"},
      {:b, :"a@127.0.0.1"},
      {:c, :"a@127.0.0.1"},
    ]
    common_config = [session_id: 1, ping_gap_interval: 200]
    configs = Controller.generate_peer_configs(peers, common_config)

    # Start peers. 
    Enum.map(peers, fn {peer_id, _} ->
      {:ok, state_agent} = Agent.start_link fn -> {:not_started, nil} end, []
      {:ok, _pid} = ExperimentCoordinator.start_link(peer_id, state_agent)
    end)

    Controller.get_status(peers, :not_started)
    |> Enum.map(fn status -> assert status == :not_started end)
    
    # Run following commands
    # configure_and_run |> get_ready |> begin_pings
    Enum.zip(peers, configs)
    |> Enum.map(fn {{peer_id, peer_name}, config} ->
      command = {:configure_and_run, config}
      {{peer_id, peer_name}, command}
    end)
    |> (fn peers_and_commands -> 
      Controller.send_command(peers_and_commands)
      |> Enum.map(fn {_peer_id, result} -> assert result == :ok end)

      Controller.get_status(peers, :just_started)
      |> Enum.map(fn status -> assert status == :just_started end)
      peers
    end).()
    |> (fn peers ->
      peers
      |> Enum.map(fn {peer_id, peer_name} ->
        command = :get_ready
        {{peer_id, peer_name}, command}
      end)
      |> (fn peers_and_commands ->
        Controller.send_command(peers_and_commands)

        Controller.get_status(peers, :ready)
        |> Enum.map(fn status -> assert status == :ready end)
        peers
      end).()
    end).()
    |> (fn peers ->
      peers
      |> Enum.map(fn {peer_id, peer_name} ->
        command = :begin_pings
        {{peer_id, peer_name}, command}
      end)
      |> (fn peers_and_commands ->
        Controller.send_command(peers_and_commands)
        Controller.get_status(peers, :pinging)
        |> Enum.map(fn status -> assert status == :pinging end)
        peers
      end).()
    end).()

    # Wait, hoping there aren't any crashes :) 
    :timer.sleep(2000)
    
  end
  
end
