defmodule ExPool.Pool.Monitors do
  @moduledoc """
  Manages the queue of waiting requests of the pool.
  """

  @doc """
  Creates an empty queue
  """
  @spec setup(State.t) :: State.t
  def setup(state) do
    %{state | monitors: :ets.new(:monitors, [:private])}
  end

  @doc """
  Adds the given item and its associated reference
  """
  @spec add(State.t, item :: any, reference) :: State.t
  def add(%{monitors: monitors} = state, item, ref) do
    :ets.insert(monitors, {item, ref})

    state
  end

  @doc """
  Gets an item from its reference
  """
  @spec item_from_ref(State.t, reference) :: {:ok, item :: any} | :not_found
  def item_from_ref(%{monitors: monitors}, ref) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[item]] -> {:ok, item}
      []       -> :not_found
    end
  end

  @doc """
  Gets a reference from its item
  """
  @spec ref_from_item(State.t, item :: any) :: {:ok, reference} | :not_found
  def ref_from_item(%{monitors: monitors}, item) do
    case :ets.lookup(monitors, item) do
      [{^item, ref}] -> {:ok, ref}
      []             -> :not_found
    end
  end

  @doc """
  Removes the given item and its associated reference
  """
  @spec forget(State.t, item :: any) :: State.t
  def forget(%{monitors: monitors} = state, item) do
    :ets.delete(monitors, item)

    state
  end
end
