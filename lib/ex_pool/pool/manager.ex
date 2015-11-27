defmodule ExPool.Pool.Manager do
  alias ExPool.Pool.State

  def new(config) do
    State.new(config)
  end

  def check_out(state, from) do
    case State.get_worker(state) do
      {:ok, {worker, new_state}} -> {:ok, {worker, new_state}}
      {:empty, state}            -> {:waiting, State.enqueue(state, from)}
    end
  end

  def check_in(state, worker) do
    case State.pop_from_queue(state) do
      {:ok, {from, state}} -> {:check_out, {from, state}}
      {:empty, state}      -> {:ok, State.put_worker(state, worker)}
    end
  end
end
