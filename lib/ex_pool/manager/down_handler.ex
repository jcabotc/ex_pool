defmodule ExPool.Manager.DownHandler do
  alias ExPool.State

  def process_down(state, ref) do
    case State.item_from_ref(state, ref) do
      {:ok, {:worker, worker}} -> worker_down(state, worker)
      {:ok, {:in_use, worker}} -> using_process_down(state, worker)
      {:ok, {:waiting, pid}}   -> waiting_process_down(state, pid)
      :not_found               -> {:ok, state}
    end
  end

  defp worker_down(state, worker) do
    case State.ref_from_item(state, {:in_use, worker}) do
      {:ok, ref} -> Process.demonitor(ref)
      :not_found -> nil
    end

    state = state
            |> State.remove_monitor({:in_use, worker})
            |> State.remove_monitor({:worker, worker})

    {:dead_worker, state}
  end

  defp using_process_down(state, worker) do
    state = state
            |> State.remove_monitor({:in_use, worker})

    {:check_in, {worker, state}}
  end

  defp waiting_process_down(state, pid) do
    state = state
            |> State.remove_monitor({:waiting, pid})
            |> State.keep_on_queue fn {waiting_pid, _ref} ->
                 waiting_pid != pid
               end

    {:ok, state}
  end
end
