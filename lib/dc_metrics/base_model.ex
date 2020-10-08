defmodule DCMetrics.BaseModel do
  defstruct [
    :message,
    :caller,
    :environment,
    :correlation_id,
    :create_timestamp,
    :action,
    :level,
    :direction,
    :source_type,
    :source_name,
    :duration_ms,
    :root_resource_type,
    :ext_root_resource_id,
    :int_root_resource_id,
    :child_resource_type,
    :child_resource_id,
    :ext_store_id,
    :int_store_id,
    :error_code,
    :payload
  ]
end
