defmodule DCMetricsTest do
  use ExUnit.Case
  doctest DCMetrics

  import ExUnit.CaptureIO

  setup do
    metadata = [
      action: "action_test",
      direction: "direction_test",
      source_type: "source_type_test",
      source_name: "source_name_test",
      root_resource_type: "root_resource_type_test",
      ext_root_resource_id: "ext_root_resource_id_test",
      int_root_resource_id: "int_root_resource_id_test",
      child_resource_type: "child_resource_type_test",
      child_resource_id: "child_resource_id_test",
      int_store_id: "int_store_id_test",
      ext_store_id: "ext_store_id_test",
      payload: "payload_test",
      error_code: "error_code_test",
      duration_ms: 500,
    ]

    {:ok, metadata: metadata}
  end

  describe "log/3" do
    test "logs structured data to stdout", context do
      output = capture_io(fn -> DCMetrics.log(:info, "message_test", context[:metadata]) end)

      parsed_output =
        output
        |> String.trim()
        |> Jason.decode!()

      expected = %{
        "message" => "message_test",
        "severity" => "INFO",
        "modelLog" => %{
          "level" => "INFO",
          "message" => "message_test",
          "caller" => "APPLICATION_NAME",
          "environment" => "TEST",
          "correlation_id" => "source_type_test-source_name_test-ext_root_resource_id_test-int_root_resource_id_test",
          "action" => "action_test",
          "direction" => "direction_test",
          "source_type" => "source_type_test",
          "source_name" => "source_name_test",
          "root_resource_type" => "root_resource_type_test",
          "ext_root_resource_id" => "ext_root_resource_id_test",
          "int_root_resource_id" => "int_root_resource_id_test",
          "child_resource_type" => "child_resource_type_test",
          "child_resource_id" => "child_resource_id_test",
          "int_store_id" => "int_store_id_test",
          "ext_store_id" => "ext_store_id_test",
          "payload" => "payload_test",
          "error_code" => "error_code_test",
          "duration_ms" => 500
        }
      }

      assert expected == parsed_output |> pop_in(["modelLog", "create_timestamp"]) |> elem(1)
    end
  end

  describe "debug/2" do
    test "logs an event with level DEBUG", context do
      output = capture_io(fn -> DCMetrics.debug("message_test", context[:metadata]) end)

      parsed_output =
        output
        |> String.trim()
        |> Jason.decode!()

      assert parsed_output["severity"] == "DEBUG"
      assert parsed_output["modelLog"]["level"] == "DEBUG"
    end
  end

  describe "info/2" do
    test "logs an event with level INFO", context do
      output = capture_io(fn -> DCMetrics.info("message_test", context[:metadata]) end)

      parsed_output =
        output
        |> String.trim()
        |> Jason.decode!()

      assert parsed_output["severity"] == "INFO"
      assert parsed_output["modelLog"]["level"] == "INFO"
    end
  end

  describe "warn/2" do
    test "logs an event with level WARN", context do
      output = capture_io(fn -> DCMetrics.warn("message_test", context[:metadata]) end)

      parsed_output =
        output
        |> String.trim()
        |> Jason.decode!()

      assert parsed_output["severity"] == "WARN"
      assert parsed_output["modelLog"]["level"] == "WARN"
    end
  end

  describe "error/2" do
    test "logs an event with level ERROR", context do
      output = capture_io(fn -> DCMetrics.error("message_test", context[:metadata]) end)

      parsed_output =
        output
        |> String.trim()
        |> Jason.decode!()

      assert parsed_output["severity"] == "ERROR"
      assert parsed_output["modelLog"]["level"] == "ERROR"
    end
  end
end
