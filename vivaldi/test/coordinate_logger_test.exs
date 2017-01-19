defmodule VectorTest do
  use ExUnit.Case
  
  alias Vivaldi.Peer.{Config, CoordinateLogger}
  alias Vivaldi.Experiment.Logcentral


  test "Coordinate-update event" do

    log_path = "/tmp/events.log"
    {:ok, _} = Logcentral.start_link(log_path)

    config = get_config()
    {:ok, _} = CoordinateLogger.start_link(config)

    events = get_events()

    Enum.each(events, fn event ->
      CoordinateLogger.log(:a, event)
    end)
    :timer.sleep(200)

    {:ok, file} = File.open(log_path)
    content = IO.read(file, :all)
    :ok = File.close(file)

    assert Enum.count(String.split(content, "\n")) == 4

    File.rm(log_path)
  end

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

  def get_events do 
    event_1 = %{
      i: 0,
      j: 1,
      x_i: %{vector: [0, 0], height: 1.0e-6, error: 1.5},
      x_j: %{vector: [0, 0], height: 1.0e-6, error: 1.5},
      x_i_next: %{vector: [0.2, 0.2], height: 1.0e-6, error: 1.43},
      rtt: 0.2
    }

    event_2 = %{
      i: 0,
      j: 2,
      x_i: %{vector: [0.2, 0.2], height: 1.0e-6, error: 1.5},
      x_j: %{vector: [0, 0], height: 1.0e-6, error: 1.5},
      x_i_next: %{vector: [0.22, 0.18], height: 1.0e-6, error: 1.40},
      rtt: 0.1
    }

    event_3 = %{
      i: 0,
      j: 2,
      x_i: %{vector: [0.22, 0.18], height: 1.0e-6, error: 1.5},
      x_j: %{vector: [1, 0], height: 1.0e-6, error: 1},
      x_i_next: %{vector: [0.24, 0.16], height: 1.0e-6, error: 1.35},
      rtt: 0.2
    }

    [event_1, event_2, event_3]
  end

end