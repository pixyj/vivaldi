defmodule Vivaldi.Peer.CoordinateLogger do
  @moduledoc """
  All coordinate-update events are sent here. Events are logged to stdout.
  TODO: Also log events to a centralized log aggregator.
  """
  use GenServer
  
  require Logger

  # API

  def start_link(config) do
    node_id = config[:node_id]
    GenServer.start_link(__MODULE__, {config, nil}, name: get_name(node_id))
  end

  def log(node_id, event) do
    GenServer.cast(get_name(node_id), {:"coordinate-update-event", event})
  end

  # Implementation

  def get_name(node_id) do
    :"#{node_id}-coordinate-logger"
  end

  def handle_cast({:"coordinate-update-event", event}, {config, logcentral_pid}) do
    case get_logcentral_pid(logcentral_pid) do
      nil ->
        # TODO: Send pending messages when logcentral comes back up. 
        Logger.error("FATAL error. logcentral pid not found. ")
        {:noreply, {config, nil}}

      new_logcentral_pid -> 
        GenServer.cast(new_logcentral_pid, {:"coordinate-update-event", event})
        {:noreply, {config, new_logcentral_pid}}
    end
  end

  def get_logcentral_pid(previous_logcentral_pid) do
    case previous_logcentral_pid do
      nil ->
        case :global.whereis_name(:logcentral) do
          :undefined ->
            nil
          pid ->
            pid
        end
      pid ->
        pid
    end
  end

end
