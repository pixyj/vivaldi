defmodule Vivaldi do

  require Logger

  alias Vivaldi.Peer.Supervisor

  def main(argv) do
    {options, _, _} = OptionParser.parse(argv)
    
    node_id = options[:nodeid] |> String.to_atom()
    node_name = options[:nodename] |> String.to_atom()
    cookie = options[:cookie] |> String.to_atom()
    controller_name = options[:controllername] |> String.to_atom()
    
    {:ok, _pid} = Node.start(node_name)
    Node.set_cookie(cookie)

    Logger.info "#{node_id} - Started node #{Node.self}"

    case Node.connect(controller_name) do 
      true ->
        Logger.info "#{node_id} - Connected to the controller. Starting PeerSupervisor..."

        Supervisor.start_link(node_id)

        # I couldn't get distillery to work. 
        # So here's a hack to keep the application running 
        # until we collect enough data for the experiment. 
        :timer.sleep(1000 * 86400)
      _ ->
        Logger.error "Could not connect to controller. Exiting..."
    end


  end
  
end
