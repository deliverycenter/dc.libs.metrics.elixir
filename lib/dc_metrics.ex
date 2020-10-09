defmodule DCMetrics do
  @moduledoc """
  Elixir implementation for DeliveryCenter's structured logging format.

  By default, all events will be logged to:

  - Stdout, as a [Google Cloud Platform structured log](https://cloud.google.com/logging/docs/structured-logging)
  - Metrics API, using gRPC + Protobuf

  ## Levels

  The supported levels are:

    * `:error` - for errors
    * `:warn` - for warnings
    * `:info` - for information of any kind
    * `:debug` - for debug-related messages

  ## Metadata

  All log operations take a argument `metadata`, which should contain all fields to be sent as a metric. The list of
  fields and its descriptions can be found at the Confluence documentation page.

  ### Runtime Configuration

  All configuration below must be set via config files (such as
  `config/config.exs`) and cannot be changed during runtime.

    * `:grpc_url` - URL to the Metrics API gRPC. This may vary between environments. You can find the possible values
      in the centralized docs.

    * `:caller` - name of the application using the lib, in uppercase. Ex.: "WAREHOUSE"

    * `:env` - environment of the application `(:prod, :staging, :sandbox, :dev, or :test)`. Defaults to `Mix.env()`.

    * `:disabled` - true if you want to disable the lib's functionality. Might be useful to disable it in tests, for
      example.

  """
  require Logger

  alias Logging.Deliverycenter.Integration.V1.WriteMetricsRequest
  alias Logging.Deliverycenter.Integration.V1.MetricsService.Stub, as: MetricsStub

  alias DCMetrics.BaseModel

  @grpc_url Application.fetch_env!(:dc_metrics, :grpc_url)
  @caller Application.fetch_env!(:dc_metrics, :caller)
  @env Application.get_env(:dc_metrics, :env, Mix.env())
  @disabled Application.get_env(:dc_metrics, :disabled, Mix.env())
  @log_levels [:error, :warn, :info, :debug]

  @type level :: :error | :warn | :info | :debug
  @type message :: String.t()
  @type metadata :: keyword()

  @doc """
  Logs an event at level DEBUG
  """
  @spec debug(message, metadata) :: :ok
  def debug(message, metadata), do: log(:debug, message, metadata)

  @doc """
  Logs an event at level INFO
  """
  @spec info(message, metadata) :: :ok
  def info(message, metadata), do: log(:info, message, metadata)

  @doc """
  Logs an event at level WARN
  """
  @spec warn(message, metadata) :: :ok
  def warn(message, metadata), do: log(:warn, message, metadata)

  @doc """
  Logs an event at level ERROR
  """
  @spec error(message, metadata) :: :ok
  def error(message, metadata), do: log(:error, message, metadata)

  @doc """
  Logs an event with the given level
  """
  @spec log(level, message, metadata) :: :ok
  def log(level, message, metadata) when level in @log_levels do
    base_model = build_base_model(level, message, metadata)

    log_to_stdout(base_model)
    log_to_metrics(base_model)

    :ok
  end

  defp log_to_stdout(%BaseModel{} = base_model) do
    base_model
    |> build_stdout_payload()
    |> Jason.encode!()
    |> IO.puts()
  end

  defp log_to_metrics(%BaseModel{} = base_model) do
    base_model
    |> build_metrics_payload()
    |> Map.from_struct()
    |> WriteMetricsRequest.new()
    |> make_metrics_request()
  end

  defp build_stdout_payload(%BaseModel{} = base_model) do
    %{
      message: base_model.message,
      severity: base_model.level,
      modelLog: base_model
    }
  end

  defp build_metrics_payload(%BaseModel{} = base_model) do
    %{
      base_model
      | create_timestamp: to_google_timestamp(base_model.create_timestamp)
    }
  end

  defp build_base_model(level, message, metadata) do
    %BaseModel{
      level: level,
      message: message,
      caller: @caller,
      environment: enviroment_map(),
      correlation_id: build_correlation_id(metadata),
      create_timestamp: :os.system_time(:nanosecond),
      action: metadata[:action],
      direction: metadata[:direction],
      source_type: metadata[:source_type],
      source_name: metadata[:source_name],
      duration_ms: metadata[:duration_ms],
      root_resource_type: metadata[:root_resource_type],
      ext_root_resource_id: metadata[:ext_root_resource_id] |> to_string(),
      int_root_resource_id: metadata[:int_root_resource_id] |> to_string(),
      child_resource_type: metadata[:child_resource_type],
      child_resource_id: metadata[:child_resource_id] |> to_string(),
      ext_store_id: metadata[:ext_store_id] |> to_string(),
      int_store_id: metadata[:int_store_id] |> to_string(),
      error_code: metadata[:error_code],
      payload: metadata[:payload]
    }
  end

  defp build_correlation_id(metadata) do
    metadata
    |> Keyword.take([:source_type, :source_name, :ext_root_resource_id, :int_store_id])
    |> Keyword.values()
    |> Enum.join("-")
  end

  defp make_metrics_request(%WriteMetricsRequest{} = request) do
    Task.start(fn ->
      try do
        with {:ok, channel} <- GRPC.Stub.connect(@grpc_url),
             {:ok, response} <- MetricsStub.write_metrics(channel, request) do
          {:ok, response}
        else
          error -> error
        end
      rescue
        _ -> :error
      end
    end)
  end

  defp to_google_timestamp(nanoseconds) do
    %Google.Protobuf.Timestamp{
      seconds: div(nanoseconds, 1_000_000_000),
      nanos: rem(nanoseconds, 1_000_000_000)
    }
  end

  defp enviroment_map do
    case @env do
      :prod -> "PRODUCTION"
      :staging -> "STAGING"
      :sandbox -> "SANDBOX"
      :dev -> "DEVELOPMENT"
      :test -> "TEST"
    end
  end
end
