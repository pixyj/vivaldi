# Vivaldi


[![Build Status](https://api.travis-ci.org/pixyj/vivaldi.svg)](https://travis-ci.org/pixyj/vivaldi) [![Coverage Status](https://coveralls.io/repos/github/pixyj/vivaldi/badge.svg?branch=master)](https://coveralls.io/github/pixyj/vivaldi?branch=master)

Prototyping and visualizing the [Vivaldi algorithm](https://www.semanticscholar.org/paper/Vivaldi-a-decentralized-network-coordinate-system-Dabek-Cox/424909ea3e4e5a8cfe5363420926c1b10fbbf034) in Elixir.

_____

## Test it for yourself!


1. Clone the repo

```
git clone git@github.com:pixyj/vivaldi.git
```

2. `cd` to the `vivaldi` directory

```
cd vivaldi
```

3. Fetch dependencies

```
mix deps.get
```

4. Run tests

```
epmd -daemon
mix test
```

5. Build the `vivaldi` binary

```
mix escript.build
```

6. Copy the binary to a bunch of servers

7. On each peer:

7.1 [Install Erlang](http://erlang.org/doc/installation_guide/INSTALL.html)
7.2 Start the epmd daemon. 
    ```
    epmd -daemon
    ```
7.3 Start the peer.

(Assign a unique node_id to each peer)

  ./vivaldi --nodeid <node_id> --nodename <node_id>@<node_ip_address> --cookie <cookie>

8. Start the algorithm using the controller.

You can run the controller on your local machine using `iex`

8.1 Start `iex`

```
iex -S mix
```

8.2. List all peers

```
peers = [
  "<peer_ip_address_1>",
  "<peer_ip_address_2",
  # And so on
]
```

8.3 Start the controller node

```
alias Vivaldi.Experiment.Controller

cookie = :<cookie>
ip_address = "<ip_address>"

Controller.start :"controller@#{ip_address}", cookie, peers
```

And we're done! Let the algorithm run for a few minutes.


9. Collect Results

```
Controller.visualize()
```

A file call `my_events.json` will be placed in the visualization directory.

10. Visualize!

Follow instructions at the [visualization](https://github.com/pixyj/vivaldi/tree/master/visualization) directory.
