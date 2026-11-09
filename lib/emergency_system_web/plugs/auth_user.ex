defmodule EmergencySystemWeb.Plugs.AuthUser do
  @moduledoc """
  Gestiona la sesión del usuario en la interfaz web.
  Si no hay usuario en sesión, inicializa una sesión de demostración por defecto.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user = get_session(conn, :current_user)

    if user do
      assign(conn, :current_user, user)
    else
      # Usuario de demostración por defecto (Coordinador)
      default_user = %{
        username: "coordinador_general",
        role: "coordinador",
        zone: "centro"
      }

      # Asegurar que esté conectado en el sistema
      EmergencySystem.connect("coordinador_general", "1234", "coordinador", "centro", "Coordinador General")

      conn
      |> put_session(:current_user, default_user)
      |> assign(:current_user, default_user)
    end
  end
end
