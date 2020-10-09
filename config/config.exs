# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env() == :test do
  config :dc_metrics,
    grpc_url: "FAKE_ADDR",
    caller: "APPLICATION_NAME",
    env: Mix.env()
end
