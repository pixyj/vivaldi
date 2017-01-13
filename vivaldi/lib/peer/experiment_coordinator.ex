defmodule Vivaldi.Peer.ExperimentCoordinator do
  @moduledoc """
  * Runs at each peer.
  * Passes commands from controller to peer processes
  * Answers status requests to controller

  The variable `status` used everywhere refers to the status of the experiment, and is
  part of the GenServer `state`
  """

  use GenServer

  require Logger

  alias Vivaldi.Peer.{Connections, Coordinate, CoordinateLogger, 
                      CoordinateStash, PingClient, PingServer}

  def start_link(config, state_agent, algo_sup) do
    name = get_name(config[:node_id])
    GenServer.start_link(__MODULE__, [config, state_agent, algo_sup], name: name)
  end

  def get_name(node_id) do
    :"#{node_id}-experiment-coordinator"
  end

  def init(config, state_agent) do
    node_id = config[:node_id]
    name = get_name(node_id)
    Logger.info "#{node_id} - starting #{name}..."
    status = Agent.get(state_agent, fn status -> status end)
    :yes = :global.register_name(name, self)
    {:ok, {status, state_agent, config}}
  end

  def handle_call(:get_ready, _, {:just_started, state_agent, config}) do
    node_id = config[:node_id]
    names = [
      Connections.get_name(node_id),
      Coordinate.get_name(node_id)
      CoordinateLogger.get_name(node_id)
      CoordinateStash.get_name(node_id)
      PingClient.get_name(node_id)
      PingServer.get_name(node_id)
    ]

    ready? = Enum.map(names, fn name -> 
      case Process.whereis(name) do
        nil ->
          Logger.warn "#{node_id} #{name} isn't running. We are not ready yet..."
          nil
        pid ->
          pid
      end
    end)
    |> Enum.filter(fn pid ->
      pid == nil
    end)
    |> (fn nil_statuses -> Enum.count(nil_statuses) == 0).()

    if ready? do
      {:reply, :ok, {:ready, state_agent, config}}
    else
      {:reply, :error, {:just_started, state_agent, config}}
    end
  end

  def handle_call(:begin_pings, _, {:ready, state_agent, config}) do
    node_id = config[:node_id]
    name = PingClient.get_name(node_id)
    case log_command_and_get_process(node_id, :begin_pings, name, {:ready, state_agent, config}) do
      {:error, response} ->
        response
      {:ok, _} ->
        PingClient.begin_pings(node_id)
        log_command_executed(node_id, :begin_pings, status)

        next_status = :pinging
        set_status(node_id, state_agent, status, next_status)
        {:reply, :ok, {next_status, state_agent, config}}
    end

    node_id = config[:node_id]
    name = PingClient.get_name(node_id)
    case Process.whereis(name) do
      nil ->
        message = "#{node_id}: cannot execute command :begin_pings. PingClient isn't running"
        Logger.error message
        {:reply, {:error, message}, {:just_started, state_agent, config}}
      pid ->
        {:reply, :ok, {:pinging, state_agent, config}}
    end
  end

  def handle_call(:stop_pings, _, {:pinging, state_agent, config}) do
    node_id = config[:node_id]
    name = PingClient.get_name(node_id)
    case log_command_and_get_process(node_id, :stop_pings, name, {:pinging, state_agent, config}) do
      {:error, response} ->
        response
      {:ok, ping_client} ->
        Process.exit ping_client, :kill
        log_command_executed(node_id, :stop_pings, status)
        :timer.sleep(100)
        # Hopefully, ping_client is restarted by its supervisor by now
        case Process.whereis(name) do
          nil ->
            Logger.error "#{node_id} -> ping_client has not restarted yet..."
            next_status = :just_started
            set_status(node_id, state_agent, status, next_status)
            {:reply, {:error, :restart_failed}, {next_status, state_agent, config}}
          _ ->
            next_status = :ready
            set_status(node_id, state_agent, status, next_status)
            {:reply, :ok, {next_status, state_agent, config}}
        end
    end
  end

  def handle_call(:force_reset, _, {status, state_agent, config}) do
    node_id = config[:node_id]
    name = AlgorithmSupervisor.get_name(node_id)
    case log_command_and_get_algo_sup(node_id, :force_reset, name, {status, state_agent, config}) do
      {:error, response} ->
        response
      {:ok, algo_sup} ->
        Process.exit pid, :kill
        log_command_executed(node_id, :force_reset, status)
        # Should we check if processes are restarted here? 
        next_status = :just_started
        set_status(node_id, state_agent, status, next_status)
        {:reply, :ok, {next_status, state_agent, config}}
    end
  end

  # TODO: Handle invalid commands

  def log_command_and_get_process(node_id, command, name, {status, state_agent, config}) do
    log_command_received(node_id, command, status)
    case Process.whereis(name) do
      nil ->
        message = "#{node_id} - ignored #{command}: #{name} isn't running"
        Logger.error message
        {:error, {:reply, {:error, message}, {status, state_agent, config}}}
      pid ->
        {:ok, pid}
    end
  end

  def set_status(node_id, state_agent, status, next_status) do
    if status != next_status do
      Agent.update(state_agent, fn _ -> next_status end)
      Logger.info "#{node_id} - changed status #{status} -> #{next_status}"
    end
  end

  def log_command_received(node_id, command, status) do
    Logger.info "#{node_id} - at status: #{status} - received command #{command}"
  end

  def log_command_executed(node_id, command, status) do
    Logger.info "#{node_id} - at status: #{status} - executed command #{command}"
  end

end
