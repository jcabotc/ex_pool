defmodule ExPool.State.Config do
  @moduledoc """
  The configuration of the pool.

  This module defines a `ExPool.State.Config` struct that keeps the
  configuration given by the user.

  ## Fields

    * `size` - number of workers of the pool

  """

  @type size :: non_neg_integer

  @type t :: %__MODULE__{
    size: size
  }

  defstruct size: nil

  alias ExPool.State.Config

  @default_size 5

  @doc """
  Creates a new Config from the given keyword configuration.

  ## Configuration options

    * `:size` - (Optional) size of the pool (default #{@default_size})

  """
  @spec new(config :: [Keyword]) :: t
  def new(config) do
    size = Keyword.get(config, :size, @default_size)

    %Config{size: size}
  end
end
