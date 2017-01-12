defmodule Vivaldi.Peer.Config do

  require Logger

  @height_min                 10.0e-6
  @vivaldi_cc                 0.25
  @vivaldi_ce                 0.25
  @vivaldi_error_max          1.5
  @zero_threshold             1.0e-6
  @ping_timeout               20_000
  @whereis_name_wait_interval 500

  def new(config) do
    mandatory_keys = [:node_id, :node_name, :session_id, :peers]
    Enum.each(mandatory_keys, fn key ->
      if config[key] == nil do
        Logger.error "Config: #Required key #{key} not present. The system will crash!"
      end
    end)

    defaults = [
      height_min: @height_min,
      vivaldi_cc: @vivaldi_cc,
      vivaldi_ce: @vivaldi_ce,
      vivaldi_error_max: @vivaldi_error_max,
      zero_threshold: @zero_threshold,
      whereis_name_wait_interval: @whereis_name_wait_interval
    ]
    defaults 
    |> Keyword.merge(config) 
    |> Keyword.merge([
      peer_names_by_id: get_peer_names_by_id(config[:peers])
    ])
  end

  def get_peer_names_by_id(peers) do
    Enum.map(peers, fn {peer_id, peer_name} ->
      {peer_id, peer_name}
    end)
    |> Enum.into(%{})
  end

end