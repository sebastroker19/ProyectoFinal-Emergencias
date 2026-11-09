defmodule EmergencySystemWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :emergency_system

  @session_options [
    store: :cookie,
    key: "_emergency_system_key",
    signing_salt: "7qH8jK2x9Y0v"
  ]

  plug Plug.Static,
    at: "/",
    from: :emergency_system,
    gzip: false

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug EmergencySystemWeb.Router
end
