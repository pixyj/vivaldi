defmodule ExperimentCoordinatorTest do
  use ExUnit.Case

  alias Vivaldi.Peer.{Config, ExperimentCoordinator}

  setup_all do
    Node.start :"a@127.0.0.1"
    Node.set_cookie :"hide_and_seek"
    :ok
  end

  def get_config do
    peers = [
      {:d, :"a@127.0.0.1"}
    ]
    conf = [
      node_id: :a,
      node_name: :"a@127.0.0.1",
      session_id: 1,
      peers: peers,
      vivaldi_ce: 0.5,
      ping_gap_interval: 20
    ]
    Config.new(conf)
  end

  test "actions" do
    {:ok, state_agent} = Agent.start_link fn -> {:not_started, nil} end, []
    {:ok, exp} = ExperimentCoordinator.start_link(:a, state_agent)

    name = ExperimentCoordinator.get_name(:a)

    :ok = GenServer.call(name, {:configure_and_run, get_config()})
    :timer.sleep(30)
    {:ok, :just_started} = GenServer.call(name, :get_status)

    :ok = GenServer.call(name, :get_ready)
    :timer.sleep(30)
    {:ok, :ready} = GenServer.call(name, :get_status)


    GenServer.call(name, :begin_pings)
    :timer.sleep(1000)
    {:ok, :pinging} = GenServer.call(name, :get_status)
  end

end
