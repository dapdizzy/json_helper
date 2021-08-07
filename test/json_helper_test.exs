defmodule JsonHelperTest do
  use ExUnit.Case
  doctest JsonHelper

  test "greets the world" do
    assert JsonHelper.hello() == :world
  end
end
