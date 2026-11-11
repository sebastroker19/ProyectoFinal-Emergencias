defmodule EmergencySystemWeb.Plugs.AuthUser do
  @moduledoc """
  Gestiona la sesión del usuario en la interfaz web.
  Si no hay usuario en sesión, asigna un perfil humano predeterminado para demostración.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user = get_session(conn, :current_user)

    if user do
      assign(conn, :current_user, user)
    else
      # Usuario humano por defecto (Coordinadora Dra. Laura Morales)
      default_user = %{
        username: "laura.morales",
        full_name: "Dra. Laura Morales",
        role: "coordinador",
        zone: "Zona 1 - Centro Histórico"
      }

      EmergencySystem.connect(
        "laura.morales",
        "1234",
        "coordinador",
        "Zona 1 - Centro Histórico",
        "Dra. Laura Morales"
      )

      conn
      |> put_session(:current_user, default_user)
      |> assign(:current_user, default_user)
    end
  end
end
