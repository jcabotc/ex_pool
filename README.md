# ExPool

A generic pooling library for Elixir.

[Documentation for ExPool is available online](http://hexdocs.pm/plug/).

## Installation

Add ex_pool to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ex_pool, "~> 0.0.1"}]
end
```

## Usage

ExPool uses a set of initialized processes kept ready to use rather than spawning and destroying them on demand.

When a function is run on the pool ExPool requests a process from the pool, runs the function with the pid as argument and returns the process to the pool.

If there are no processes available it blocks until a process is returned to the pool, and then runs the function.

### The worker

The worker is a module that fits into a supervision tree (for example, a GenServer).

It is the process the pool will initialize and keep ready to use.

The following snippet shows an example of a worker that uses `:timer.sleep\1` to simulate a long-lasting operation (like a CPU intensive task, an external http request or a database query).

```elixir
defmodule HardWorker do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def do_work(pid, milliseconds \\ 2000) do
    GenServer.call(pid, milliseconds)
  end

  def handle_call(milliseconds, _from, state) do
    :timer.sleep(milliseconds)
    IO.puts "Work done!"

    {:reply, :ok, state}
  end
end
```

### The pool

You can start a pool with `ExPool.start_link/1`.

In the following example we create a pool and run a function on it.

```elixir
{:ok, pool} = ExPool.start_link(worker_mod: HardWorker)

ExPool.run pool, fn (worker) ->
  HardWorker.do_work(worker, 1000)
end

# It will print:
#   Work done!
```

We have created a pool that spawns a set of workers (5 by default) and we have run a function on the pool.

If we run concurrently more functions on the pool than workers available the functions that overflow the number of workers will block until there is a worker available.

```elixir
{:ok, pool} = ExPool.start_link(worker_mod: HardWorker, size: 2)

for _i <- 1..5 do
  ExPool.run pool, &HardWorker.do_work(&1)
end

# It will print:
#   Work done!
#   Work done!
#   Work done!
#   Work done!
#   Work done!
```
