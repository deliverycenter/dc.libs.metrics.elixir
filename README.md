# dc.libs.metrics.golang

Elixir implementation for DeliveryCenter's structured logging format.

> This package is part of a family of libraries that implement DeliveryCenter's metrics pattern  for different languages. 
Check also our [Golang](https://github.com/deliverycenter/dc.libs.metrics.golang), 
>[Node](https://github.com/deliverycenter/dc.libs.metrics.node) and 
>[Ruby](https://github.com/deliverycenter/dc.libs.metrics.ruby) versions.

Full documentation can be found at TBD.

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
  grpc_url: "ADDR:PORT",
  caller: "APPLICATION_NAME",
  env: Mix.env()
```

Then, to log an event

```elixir
DCTracing.info("Product created with success",
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

Full documentation can be found at TBD.