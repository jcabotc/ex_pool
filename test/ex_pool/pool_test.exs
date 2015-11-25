defmodule ExPool.PoolTest do
  use ExUnit.Case

  alias ExPool.Pool

  setup do
    {:ok, pool} = Pool.start_link

    {:ok, %{pool: pool}}
  end
end
