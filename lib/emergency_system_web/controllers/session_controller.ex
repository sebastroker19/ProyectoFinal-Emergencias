defmodule EmergencySystemWeb.SessionController do
  use EmergencySystemWeb, :controller

  def switch(conn, %{"role" => role}) do
    username = "#{role}_web"
    EmergencySystem.connect(username, "1234", role, "centro", "Usuario #{String.capitalize(role)}")

    user = %{
      username: username,
      role: role,
      zone: "centro"
    }

    conn
    |> put_session(:current_user, user)
    |> put_flash(:info, "Has cambiado de rol a: #{String.upcase(role)}")
    |> redirect(to: get_referer_or_root(conn))
  end

  defp get_referer_or_root(conn) do
    case Plug.Conn.get_req_header(conn, "referer") do
      [referer | _] ->
        uri = URI.parse(referer)
        uri.path || "/"
      _ ->
        "/"
    end
  end
end
