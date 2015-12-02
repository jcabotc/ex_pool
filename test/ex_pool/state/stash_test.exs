defmodule ExPool.State.StashTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.State.Stash

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = %State{worker_mod: TestWorker} |> Stash.setup

    {:ok, %{state: state}}
  end

  test "#create, #length,  #get, #put", %{state: state} do
    {_worker, state} = Stash.create(state)
    {_worker, state} = Stash.create(state)

    assert 2 = Stash.count(state)

    assert {:ok, {worker_1, state}}  = Stash.get(state)
    assert {:ok, {_worker_2, state}} = Stash.get(state)
    assert {:empty, ^state}          = Stash.get(state)

    assert 0 = Stash.count(state)

    state = Stash.put(state, worker_1)

    assert {:ok, {^worker_1, _state}} = Stash.get(state)
  end
end
