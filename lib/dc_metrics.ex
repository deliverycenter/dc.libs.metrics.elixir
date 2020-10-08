defmodule DcMetrics do
  require Logger

  alias Logging.Deliverycenter.Integration.V1.WriteMetricsRequest
  alias Logging.Deliverycenter.Integration.V1.MetricsService.Stub, as: MetricsStub

  @grpc_url Application.fetch_env!(:dc_metrics, :grpc_url)
  @caller Application.fetch_env!(:dc_metrics, :caller)
  @env Application.fetch_env!(:dc_metrics, :env)

  @doc """
  Logs an event as a GCP formatted stdout and send it to the Metrics API
  """
  def log(message, metadata) when @env != :test do
    base_model = build_base_model(message, metadata)

    log_to_stdout(base_model)
    log_to_metrics(base_model)

    :ok
  end

  def log(_, _), do: :ok

  defp log_to_stdout(%{} = base_model) do
    base_model
    |> build_stdout_payload()
    |> Poison.encode!()
    |> IO.puts()
  end

  defp log_to_metrics(%{} = base_model) do
    base_model
    |> build_metrics_payload()
    |> WriteMetricsRequest.new()
    |> make_metrics_request()
  end

  defp build_stdout_payload(%{} = base_model) do
    %{
      message: base_model[:message],
      severity: base_model[:level],
      modelLog: base_model
    }
  end

  defp build_metrics_payload(%{} = base_model) do
    %{
      base_model
    | create_timestamp: to_google_timestamp(base_model[:create_timestamp])
    }
  end

  defp build_base_model(message, metadata) do
    %{
      message: message,
      caller: @caller,
      environment: enviroment_map(),
      correlation_id: build_correlation_id(metadata),
      create_timestamp: :os.system_time(:nanosecond),
      action: metadata[:action],
      level: metadata[:level] || "INFO",
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
    end
  end
end
