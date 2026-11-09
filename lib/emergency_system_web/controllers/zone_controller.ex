defmodule EmergencySystemWeb.ZoneController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.ZoneManager

  def index(conn, _params) do
    zones = ZoneManager.list_zones()

    zones_html =
      if zones == [] do
        """
        <div class="text-center py-12 bg-white rounded-2xl border border-dashed border-slate-300">
          <p class="text-slate-500 font-medium">No hay zonas afectadas registradas en el sistema.</p>
          <p class="text-xs text-slate-400 mt-1">Utiliza el formulario lateral para dar de alta una nueva zona.</p>
        </div>
        """
      else
        Enum.map_join(zones, "\n", &render_zone_card/1)
      end

    html_content = """
    <div class="space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Gestión de Zonas y Jerarquía Territorial</h1>
          <p class="text-slate-500 text-sm mt-0.5">
            Estructura Jerárquica: <span class="font-semibold text-slate-700">Zona &rarr; Sectores &rarr; Puntos de Atención</span> calculada mediante los 4 algoritmos recursivos.
          </p>
        </div>
      </div>

      <!-- Cuadrícula Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Columna Izquierda: Árbol Jerárquico de Zonas (2 columnas en desktop) -->
        <div class="lg:col-span-2 space-y-4">
          #{zones_html}
        </div>

        <!-- Columna Derecha: Formularios de Registro -->
        <div class="space-y-6">
          <!-- Formulario: Registrar Zona -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>➕</span> Registrar Nueva Zona
            </h3>
            <form action="/zones" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Código de Zona</label>
                <input type="text" name="code" placeholder="Ej: ZONA_CENTRO" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre</label>
                <input type="text" name="name" placeholder="Ej: Centro Histórico" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nivel de Afectación</label>
                <select name="level" class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  <option value="critico">Crítico</option>
                  <option value="alto" selected>Alto</option>
                  <option value="medio">Medio</option>
                  <option value="bajo">Bajo</option>
                </select>
              </div>
              <button type="submit" class="w-full py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Zona
              </button>
            </form>
          </div>

          <!-- Formulario: Añadir Sector a Zona -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>📍</span> Añadir Sector a Zona
            </h3>
            <form action="/zones/sector" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Zona Destino</label>
                <select name="zone_code" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  #{render_zone_options(zones)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre del Sector</label>
                <input type="text" name="sector_name" placeholder="Ej: Manzana 4 / Barrio San José" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Añadir Sector
              </button>
            </form>
          </div>

          <!-- Formulario: Añadir Punto de Atención -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>⛺</span> Añadir Punto de Atención
            </h3>
            <form action="/zones/point" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Zona</label>
                <select name="zone_code" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  #{render_zone_options(zones)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre del Sector</label>
                <input type="text" name="sector_name" placeholder="Nombre exacto del sector existente" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre del Punto</label>
                <input type="text" name="point_name" placeholder="Ej: Polideportivo Central" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Personas Afectadas Estimadas</label>
                <input type="number" name="affected" min="0" placeholder="Ej: 45" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Punto de Atención
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """

    html(conn, Layout.render(conn, "zones", "Gestión de Zonas", html_content))
  end

  def create_zone(conn, %{"code" => code, "name" => name, "level" => level}) do
    user = conn.assigns[:current_user]

    case EmergencySystem.register_zone(user.username, code, name, level) do
      {:ok, _zone} ->
        conn
        |> put_flash(:info, "Zona [#{code}] registrada exitosamente.")
        |> redirect(to: "/zones")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al registrar zona: #{inspect(reason)}")
        |> redirect(to: "/zones")
    end
  end

  def create_sector(conn, %{"zone_code" => zone_code, "sector_name" => sector_name}) do
    user = conn.assigns[:current_user]

    case EmergencySystem.add_sector(user.username, zone_code, sector_name) do
      {:ok, _zone} ->
        conn
        |> put_flash(:info, "Sector '#{sector_name}' añadido a la zona #{zone_code}.")
        |> redirect(to: "/zones")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al añadir sector: #{inspect(reason)}")
        |> redirect(to: "/zones")
    end
  end

  def create_point(conn, %{"zone_code" => zone_code, "sector_name" => sector_name, "point_name" => point_name, "affected" => aff}) do
    user = conn.assigns[:current_user]
    aff_num = String.to_integer(aff)

    case EmergencySystem.add_point_of_attention(user.username, zone_code, sector_name, point_name, aff_num) do
      {:ok, _zone} ->
        conn
        |> put_flash(:info, "Punto '#{point_name}' registrado con #{aff_num} personas afectadas.")
        |> redirect(to: "/zones")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al registrar punto: #{inspect(reason)}")
        |> redirect(to: "/zones")
    end
  end

  # =========================================================================
  # VISTAS AUXILIARES Y RENDERIZADO RECURSIVO
  # =========================================================================

  defp render_zone_card(zone) do
    sectors = Map.values(zone.sectors)

    # 4 Algoritmos Recursivos en acción:
    total_affected = ZoneManager.sum_zone_affected(sectors)
    total_points = ZoneManager.count_total_points(sectors)
    _critical_points = ZoneManager.collect_critical_points(sectors, 50)

    level_badge =
      case zone.level do
        "critico" -> "bg-red-100 text-red-800 border-red-300"
        "alto" -> "bg-amber-100 text-amber-800 border-amber-300"
        "medio" -> "bg-blue-100 text-blue-800 border-blue-300"
        _ -> "bg-slate-100 text-slate-800 border-slate-300"
      end

    sectors_content =
      if sectors == [] do
        """
        <div class="text-xs text-slate-400 italic py-2">
          No hay sectores registrados en esta zona aún.
        </div>
        """
      else
        Enum.map_join(sectors, "\n", &render_sector_item/1)
      end

    """
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 space-y-4">
      <div class="flex items-start justify-between">
        <div>
          <div class="flex items-center gap-2">
            <span class="font-mono font-bold text-sm text-slate-900 bg-slate-100 px-2.5 py-0.5 rounded-lg border border-slate-200">
              #{zone.code}
            </span>
            <h2 class="font-bold text-slate-900 text-base">#{zone.name}</h2>
          </div>
          <p class="text-xs text-slate-400 mt-1">Nivel de afectación territorial</p>
        </div>
        <span class="px-2.5 py-1 rounded-full text-xs font-bold uppercase border #{level_badge}">
          Nivel #{zone.level}
        </span>
      </div>

      <!-- Resumen Recursivo de Estadísticas -->
      <div class="grid grid-cols-3 gap-3 p-3 bg-slate-50 rounded-xl border border-slate-100 text-center">
        <div>
          <div class="text-xs text-slate-400 font-medium">Sectores</div>
          <div class="text-base font-bold text-slate-800">#{length(sectors)}</div>
        </div>
        <div>
          <div class="text-xs text-slate-400 font-medium">Puntos de Atención</div>
          <div class="text-base font-bold text-slate-800">#{total_points}</div>
          <div class="text-[9px] text-slate-400">(count_total_points)</div>
        </div>
        <div>
          <div class="text-xs text-slate-400 font-medium">Total Afectados</div>
          <div class="text-base font-extrabold text-red-600">#{total_affected}</div>
          <div class="text-[9px] text-slate-400">(sum_zone_affected)</div>
        </div>
      </div>

      <!-- Desglose de Sectores -->
      <div class="space-y-2 pt-2 border-t border-slate-100">
        <h4 class="text-xs font-bold text-slate-500 uppercase tracking-wider">Desglose de Sectores y Puntos:</h4>
        <div class="space-y-2">
          #{sectors_content}
        </div>
      </div>
    </div>
    """
  end

  defp render_sector_item(sector) do
    # Recursión 2: sum_points en este sector
    sector_affected = ZoneManager.sum_points(sector.points)

    points_html =
      if sector.points == [] do
        """
        <div class="text-[11px] text-slate-400 italic pl-4 py-1">Sin puntos de atención.</div>
        """
      else
        Enum.map_join(sector.points, "\n", fn p ->
          """
          <div class="flex items-center justify-between text-xs bg-white px-3 py-1.5 rounded-lg border border-slate-200">
            <span class="text-slate-700 font-medium">⛺ #{p.name}</span>
            <span class="font-bold #{if p.affected >= 50, do: "text-red-600 font-extrabold", else: "text-slate-800"}">
              #{p.affected} afectados #{if p.affected >= 50, do: "⚠️", else: ""}
            </span>
          </div>
          """
        end)
      end

    """
    <div class="bg-slate-50/70 p-3 rounded-xl border border-slate-200/80 space-y-2">
      <div class="flex justify-between items-center text-xs">
        <span class="font-bold text-slate-800 flex items-center gap-1.5">
          <span>📁 Sector:</span> #{sector.name}
        </span>
        <span class="text-xs font-semibold text-slate-600">
          Subtotal: <strong class="text-red-700 font-bold">#{sector_affected}</strong> personas
        </span>
      </div>
      <div class="space-y-1 pl-2">
        #{points_html}
      </div>
    </div>
    """
  end

  defp render_zone_options(zones) do
    if zones == [] do
      "<option value=''>Primero cree una zona</option>"
    else
      Enum.map_join(zones, "\n", fn z ->
        "<option value='#{z.code}'>[#{z.code}] #{z.name}</option>"
      end)
    end
  end
end
