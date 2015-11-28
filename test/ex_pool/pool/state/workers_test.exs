defmodule ExPool.Pool.State.WorkersTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Pool.State.Workers

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = %State{worker_mod: TestWorker} |> Workers.setup

    {:ok, %{state: state}}
  end

  test "#create, #get, #put", %{state: state} do
    {_worker, state} = Workers.create(state)
    {_worker, state} = Workers.create(state)

    assert {:ok, {worker_1, state}}  = Workers.get(state)
    assert {:ok, {_worker_2, state}} = Workers.get(state)
    assert {:empty, ^state}          = Workers.get(state)

    state = Workers.put(state, worker_1)

    assert {:ok, {^worker_1, _state}} = Workers.get(state)
  end
end
