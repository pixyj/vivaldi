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

  def start_link(config) do
    node_id = config[:node_id]
    Logger.info "#{node_id} - starting PingClient..."
    GenServer.start_link(__MODULE__, config)
  end

  def handle_call(:begin_pings, _, config) do
    node_id = config[:node_id]
    Logger.info "#{node_id} - starting. Starting periodic_pinger..."
    spawn_link(fn -> begin_periodic_pinger(config) end)
    {:reply, :ok, config}
  end

  @doc """
  Pings peer_ids in random order serially.
  Should we introduce concurrent pinging? 
  """
  def begin_periodic_pinger(config) do
    node_id = config[:node_id]

    config[:peer_ids]
    |> Enum.shuffle()
    |> Enum.map(fn peer_id ->
      case ping_multi(config, peer_id) do
        {:ok, {rtt, other_coordinate}} ->
          # Placeholder. Update Coordinate here.
          x = 1
        {:error, reason} ->
          Logger.error "#{node_id} - ping_multi to #{peer_id} failed. #{reason}"
      end
      config[:ping_gap_interval]
    end)
    begin_periodic_pinger(config)
  end

  def ping_multi(config, peer_id) do
    {node_id, times} = {config[:node_id], config[:ping_repeat]}
    start_ping_id = generate_start_ping_id()
    case Connections.get_peer_ping_server(node_id, peer_id) do
      {:ok, server_pid} ->
        Logger.info "#{node_id} - Pinging #{peer_id} #{times} times..."
        Stream.map(1..times, fn i ->
          ping_once(config, peer_id, server_pid, start_ping_id + i)
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

  def ping_once(config, peer_id, peer_server_pid, ping_id) do
    {node_id, session_id, timeout} = {config[:node_id], config[:session_id], config[:ping_timeout]}
    Logger.info "#{node_id} - sending ping: #{ping_id} to #{peer_id}"
    start = Duration.now()
    response = PingServer.ping(node_id, session_id, peer_id, peer_server_pid, ping_id, timeout)
    finish = Duration.now()

    case response do
      {:pong, payload} ->
        Logger.info "#{node_id} - received pong: #{ping_id} from #{peer_id}"
        rtt = calculate_rtt(start, finish)
        other_coordinate = payload[:coordinate]
        {:pong, {rtt, other_coordinate}}
      {:pang, message} ->
        Logger.error message
        {:pang, message}
        {:error, message}
      {:error, reason} ->
        Logger.warn "#{node_id} - ping to #{peer_id} failed. Reason: #{inspect reason}"
        {:error, reason}
      _ ->
        message = "#{node_id} - unknown response from #{peer_id} to ping: #{ping_id}"
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