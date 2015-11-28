defmodule ExPool.Pool.Manager do
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

  alias ExPool.Pool.Manager

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

  alias ExPool.Pool.State

  @doc """
  Create a new pool state with the given configuration.
  (See State.new/1 for more info about configuration options)
  """
  @spec new(config :: [Keyword]) :: State.t
  def new(config) do
    State.new(config)
  end

  @doc """
  Check-out a worker from the pool.

  It receives the state, and a term to identify the current check-out
  request. In case there are no workers available, the same term will
  be returned by check-in to identify the requester of the worker.
  """
  @spec check_out(State.t, from :: any) :: {:ok, {pid, State.t}} | {:empty, State.t}
  def check_out(state, from) do
    case State.get_worker(state) do
      {:ok, {worker, new_state}} -> {:ok, {worker, new_state}}
      {:empty, state}            -> {:waiting, State.enqueue(state, from)}
    end
  end

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
    case State.pop_from_queue(state) do
      {:ok, {from, state}} -> {:check_out, {from, worker, state}}
      {:empty, state}      -> {:ok, State.put_worker(state, worker)}
    end
  end

  @doc """
  Handle a process down.
  """
  @spec process_down(State.t, reference) :: any
  def process_down(state, ref) do
    case State.pid_from_ref(state, ref) do
      {:ok, {:worker, worker}} -> handle_worker_down(state, worker)
    end
  end

  defp handle_worker_down(state, worker) do
    state |> State.forget(worker, :worker) |> State.create_worker
  end
end
