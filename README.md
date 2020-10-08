# dc.libs.metrics.golang

Elixir implementation for DeliveryCenter's structured logging format.

The details of the logging strategy and fields descriptions that are applied to all packages of this family 
can be found in the [Confluence page](https://deliverycenterbr.atlassian.net/wiki/spaces/SP/pages/755630096/Observabilidade+do+ecossistema+DC)
(private). Docs of this package will focus on the details of the *Elixir* implementation.   

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
DCTracing.log("Product created with success",
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