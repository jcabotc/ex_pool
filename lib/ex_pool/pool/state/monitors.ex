defmodule ExPool.Pool.State.Monitors do
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
  Monitors the given pid and stores the reference and the tag.
  """
  @spec watch(State.t, pid, tag :: atom) :: State.t
  def watch(%{monitors: monitors} = state, tag, pid) do
    ref = Process.monitor(pid)
    :ets.insert(monitors, {pid, tag, ref})

    state
  end

  @doc """
  Gets a pid and its tag from the monitor reference.
  """
  @spec pid_from_ref(State.t, reference) ::
    {:ok, {tag :: atom, pid}} | :not_found
  def pid_from_ref(%{monitors: monitors}, ref) do
    case :ets.match(monitors, {:"$1", :"$2", ref}) do
      [[pid, tag]] -> {:ok, {tag, pid}}
      []           -> :not_found
    end
  end

  @doc """
  Demonitors the given pid and removes the reference.
  """
  @spec forget(State.t, pid) :: State.t
  def forget(%{monitors: monitors} = state, pid) do
    [{^pid, _tag, ref}] = :ets.lookup(monitors, pid)

    Process.demonitor(ref)
    :ets.delete(monitors, pid)

    state
  end
end
