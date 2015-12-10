defmodule ExPool.Manager.Info do
  alias ExPool.State

  def get(state) do
    %{
      workers: workers(state),
      waiting: waiting(state)
    }
  end

  defp workers(state) do
    total  = State.total_workers(state)
    free   = State.available_workers(state)
    in_use = total - free

    %{total: total, free: free, in_use: in_use}
  end

  defp waiting(state), do: State.queue_size(state)
end
