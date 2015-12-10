defmodule ExPool.Manager.Joiner do
  alias ExPool.State

  def join(state, worker) do
    case Process.alive?(worker) do
      true  -> check_in(state, worker)
      false -> clean_dead_worker(state, worker)
    end
  end

  defp check_in(state, worker) do
    case State.pop_from_queue(state) do
      {:ok, {from, state}} -> check_out(state, worker, from)
      {:empty, state}      -> stash(state, worker)
    end
  end

  defp check_out(state, worker, {pid, _ref} = from) do
    {:ok, ref} = State.ref_from_item(state, {:waiting, pid})

    state = state
            |> State.remove_monitor({:waiting, pid})
            |> State.add_monitor({:in_use, worker}, ref)

    {:check_out, {from, worker, state}}
  end

  defp stash(state, worker) do
    case State.ref_from_item(state, {:in_use, worker}) do
      {:ok, ref} -> Process.demonitor(ref)
      :not_found -> nil
    end

    state = state
            |> State.remove_monitor({:in_use, worker})
            |> State.return_worker(worker)

    {:ok, state}
  end

  defp clean_dead_worker(state, worker) do
    case State.ref_from_item(state, {:worker, worker}) do
      {:ok, _ref} -> demonitor_and_respond(state, worker)
      :not_found  -> {:ok, state}
    end
  end

  defp demonitor_and_respond(state, worker) do
    state = state
            |> State.remove_monitor({:worker, worker})

    {:dead_worker, state}
  end
end
