# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env() == :test do
  config :dc_metrics,
    caller: "APPLICATION_NAME",
    env: Mix.env(),
    gcp_project_id: "local_project_id",
    pubsub_topic_name: "topic_name"

  config :goth, disabled: true
  config :google_api_pub_sub, :base_url, "http://localhost:8681/"
end
