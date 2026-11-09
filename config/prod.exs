import Config

config :emergency_system, EmergencySystemWeb.Endpoint,
  http: [port: 4000],
  server: true

config :logger, level: :info
