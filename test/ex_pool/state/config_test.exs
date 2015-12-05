defmodule ExPool.State.ConfigTest do
  use ExUnit.Case

  alias ExPool.State.Config

  setup do
    config = Config.new([size: 3])

    {:ok, %{config: config}}
  end

  test "#add, #item_from_ref, #forget", %{config: config} do
    assert config.size == 3
  end
end
