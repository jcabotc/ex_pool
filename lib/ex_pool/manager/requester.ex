defmodule ExPool.Manager.Requester do
  alias ExPool.State

  def request(state, from) do
    case State.get_worker(state) do
      {:ok, {worker, state}} -> check_out(state, worker, from)
      {:empty, state}        -> enqueue(state, from)
    end
  end

  def check_out(state, worker, {pid, _ref}) do
    ref = Process.monitor(pid)
    new_state = state
                |> State.add_monitor({:in_use, worker}, ref)

    {:ok, {worker, state}}
  end

  defp enqueue(state, {pid, _ref} = from) do
    ref = Process.monitor(pid)
    new_state = state
                |> State.add_monitor({:waiting, pid}, ref)
                |> State.enqueue(from)

    {:waiting, new_state}
  end
end
