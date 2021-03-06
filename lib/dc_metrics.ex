defmodule DCMetrics do
  require Logger

  alias Logging.Deliverycenter.Integration.V1.WriteMetricsRequest

  alias DCMetrics.BaseModel

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
    unless disabled?() do
      base_model = build_base_model(level, message, metadata)

      log_to_stdout(base_model)
      log_to_metrics(base_model)
    end

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
      level: level |> to_string() |> String.upcase(),
      message: message,
      caller: caller(),
      environment: environment(),
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
    [
      metadata[:source_type],
      metadata[:source_name],
      metadata[:ext_root_resource_id],
      metadata[:int_root_resource_id]
    ]
    |> Enum.join("-")
  end

  defp make_metrics_request(%WriteMetricsRequest{} = request) do
    Task.start(fn ->
      try do
        message_data = prepare_pubsub_message(request)

        request = %GoogleApi.PubSub.V1.Model.PublishRequest{
          messages: [
            %GoogleApi.PubSub.V1.Model.PubsubMessage{
              data: message_data
            }
          ]
        }

        {:ok, _response} =
          GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_topics_publish(
            pubsub_client(),
            pubsub_project_id(),
            pubsub_topic_name(),
            body: request
          )
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

  defp environment() do
    case Application.fetch_env!(:dc_metrics, :env) do
      :prod -> "PRODUCTION"
      :staging -> "STAGING"
      :sandbox -> "SANDBOX"
      :dev -> "DEVELOPMENT"
      :test -> "TEST"
    end
  end

  defp caller() do
    Application.fetch_env!(:dc_metrics, :caller)
  end

  defp prepare_pubsub_message(%WriteMetricsRequest{} = request) do
    request
    |> WriteMetricsRequest.encode()
    |> Base.encode64()
  end

  defp pubsub_client do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/pubsub")
    GoogleApi.PubSub.V1.Connection.new(token.token)
  end

  defp pubsub_project_id do
    Application.fetch_env!(:dc_metrics, :gcp_project_id)
  end

  defp pubsub_topic_name do
    Application.fetch_env!(:dc_metrics, :pubsub_topic_name)
  end

  def disabled? do
    Application.get_env(:dc_metrics, :disabled, false)
  end
end
