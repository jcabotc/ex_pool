defmodule ExPool.State.QueueTest do
  use ExUnit.Case

  alias ExPool.State.Queue

  setup do
    queue = Queue.new([])

    {:ok, %{queue: queue}}
  end

  test "#push, #pop, #size", %{queue: queue} do
    assert {:empty, queue} = Queue.pop(queue)

    queue = Queue.push(queue, :from_1)
    queue = Queue.push(queue, :from_2)

    assert 2 = Queue.size(queue)

    assert {:ok, {:from_1, queue}} = Queue.pop(queue)
    assert {:ok, {:from_2, queue}} = Queue.pop(queue)
    assert {:empty, _state}        = Queue.pop(queue)

    assert 0 = Queue.size(queue)
  end

  test "#keep", %{queue: queue} do
    queue = queue
            |> Queue.push(:from_1)
            |> Queue.push(:from_2)
            |> Queue.push(:from_1)
            |> Queue.keep(&(&1 != :from_1))

    assert {:ok, {:from_2, queue}} = Queue.pop(queue)
    assert {:empty, _state}        = Queue.pop(queue)
  end
end
