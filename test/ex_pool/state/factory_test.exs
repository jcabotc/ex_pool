defmodule ExPool.State.FactoryTest do
  use ExUnit.Case

  alias ExPool.State.Factory

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    factory = Factory.new(worker_mod: TestWorker)

    {:ok, %{factory: factory}}
  end

  test "create/1, destroy/2, report_dead/1", %{factory: factory} do
    {worker_1, factory} = Factory.create(factory)
    {worker_2, factory} = Factory.create(factory)
    assert factory.total == 2

    factory = Factory.destroy(factory, worker_2)
    refute Process.alive?(worker_2)
    assert factory.total == 1

    Agent.stop(worker_1)
    factory = Factory.report_death(factory)
    assert factory.total == 0
  end
end
