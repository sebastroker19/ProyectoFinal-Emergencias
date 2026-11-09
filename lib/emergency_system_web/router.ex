defmodule EmergencySystemWeb.Router do
  use EmergencySystemWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
    plug EmergencySystemWeb.Plugs.AuthUser
  end

  scope "/", EmergencySystemWeb do
    pipe_through :browser

    # Dashboard Principal
    get "/", DashboardController, :index

    # Gestión de Sesión y Roles
    post "/session/switch", SessionController, :switch

    # Zonas y Jerarquía Territorial Recursiva
    get "/zones", ZoneController, :index
    post "/zones", ZoneController, :create_zone
    post "/zones/sector", ZoneController, :create_sector
    post "/zones/point", ZoneController, :create_point

    # Inventario y Recursos
    get "/resources", ResourceController, :index
    post "/resources", ResourceController, :create
    post "/resources/transfer", ResourceController, :transfer

    # Necesidades Puntuales y Asignación
    get "/needs", NeedController, :index
    post "/needs", NeedController, :create
    post "/needs/assign", NeedController, :assign

    # Albergues y Control de Capacidad
    get "/shelters", ShelterController, :index
    post "/shelters", ShelterController, :create
    post "/shelters/entry", ShelterController, :entry
    post "/shelters/exit", ShelterController, :exit

    # Localización y Mensajes Familiares
    get "/people", PersonController, :index
    post "/people", PersonController, :report
    post "/people/status", PersonController, :update_status
    post "/people/messages", PersonController, :send_message
    post "/people/messages/:id/deliver", PersonController, :mark_delivered

    # Mascotas Perdidas y Encontradas
    get "/pets", PetController, :index
    post "/pets", PetController, :report
    post "/pets/match/confirm", PetController, :confirm_match

    # Laboratorio de Concurrencia
    get "/concurrency", ConcurrencyController, :index
    post "/concurrency/simulate", ConcurrencyController, :simulate
  end
end
