defmodule ExPool.Pool.StateTest do
  use ExUnit.Case

  alias ExPool.Pool.State

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker)

    {:ok, %{state: state}}
  end
end
