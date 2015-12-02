defmodule ExPool.State.Monitors do
  @moduledoc """
  Manages the queue of waiting requests of the pool.
  """

  @type item :: any
  @type ref  :: reference

  @type table :: :ets.tid

  @type t :: %__MODULE__{
    table: table
  }

  defstruct table: nil

  alias ExPool.State.Monitors

  @doc """
  Creates a new Monitors struct.
  """
  @spec new(config :: [Keyword]) :: t
  def new(_config) do
    table = :ets.new(:monitors, [:private])

    %Monitors{table: table}
  end

  @doc """
  Adds the given item and its associated reference.
  """
  @spec add(t, item, ref) :: t
  def add(%Monitors{table: table} = monitors, item, ref) do
    :ets.insert(table, {item, ref})
    monitors
  end

  @doc """
  Gets an item from its reference.
  """
  @spec item_from_ref(t, ref) :: {:ok, item} | :not_found
  def item_from_ref(%Monitors{table: table}, ref) do
    case :ets.match(table, {:"$1", ref}) do
      [[item]] -> {:ok, item}
      []       -> :not_found
    end
  end

  @doc """
  Gets a reference from its item.
  """
  @spec ref_from_item(t, item) :: {:ok, ref} | :not_found
  def ref_from_item(%Monitors{table: table}, item) do
    case :ets.lookup(table, item) do
      [{^item, ref}] -> {:ok, ref}
      []             -> :not_found
    end
  end

  @doc """
  Removes the given item and its associated reference
  """
  @spec forget(t, item) :: t
  def forget(%Monitors{table: table} = monitors, item) do
    :ets.delete(table, item)
    monitors
  end
end
