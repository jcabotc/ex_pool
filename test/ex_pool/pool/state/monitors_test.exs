defmodule ExPool.Pool.State.MonitorsTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Pool.State.Monitors

  setup do
    state = %State{} |> Monitors.setup

    {:ok, %{state: state}}
  end

  test "", %{state: state} do
  end
end
