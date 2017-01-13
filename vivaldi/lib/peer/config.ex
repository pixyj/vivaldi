defmodule Vivaldi.Peer.Config do

  require Logger

  def defaults do
    [ vector_dimension:           2,
      height_min:                10.0e-6,
      vivaldi_cc:                 0.25,
      vivaldi_ce:                 0.25,
      vivaldi_error_max:          1.5,
      zero_threshold:             1.0e-6,
      ping_timeout:               20_000,
      ping_repeat:                8,
      ping_gap_interval:          5_000,
      whereis_name_wait_interval: 500,
      local_mode?:                false,
    ]
  end

  def new(config) do
    mandatory_keys = [:node_id, :node_name, :session_id, :peers]
    Enum.each(mandatory_keys, fn key ->
      if config[key] == nil do
        Logger.error "Config: #Required key #{key} not present. The system will crash!"
      end
    end)

    defaults()
    |> Keyword.merge(config) 
    |> Keyword.merge([
      peer_names_by_id: get_peer_names_by_id(config[:peers])
    ])
    |> Keyword.merge([
      peer_ids: get_peer_ids(config[:peers])
    ])
  end

  def get_peer_names_by_id(peers) do
    Enum.map(peers, fn {peer_id, peer_name} ->
      {peer_id, peer_name}
    end)
    |> Enum.into(%{})
  end

  def get_peer_ids(peers) do
    Enum.map(peers, fn {peer_id, _peer_name} ->
      peer_id 
    end)
  end

end