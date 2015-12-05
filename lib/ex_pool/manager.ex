defmodule ExPool.Manager do
  @moduledoc """
  Module to start a pool, and check-in and check-out workers.

  When a worker is available, it can be checked-out from the pool.
  In case there are no available workers it will respond `{:waiting, state}`
  and enqueue the pending request.

  When a worker is checked-in with any pending requests, it will
  respond with `{:check_out, {requester_identifier, state}}` and
  remove from de pending queue the current request.

  ## Example:

  ```elixir
  defmodule HardWorker do
    def start_link(_), do: Agent.start_link(fn -> :ok end)
  end

  alias ExPool.Manager

  state = Manager(worker_mod: HardWorker, size: 1)

  # There is a worker available. It can be checked-out.
  {:ok, {worker, state}} = Manager.check_out(state, :request_1)

  # There are no workers available. The current request identified
  # by :request_2 has to wait for available workers.
  {:waiting, state} = Manager.check_out(state, :request_2)

  # A worker is checked-in but there is a request pending. The
  # worker is checked_out to be used by the pending request (:request_2).
  {:check_out, {:request_2, state}} = Manager.check_in(state, worker)

  # There are no pending requests. The worker is checked-in properly.
  {:ok, state} = Manager.check_in(state, worker)
  ```
  """

  alias ExPool.State

  alias ExPool.Manager.Requester

  @doc """
  Create a new pool state with the given configuration.
  (See State.new/1 for more info about configuration options)
  """
  @spec new(config :: [Keyword]) :: State.t
  def new(config) do
    config
    |> State.new
    |> prepopulate
  end

  defp prepopulate(state) do
    prepopulate(state, State.size(state))
  end

  defp prepopulate(state, 0), do: state
  defp prepopulate(state, remaining) do
    {worker, state} = State.create_worker(state)
    state           = State.return_worker(state, worker)
    ref             = Process.monitor(worker)

    state |> State.add_monitor({:worker, worker}, ref) |> prepopulate(remaining - 1)
  end

  @doc """
  Gathers information about the current state of the pool.

  ## Format:

    %{
      workers: %{
        free: <number_of_available_workers>,
        in_use: <number_of_workers_in_use>,
        total: <total_number_of_workers>
      },
      waiting: <number_of_processes_waiting_for_an_available_worker>
    }
  """
  @spec info(State.t) :: map
  def info(state) do
    %{
      workers: workers_info(state),
      waiting: State.queue_size(state)
    }
  end

  defp workers_info(state) do
    total  = State.size(state)
    free   = State.available_workers(state)
    in_use = total - free

    %{total: total, in_use: in_use, free: free}
  end

  @doc """
  Check-out a worker from the pool.

  It receives the state, and a term to identify the current check-out
  request. In case there are no workers available, the same term will
  be returned by check-in to identify the requester of the worker.
  """
  @spec check_out(State.t, from :: any) :: {:ok, {pid, State.t}} | {:empty, State.t}
  def check_out(state, from),
    do: Requester.request(state, from)

  @doc """
  Check-in a worker from the pool.

  When returning a worker to the pool, there are 2 possible scenarios:

    * There aren't any worker requests pending: The worker is stored in the
    pool and responds with `{:ok, state}`.

    * There is any worker request pending: The worker is not stored. Instead
    the term identifying the request (`from`) is returned expecting the caller to yield
    the resource to the requester. It responds with
    `{:check_out, {from, worker, state}`.

  """
  @spec check_in(State.t, pid) ::
    {:ok, State.t} | {:check_out, {from :: any, worker :: pid, State.t}}
  def check_in(state, worker) do
    State.pop_from_queue(state) |> handle_check_in(worker)
  end

  def handle_check_in({:ok, {{pid, _} = from, state}}, worker) do
    {:ok, ref} = State.ref_from_item(state, {:waiting, pid})

    new_state = state
                |> State.remove_monitor({:waiting, pid})
                |> State.add_monitor({:in_use, worker}, ref)

    {:check_out, {from, worker, new_state}}
  end
  def handle_check_in({:empty, state}, worker) do
    {:ok, ref} = State.ref_from_item(state, {:in_use, worker})
    Process.demonitor(ref)

    new_state = state
                |> State.remove_monitor({:in_use, worker})
                |> State.return_worker(worker)

    {:ok, new_state}
  end

  @doc """
  Handle a process down.

  There are 2 types of monitored processes that can crash:

    * worker - If the crashed process is a worker, a new one is started
    and monitored

    * client - If the crashed process is a client, the worker that the
    process was using is returned to the pool

  """
  @spec process_down(State.t, reference) :: any
  def process_down(state, ref) do
    State.item_from_ref(state, ref) |> handle_process_down(state)
  end

  defp handle_process_down({:ok, {:worker, worker}}, state) do
    {new_worker, state} = state
                        |> State.remove_monitor({:worker, worker})
                        |> State.report_dead_worker
                        |> State.create_worker

    ref = Process.monitor(new_worker)
    state
    |> State.add_monitor({:worker, new_worker}, ref)
    |> State.return_worker(new_worker)
  end
  defp handle_process_down({:ok, {:in_use, worker}}, state) do
    state
    |> State.remove_monitor({:in_use, worker})
    |> State.return_worker(worker)
  end
  defp handle_process_down({:ok, {:waiting, pid}}, state) do
    state
    |> State.remove_monitor({:waiting, pid})
    |> State.keep_on_queue fn {waiting_pid, _ref} ->
         waiting_pid != pid
       end
  end
  defp handle_process_down(:not_found, state) do
    state
  end
end
