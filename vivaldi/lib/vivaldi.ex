defmodule Vivaldi do

  require Logger

  alias Vivaldi.Peer.Supervisor

  def main(argv) do
    {options, _, _} = OptionParser.parse(argv)
    
    node_id = options[:nodeid] |> String.to_atom()
    node_name = options[:nodename] |> String.to_atom()
    cookie = options[:cookie] |> String.to_atom()
    
    {:ok, _pid} = Node.start(node_name)
    Node.set_cookie(cookie)

    Logger.info "#{node_id} - #{Node.self} is up!. Waiting for controller to connect..."

    Supervisor.start_link(node_id)

    # This is a hack. Don't exit since controller will connect soon!
    :timer.sleep(1000 * 86400)
  end
  
end
