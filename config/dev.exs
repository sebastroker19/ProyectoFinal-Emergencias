import Config

config :emergency_system, EmergencySystemWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  server: true,
  check_origin: false,
  debug_errors: true,
  code_reloader: false

config :logger, :console, format: "[$level] $message\n"
