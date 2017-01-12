defmodule Vivaldi.Peer.PingClient do
  @moduledoc """
  Periodically Pings peers in a random order, and measures RTT on response. 
  When 8(configurable) responses are received from another peer `x_j`, the median RTT and latest coordinate of `x_j` is chosen, and sent to the Coordinate process 
  so that it can update our coordinate, `x_i`

  This is a stateless process, i.e. individual pings and peer states are not maintained.
  For example, if `x_j` crashes after 4 pings and doesn't respond, we just move on to the next peer. 
  """
  use GenServer
  use Timex

  require Logger

  alias Vivaldi.Peer.{Connections, PingServer}

  @ping_timeout 20000

  def start_link(node_id, session_id, peer_ids) do
    Logger.info "#{node_id} - Starting PingClient"
    GenServer.start_link(__MODULE__, {node_id, session_id, peer_ids})
  end

  def handle_call(:begin_pings, _, {node_id, session_id, peer_ids}) do
    spawn_link(fn -> begin_periodic_pinger(node_id, session_id, peer_ids) end)
    {:reply, :ok, {node_id, peer_ids}}
  end

  @doc """
  Pings peer_ids in random order serially.
  Should we introduce concurrent pinging? 
  """
  def begin_periodic_pinger(node_id, session_id, peer_ids) do
    peer_ids 
    |> Enum.shuffle()
    |> Enum.map(fn peer_id ->
      case ping_multi(node_id, session_id, peer_id) do
        {:ok, {rtt, other_coordinate}} ->
          # Placeholder. Update Coordinate here.
          x = 1
        {:error, reason} ->
          Logger.error "#{node_id} - ping_multi to #{peer_id} failed. #{reason}"
      end
      :timer.sleep(5000)
    end)
    begin_periodic_pinger(node_id, session_id, peer_ids)
  end

  def ping_multi(node_id, session_id, peer_id, times \\ 8) do
    start_ping_id = generate_start_ping_id()
    case Connections.get_peer_ping_server(node_id, peer_id) do
      {:ok, server_pid} ->
        Stream.map(1..times, fn i ->
          ping_once(node_id, session_id, peer_id, server_pid, start_ping_id + i)
        end)
        |> Stream.filter(fn {status, _} ->
          status == :pong
        end)
        |> Stream.map(fn {_, response} -> response end)
        |> Enum.into([])
        |> get_median_rtt_and_last_coordinate()

      {:error, reason} ->
        {:error, reason}
    end
  end

  def ping_once(node_id, session_id, peer_id, peer_server_pid, ping_id, timeout \\ @ping_timeout) do
    start = Duration.now()
    response = PingServer.ping(node_id, session_id, peer_id, peer_server_pid, ping_id, timeout)
    finish = Duration.now()

    case response do
      {:pong, payload} ->
        rtt = calculate_rtt(start, finish)
        other_coordinate = payload[:coordinate]
        {:pong, {rtt, other_coordinate}}
      {:pang, message} ->
        Logger.error message
        {:pang, message}
        {:error, message}
      {:error, reason} ->
        Logger.warn "Ping to #{peer_id} failed. Reason: #{inspect reason}"
        {:error, reason}
      _ ->
        message = "Unknown response from #{peer_id} to ping: #{ping_id}"
        Logger.error message
        {:error, message}
    end
  end

  def get_median_rtt_and_last_coordinate([]) do
    {:error, "No valid responses received"}
  end

  def get_median_rtt_and_last_coordinate(responses) do
    {:ok, {get_median_rtt(responses), get_last_coordinate(responses)}}
  end

  def get_median_rtt(responses) do
    rtts = Enum.map(responses, fn {rtt, _} -> rtt end)
    sorted_rtts = Enum.sort(rtts)
    count = Enum.count(sorted_rtts)
    case rem(count, 2) do
      1 ->
        median_index = round(count/2) - 1
        Enum.at(sorted_rtts, median_index)
      0 ->
        middle = round(count/2)
        {median_index_1, median_index_2} = {middle, middle - 1}
        rtt_1 = Enum.at(sorted_rtts, median_index_1)
        rtt_2 = Enum.at(sorted_rtts, median_index_2)
        (rtt_1 + rtt_2) / 2
    end
  end

  def get_last_coordinate(responses) do
    {_rtt, coordinate} = List.last(responses)
    coordinate
  end

  @doc """
  Generate a random id. We'll just use a 3 digit integer for now, for debugging. 
  If id's clash, we'll probably use something like an uuid
  """
  def generate_start_ping_id do
    :rand.uniform() * 1000 |> round()
  end

  def calculate_rtt(start, finish) do
    microseconds = Duration.diff(finish, start, :microseconds)
    microseconds * 1.0e-6
  end

end