# DCMetrics Elixir

Elixir implementation for DeliveryCenter's structured logging format.

> This package is part of a family of libraries that implement DeliveryCenter's metrics pattern  for different languages. 
Check also our [Golang](https://github.com/deliverycenter/dc.libs.metrics.golang), 
>[Node](https://github.com/deliverycenter/dc.libs.metrics.node) and 
>[Ruby](https://github.com/deliverycenter/dc.libs.metrics.ruby) versions.

By default, all events will be logged to:

- Stdout, as a [Google Cloud Platform structured log](https://cloud.google.com/logging/docs/structured-logging)
- Metrics API, using PubSub

For the complete documentation, refer to the documentation page.

## Installation

This package can be installed by adding `dc_metrics` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dc_metrics, "~> 0.1.0"}
  ]
end
```

## Usage

First, set the required configs in your config file

```elixir
config :dc_metrics,
  caller: "APPLICATION_NAME",
  env: Mix.env(),
  gcp_project_id: "project_id",
  pubsub_topic_name: "topic_name"
```

Then, to log an event

```elixir
DCMetrics.info("Product created with success",
  action: "CREATE_PRODUCT",
  direction: "INCOMING",
  source_type: "PROVIDER",
  source_name: "MY_PROVIDER",
  root_resource_type: "PRODUCT",
  ext_root_resource_id: "EXT1234",
  int_root_resource_id: "6789",
  int_store_id: 100
)
```

## Options

### Levels

The supported levels are:

* `:error` - for errors
* `:warn` - for warnings
* `:info` - for information of any kind
* `:debug` - for debug-related messages

### Metadata

All log operations take a argument `metadata`, which should contain all fields to be sent as a metric. The list of
fields and its descriptions can be found at the Confluence documentation page.

### Config options

* `:project_id` - GCP's Project ID for the given environment.

* `:pubsub_topic_name` - Name of the topic where the messages will be sent to.

* `:caller` - name of the application using the lib, in uppercase. Ex.: "WAREHOUSE"

* `:env` - environment of the application `(:prod, :staging, :sandbox, :dev, or :test)`. Usually you'll want to set 
this as `Mix.env()`.

