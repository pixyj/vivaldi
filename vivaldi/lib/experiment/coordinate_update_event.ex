defmodule Vivaldi.Experiment.CoordinateUpdateEvent do
  @derive [Poison.Encoder]
  defstruct [:i, :j, :x_i, :x_j, :x_i_next, :rtt]
end
