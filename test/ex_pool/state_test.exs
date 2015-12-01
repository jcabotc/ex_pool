defmodule ExPool.StateTest do
  use ExUnit.Case

  alias ExPool.State

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  test "#new, #size" do
    state = State.new(worker_mod: TestWorker, size: 10)

    assert %{worker_mod: TestWorker, size: 10} = state
    assert 10 = State.size(state)
  end
end
