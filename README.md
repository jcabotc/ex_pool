# ExPool

A generic pooling library for Elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ex_pool to your list of dependencies in `mix.exs`:

        def deps do
          [{:ex_pool, "~> 0.0.1"}]
        end

  2. Ensure ex_pool is started before your application:

        def application do
          [applications: [:ex_pool]]
        end

## Usage

```elixir
defmodule HardWorker do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def do_work(pid, seconds \\ 2) do
    GenServer.call(pid, seconds)
  end

  def handle_call(seconds, _from, state) do
    :timer.sleep(seconds)
    {:reply, :ok, state}
  end
end

{:ok, pool} = ExPool.start_link(worker_mod: HardWorker)

ExPool.run(pool, &HardWorker.do_work(&1))

ExPool.run pool, fn (worker) ->
  HardWorker.do_work(worker, 1)
  HardWorker.do_work(worker, 1)
end
```
