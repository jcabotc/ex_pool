defmodule ExPool.State do
  @moduledoc """
  The internal state of a pool.

  It is a struct with the following fields:

    * `:worker_mod` - The worker module.
    * `:workers` - List of available worker processes.
    * `:size` - Size of the pool.
    * `:sup` - Pool supervisor.
    * `:monitors` - Store for the monitored references.
    * `:waiting` - Queue to store the waiting requests.

  """

  @type t :: %__MODULE__{
    worker_mod: atom,
    workers: [pid],
    sup: pid,
    size: non_neg_integer,
    monitors: :ets.tid,
    waiting: any
  }
  defstruct [:worker_mod, :size,
             :sup, :workers, :monitors, :waiting]

  @default_size 5

  @doc """
  Creates a new pool state with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) The worker module. It has to fit in a
    supervision tree (like a GenServer).

    * `:size` - (Optional) The size of the pool (default #{@default_size}).

  """
  @spec new(config :: [Keyword]) :: State.t
  def new(config) do
    worker_mod = Keyword.fetch!(config, :worker_mod)
    size       = Keyword.get(config, :size, @default_size)

    %__MODULE__{worker_mod: worker_mod, size: size}
  end

  @doc """
  Returns the size of the pool.
  """
  @spec size(State.t) :: non_neg_integer
  def size(%{size: size}) do
    size
  end
end
