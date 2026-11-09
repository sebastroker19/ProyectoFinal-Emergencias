import Config

config :emergency_system,
  namespace: EmergencySystem

config :emergency_system, EmergencySystemWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: EmergencySystemWeb.ErrorHTML, json: EmergencySystemWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EmergencySystem.PubSub,
  secret_key_base: "m7p7z8Y9Y8wK5+w4A2qV5tY8wK5+w4A2qV5tY8wK5+w4A2qV5tY8wK5+w4A2qV5t",
  live_view: [signing_salt: "n9K2x4Y8"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
