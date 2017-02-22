defmodule Vivaldi.Experiment.Logcentral do
  use GenServer

  require Logger

  alias Vivaldi.Experiment.CoordinateUpdateEvent

  def start_link(file_path) do
    GenServer.start_link(__MODULE__, {file_path})
  end

  def to_json(src, dst) do
    {:ok, content} = File.read(src)
    content
    |> String.trim()
    |> String.trim_trailing(",")
    |> (fn lines ->
      "{\"events\": [#{lines}]}"
    end).()
    |> (fn json_content ->
      File.write(dst, json_content)
    end).()
  end

  def init(args) do
    :yes = :global.register_name(:logcentral, self)
    {:ok, args}
  end

  def handle_cast({:"coordinate-update-event", event}, {file_path}) do

    # TODO: Implement a file backend. 
    # Until then, append events to a file
    %CoordinateUpdateEvent{}
    |> Map.merge(event)
    |> Poison.encode!()
    |> (fn json_event -> "#{json_event},\n" end).()
    |> (fn line -> File.write(file_path, line, [:append]) end).()

    {:noreply, {file_path}}
  end
  
end
