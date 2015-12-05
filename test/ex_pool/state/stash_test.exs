defmodule ExPool.State.StashTest do
  use ExUnit.Case

  alias ExPool.State.Stash

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    stash = Stash.new([])

    {:ok, %{stash: stash}}
  end

  test "#available, #get, #put", %{stash: stash} do
    worker_1 = TestWorker.start_link
    worker_2 = TestWorker.start_link

    stash = Stash.return(stash, worker_1)
    stash = Stash.return(stash, worker_2)
    assert 2 = Stash.available(stash)

    assert {:ok, {worker_1, stash}}  = Stash.get(stash)
    assert {:ok, {_worker_2, stash}} = Stash.get(stash)
    assert {:empty, ^stash}          = Stash.get(stash)
    assert 0 = Stash.available(stash)

    stash = Stash.return(stash, worker_1)
    assert 1 = Stash.available(stash)
    assert {:ok, {^worker_1, _stash}} = Stash.get(stash)
  end
end
