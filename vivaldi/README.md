# Implementation in Elixir

We have three major components:

## Peer:

Vivaldi is a fully decentralized protocol/algorithm. Each node(peer) runs a copy of the algorithm and updates its coordinates whenever it communicates with other peers. 


The following processes run on each peer. 

**PingServer**: Responds to pings from other peers with the latest version of its coordinates. 

**PingClient**: Periodically pings other peers in the cluster, and sends RTT and peer coordinates to the `Coordinate` process. 

**Connections**: Connects to peers when necessary. In local mode, all it does is finds the appropriate `PingServer` process. In distributed mode, it connects to the remote peer and then uses :global.whereis_name to locate the peer's `PingServer` process.

**Coordinate**: Maintains Vivaldi coordinates of the peer. When it receives a `:update_coordinate` message from the `PingClient`, it runs the Vivaldi algorithm and updates its coordinates. 

**CoordinateLogger**: Sends coordinates to the controller

**Coordinate Stash**: Stores the latest version of the coordinate. 

**AlgorithmSupervisor**: Supervises above processes.

**ExperimentCoordinator**: Coordinates with the controller when tuning the algorithm. 

**PeerSupervisor**: Top-level supervisor.

___


## Controller:

Before deploying Vivaldi on a cluster, we may need to tune the parameters of the algorithm. So, a `Controller` node is used to configure the peers, collect results, and make changes if required. 

The following processes run on the controller.

**Controller**: Configures peers and kicks off the Vivaldi algorithm on each peer. 

**LogCentral**: Receives coordinate-update events from all peers and logs them to a file, used later for visualization, debugging and tuning.

____

## Simulation

If RTT(the round-trip-time) between each node pair is available, we can use it to simulate the algorithm, and check if it works in the presence of triangle inequalities.

____


