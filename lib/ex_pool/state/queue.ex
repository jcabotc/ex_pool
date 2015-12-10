defmodule ExPool.State.Queue do
  @moduledoc """
  Manages the queue of waiting requests of the pool.
  """

  @type item  :: any
  @type items :: :queue.queue

  @type t :: %__MODULE__{
    items: items
  }

  defstruct items: nil

  alias ExPool.State.Queue

  @doc """
  Builds a new queue.
  """
  @spec new(config :: [Keyword]) :: t
  def new(_config) do
    items = :queue.new

    %Queue{items: items}
  end

  @doc """
  Returns the number of waiting processes.
  """
  @spec size(t) :: non_neg_integer
  def size(%Queue{items: items}), do: :queue.len(items)

  @doc """
  Adds an item to the queue.
  """
  @spec push(t, item) :: t
  def push(%Queue{items: items} = queue, item),
    do: %{queue|items: :queue.in(item, items)}

  @doc """
  Removes an item from the queue.
  """
  @spec keep(t, (item -> boolean)) :: t
  def keep(%Queue{items: items} = queue, filter),
    do: %{queue|items: :queue.filter(filter, items)}

  @doc """
  Pops an item from the queue.
  """
  @spec pop(t) :: {:ok, {item, t}} | {:empty, t}
  def pop(%Queue{items: items} = queue) do
    case :queue.out(items) do
      {{:value, item}, new_items} -> {:ok, {item, %{queue|items: new_items}}}
      {:empty, _queue}            -> {:empty, queue}
    end
  end
end
