defmodule ExPool.Pool.State do
  alias ExPool.Pool.State
  alias ExPool.Pool.Supervisor, as: PoolSupervisor

  defstruct [:worker_mod, :size,
             :sup, :workers, :monitors, :queue]

  @default_size 5

  def new(config) do
    worker_mod = Keyword.fetch!(config, :worker_mod)
    size       = Keyword.get(config, :size, @default_size)

    %State{worker_mod: worker_mod, size: size} |> start
  end

  def get_worker(%{workers: []} = state) do
    {:empty, state}
  end
  def get_worker(%{workers: [worker|rest]} = state) do
    {:ok, {worker, %{state | workers: rest}}}
  end

  def put_worker(%{workers: workers} = state, worker) do
    %{state | workers: [worker|workers]}
  end

  def add_monitor(%{monitors: monitors} = state, pid, ref) do
    :ets.insert(monitors, {pid, ref})
    state
  end

  def get_pid(%{monitors: monitors}, ref) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] -> {:ok, pid}
      []      -> :not_found
    end
  end

  def get_monitor(%{monitors: monitors}, pid) do
    case :ets.lookup(monitors, pid) do
      [{^pid, ref}] -> {:ok, ref}
      []            -> :not_found
    end
  end

  def delete_monitor(%{monitors: monitors} = state, pid) do
    :ets.delete(monitors, pid)
    state
  end

  def enqueue(%{queue: queue} = state, pid, ref) do
    %{state | queue: :queue.in({pid, ref}, queue)}
  end

  def pop_from_queue(%{queue: queue} = state) do
    case :queue.out(queue) do
      {{:value, {pid, ref}}, new_queue} -> {:ok, {pid, ref, %{state | queue: new_queue}}}
      {:empty, _queue}                  -> {:empty, state}
    end
  end

  defp start(state) do
    state
    |> create_resources
    |> prepopulate
  end

  defp create_resources(%{worker_mod: worker_mod} = state) do
    {:ok, sup} = PoolSupervisor.start_link(worker_mod)
    monitors   = :ets.new(:monitors, [:private])
    queue      = :queue.new

    %{state | sup: sup, monitors: monitors, queue: queue, workers: []}
  end

  defp prepopulate(%{size: size, sup: sup} = state) do
    workers = for _i <- 1..size, do: create_worker(sup)

    %{state | workers: workers}
  end

  def create_worker(sup) do
    {:ok, worker} = PoolSupervisor.start_child(sup)
    worker
  end
end
