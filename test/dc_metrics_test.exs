defmodule DCMetricsTest do
  use ExUnit.Case
  doctest DCMetrics

  test "greets the world" do
    assert DCMetrics.log("message", []) == :ok
  end
end
