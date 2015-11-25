defmodule ExPool.Pool do
  use GenServer

  def start_link(opts \\ []) do
    name_opts = Keyword.take(opts, [:name])

    GenServer.start_link(__MODULE__, opts, name_opts)
  end

  def run(pool, func) do
    GenServer.call(pool, {:run, func})
  end

  def init(config) do
    {:ok, :ok}
  end

  def handle_call({:run, func}, _from, _state) do
    {:reply, :ok, :ok}
  end
end
