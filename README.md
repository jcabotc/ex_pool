# ExPool

A generic pooling library for Elixir.

[Documentation for ExPool is available online](http://hexdocs.pm/ex_pool/).

## Installation

Add ExPool to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ex_pool, "~> 0.0.3"}]
end
```

## Usage

ExPool uses a set of initialized processes kept ready to use rather than spawning and destroying them on demand.

When you run a function on the pool:

 1. It requests a process from the pool.
 2. Runs the function with the pid as only argument.
 3. Returns the process to the pool.

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

Is recommended to always use blocking calls when using a worker (i.e. `GenServer.call/2` instead of `GenServer.cast/2`).

If a non-blocking call is used ExPool will return the process to the pool and make it available for other requests even though it may be performing work.

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
  spawn_link fn ->
    ExPool.run pool, &HardWorker.do_work(&1)
  end
end

# It will print:
#   Work done!
#   Work done!
#   Work done!
#   Work done!
#   Work done!
```

### Using a pool on a supervision tree

To start a pool that will be supervised by your application add to your application supervisor (or any other supervisor of your choice) the following child.

```elixir
defmodule MyApplication do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ExPool, [[worker_mod: HardWorker, size: 10, name: :my_pool]])

      # ... more children
    ]

    opts = [strategy: :one_for_one, name: Transactions.Endpoint.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

The pool will be started with your application and can be used as follows.

```elixir
ExPool.run :my_pool, fn (worker) ->
  HardWorker.do_work(worker)
end
```

## Examples

### A pool of redis connections

The following example will show how to use ExPool to keep a pool of redis connections on your application. We will use ExRedis to establish a redis connection and run commands.

First we add ExPool and ExRedis as dependencies of the application in our `mix.exs`.

```elixir
  defp deps do
    [{:ex_pool, "~> 0.0.3"},
     {:exredis, ">= 0.2.2"}]
  end
```

Run `mix deps.get` to get the dependencies from Hex.

Add to our `config/config.exs` some configuration about the pool and the redis server.

```elixir
config :redis_pool,
  worker_mod: ExRedis,
  size: 10,
  name: :redis

config :ex_redis,
  host: "127.0.0.1",
  port: 6379,
  password: "",
  db: 0
```

As ExRedis fits into a supervision tree there is no need to explicitly define a worker.

We have configured a pool with 10 redis connections named `:redis`. To start the pool when the application starts add it as a child of your application supervisor.

```elixir
defmodule MyApplication do
  use Application

  @redis_pool_config Application.get_env(:redis_pool)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ExPool, [@redis_pool_config])
    ]

    opts = [strategy: :one_for_one, name: Transactions.Endpoint.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Now you can run commands on redis from your application.

```elixir
ExPool.run :redis, fn (client) ->
  client |> Exredis.query ["SET", "foo", "bar"]
end

ExPool.run :redis, fn (client) ->
  client |> Exredis.query ["GET", "foo"]
end
# => "bar"
```
