defmodule EmergencySystemWebTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias EmergencySystemWeb.Endpoint

  @opts Endpoint.init([])

  test "GET /login carga la pantalla de autenticación y perfiles de demostración" do
    conn =
      :get
      |> conn("/login")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Portal de Coordinación de Emergencias"
    assert conn.resp_body =~ "Dra. Laura Morales"
    assert conn.resp_body =~ "Ing. Sofía Mendoza"
  end

  test "POST /session/quick-login permite ingresar con perfil demo en 1 clic" do
    post_conn =
      :post
      |> conn("/session/quick-login", %{"profile" => "laura"})
      |> Endpoint.call(@opts)

    assert post_conn.status == 302
  end

  test "GET / carga el panel de mando con status 200" do
    conn =
      :get
      |> conn("/")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Centro de Mando"
    assert conn.resp_body =~ "Personas Afectadas"
  end

  test "GET /zones y creación de zonas y sectores" do
    conn =
      :get
      |> conn("/zones")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Gestión de Zonas y Jerarquía Territorial"

    # Crear una zona vía POST
    post_conn =
      :post
      |> conn("/zones", %{"code" => "Z_WEB", "name" => "Zona Web", "level" => "alto"})
      |> Endpoint.call(@opts)

    assert post_conn.status == 302
  end

  test "GET /resources y registro de inventario" do
    conn =
      :get
      |> conn("/resources")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Gestión de Suministros e Inventario Logístico"

    post_conn =
      :post
      |> conn("/resources", %{"code" => "R_WEB", "name" => "Raciones", "quantity" => "100", "unit" => "paquetes", "location" => "almacen_web"})
      |> Endpoint.call(@opts)

    assert post_conn.status == 302
  end

  test "GET /needs y registro de necesidad" do
    conn =
      :get
      |> conn("/needs")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Gestión de Necesidades"
  end

  test "GET /shelters y control de aforo" do
    conn =
      :get
      |> conn("/shelters")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Gestión de Albergues y Control de Aforo"
  end

  test "GET /people y búsqueda" do
    conn =
      :get
      |> conn("/people")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Comunicación entre Familiares y Localización"
  end

  test "GET /pets y módulo de coincidencias" do
    conn =
      :get
      |> conn("/pets")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Gestión de Mascotas Perdidas y Encontradas"
  end

  test "GET /concurrency y simulación interactiva" do
    conn =
      :get
      |> conn("/concurrency")
      |> Endpoint.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Laboratorio de Concurrencia"

    # Ejecutar simulación concurrente
    sim_conn =
      :post
      |> conn("/concurrency/simulate", %{})
      |> Endpoint.call(@opts)

    assert sim_conn.status == 200
    assert sim_conn.resp_body =~ "RESULTADO DE LA EJECUCIÓN CONCURRENTE"
    assert sim_conn.resp_body =~ "No hubo condición de carrera"
  end
end