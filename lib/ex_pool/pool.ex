defmodule ExPool.Pool do
  use GenServer

  def start_link(opts \\ []) do
    name_opts = Keyword.take(opts, [:name])

    GenServer.start_link(__MODULE__, opts, name_opts)
  end

  def check_out(pool) do
    GenServer.call(pool, :check_out)
  end

  def check_in(pool, worker) do
    GenServer.cast(pool, {:check_in, worker})
  end

  def init(config) do
    state = Manager.new(config)

    {:ok, state}
  end

  def handle_call(:check_out, _from, state) do
    case Manager.check_out(state) do
      {:ok, {worker, new_state}} -> {:reply, worker, new_state}
      {:waiting, new_state}      -> {:noreply, new_state}
    end
  end

  def handle_cast({:check_in, worker}, _from, state) do
    case Manager.check_in(state, worker) do
      {:ok, state}                -> nil
      {:check_out, {from, state}} -> GenServer.reply(from, worker)
    end

    {:noreply, state}
  end
end
