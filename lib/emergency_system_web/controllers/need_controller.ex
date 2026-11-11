defmodule EmergencySystemWeb.NeedController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.NeedManager
  alias EmergencySystem.ResourceManager
  alias EmergencySystem.ZoneManager

  def index(conn, params) do
    user = conn.assigns[:current_user]
    filters = Map.take(params, ["status", "priority", "zone"]) |> Enum.reject(fn {_, v} -> v == "" end) |> Map.new()
    needs = NeedManager.list_needs(filters)
    resources = ResourceManager.list_resources()
    zones = ZoneManager.list_zones()

    needs_rows =
      if needs == [] do
        """
        <tr>
          <td colspan="7" class="text-center py-10 text-slate-400 text-xs">
            No hay solicitudes de auxilio registradas con estos criterios de búsqueda.
          </td>
        </tr>
        """
      else
        Enum.map_join(needs, "\n", fn n -> render_need_row(n, resources) end)
      end

    html_content = """
    <div class="space-y-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Gestión de Necesidades y Triaje Humanitario</h1>
          <p class="text-slate-500 text-sm mt-0.5">
            Solicitudes de auxilio ordenadas por criticidad, con asignación directa de stock y protección contra doble consumo.
          </p>
        </div>
      </div>

      <!-- Cuadrícula Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Tabla de Necesidades (2 columnas) -->
        <div class="lg:col-span-2 space-y-4">
          <!-- Filtros Rápidos -->
          <form action="/needs" method="get" class="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm flex flex-wrap gap-3 items-center text-xs">
            <span class="font-bold text-slate-500">Filtrar por:</span>
            <select name="priority" onchange="this.form.submit()" class="border rounded-xl px-3 py-1.5 bg-white outline-none">
              <option value="">Todas las Prioridades</option>
              <option value="critica" #{if params["priority"] == "critica", do: "selected", else: ""}>Crítica (Urgente)</option>
              <option value="alta" #{if params["priority"] == "alta", do: "selected", else: ""}>Alta</option>
              <option value="media" #{if params["priority"] == "media", do: "selected", else: ""}>Media</option>
              <option value="baja" #{if params["priority"] == "baja", do: "selected", else: ""}>Baja</option>
            </select>
            <select name="status" onchange="this.form.submit()" class="border rounded-xl px-3 py-1.5 bg-white outline-none">
              <option value="">Todos los Estados</option>
              <option value="pendiente" #{if params["status"] == "pendiente", do: "selected", else: ""}>Pendiente</option>
              <option value="en_atencion" #{if params["status"] == "en_atencion", do: "selected", else: ""}>En Atención</option>
              <option value="atendida" #{if params["status"] == "atendida", do: "selected", else: ""}>Atendida</option>
            </select>
            <a href="/needs" class="text-slate-400 hover:text-slate-600 font-medium ml-auto">Limpiar filtros</a>
          </form>

          <div class="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
              <table class="w-full text-left text-xs">
                <thead class="bg-slate-50 text-[11px] font-bold text-slate-400 uppercase border-b border-slate-100">
                  <tr>
                    <th class="py-3.5 px-4">ID / Urgencia</th>
                    <th class="py-3.5 px-4">Requerimiento / Solicitante</th>
                    <th class="py-3.5 px-4">Cantidad</th>
                    <th class="py-3.5 px-4">Zona</th>
                    <th class="py-3.5 px-4">Estado</th>
                    <th class="py-3.5 px-4">Asignar Suministro</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                  #{needs_rows}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Formulario: Registrar Nueva Necesidad -->
        <div class="space-y-6">
          <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
            <div class="border-b pb-2">
              <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2">
                <span>➕</span> Registrar Solicitud de Auxilio
              </h3>
              <p class="text-xs text-slate-400">Publicando como: <strong class="text-slate-700">#{user[:full_name]}</strong></p>
            </div>

            <form action="/needs" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Categoría del Auxilio</label>
                <select name="type" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  <option value="agua">Agua potable y líquidos</option>
                  <option value="medicamentos">Medicamentos y primeros auxilios</option>
                  <option value="alimentos">Alimentos y víveres no perecederos</option>
                  <option value="refugio">Carpas, mantas y abrigo</option>
                  <option value="transporte">Evacuación y transporte</option>
                  <option value="rescate">Búsqueda y rescate especializado</option>
                  <option value="otra">Otra necesidad puntual</option>
                </select>
              </div>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block text-xs font-bold text-slate-700 mb-1">Cantidad Requerida</label>
                  <input type="number" name="quantity" min="1" placeholder="Ej: 50" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
                </div>
                <div>
                  <label class="block text-xs font-bold text-slate-700 mb-1">Prioridad</label>
                  <select name="priority" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none bg-white">
                    <option value="critica">Crítica (Riesgo vital)</option>
                    <option value="alta" selected>Alta</option>
                    <option value="media">Media</option>
                    <option value="baja">Baja</option>
                  </select>
                </div>
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Zona Afectada</label>
                <select name="zone" class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  #{render_zone_options(zones)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Detalle y Justificación de la Emergencia</label>
                <textarea name="description" rows="3" placeholder="Indicar número de personas, familias aisladas, síntomas o urgencia inmediata..." required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none"></textarea>
              </div>
              <button type="submit" class="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl transition shadow-sm">
                Emitir Solicitud de Auxilio
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """

    html(conn, Layout.render(conn, "needs", "Gestión de Necesidades", html_content))
  end

  def create(conn, %{"type" => type, "quantity" => qty, "priority" => prio, "zone" => zone, "description" => desc}) do
    user = conn.assigns[:current_user]
    qty_num = String.to_integer(qty)

    case EmergencySystem.register_need(user.username, type, qty_num, prio, zone, desc) do
      {:ok, need} ->
        conn
        |> put_flash(:info, "Solicitud de auxilio [#{need.id}] registrada exitosamente con prioridad #{String.upcase(prio)}.")
        |> redirect(to: "/needs")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al registrar necesidad: #{inspect(reason)}")
        |> redirect(to: "/needs")
    end
  end

  def assign(conn, %{"need_id" => need_id, "resource_code" => res_code, "quantity" => qty}) do
    user = conn.assigns[:current_user]
    qty_num = String.to_integer(qty)

    case EmergencySystem.assign_resource(user.username, need_id, res_code, qty_num) do
      {:ok, need} ->
        conn
        |> put_flash(:info, "Asignadas #{qty_num} unidades de #{res_code} a necesidad #{need.id}. Nuevo estado: #{String.upcase(need.status)}.")
        |> redirect(to: "/needs")

      {:error, reason} ->
        conn
        |> put_flash(:error, "No se pudo asignar el recurso: #{inspect(reason)}")
        |> redirect(to: "/needs")
    end
  end

  defp render_need_row(need, resources) do
    prio_badge =
      case need.priority do
        "critica" -> "bg-red-100 text-red-800 border-red-300 font-extrabold"
        "alta" -> "bg-amber-100 text-amber-800 border-amber-300 font-bold"
        "media" -> "bg-blue-100 text-blue-800 border-blue-300 font-medium"
        _ -> "bg-slate-100 text-slate-800 border-slate-300 font-medium"
      end

    status_badge =
      case need.status do
        "atendida" -> "bg-emerald-100 text-emerald-800"
        "en_atencion" -> "bg-blue-100 text-blue-800"
        _ -> "bg-amber-100 text-amber-800"
      end

    assign_form =
      if need.status in ["atendida", "cancelada"] do
        "<span class='text-[11px] text-emerald-700 font-bold bg-emerald-50 px-2.5 py-1 rounded-lg border border-emerald-200'>✓ ATENDIDA TOTALMENTE</span>"
      else
        resource_options =
          Enum.map_join(resources, "\n", fn r ->
            "<option value='#{r.code}'>#{r.name} (Disp: #{r.available})</option>"
          end)

        """
        <form action="/needs/assign" method="post" class="flex items-center gap-1.5">
          <input type="hidden" name="need_id" value="#{need.id}">
          <select name="resource_code" required class="text-[10px] border rounded-lg px-2 py-1.5 bg-white outline-none max-w-[120px]">
            #{resource_options}
          </select>
          <input type="number" name="quantity" value="#{need.remaining_quantity}" min="1" max="#{need.remaining_quantity}" class="text-[10px] w-14 border rounded-lg px-1.5 py-1.5 outline-none font-bold">
          <button type="submit" class="px-2.5 py-1.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg text-[10px] shadow-sm transition">
            Asignar
          </button>
        </form>
        """
      end

    """
    <tr class="hover:bg-slate-50 transition">
      <td class="py-3.5 px-4">
        <div class="font-mono font-bold text-slate-800 text-xs">#{need.id}</div>
        <span class="px-2 py-0.5 rounded-full border text-[9px] uppercase #{prio_badge}">#{need.priority}</span>
      </td>
      <td class="py-3.5 px-4">
        <div class="font-bold text-slate-900 capitalize text-xs">#{need.type}</div>
        <div class="text-[11px] text-slate-600 max-w-sm line-clamp-2">#{need.description}</div>
        <div class="text-[10px] text-slate-400 mt-0.5">👤 Solicitante: <strong class="text-slate-700">#{need.reporter}</strong></div>
      </td>
      <td class="py-3.5 px-4 font-mono">
        <div class="font-bold text-slate-900">#{need.remaining_quantity} / #{need.quantity}</div>
        <div class="text-[10px] text-slate-400">pendiente</div>
      </td>
      <td class="py-3.5 px-4 text-slate-700 font-medium text-xs">#{need.zone}</td>
      <td class="py-3.5 px-4">
        <span class="px-2.5 py-1 rounded-full text-[10px] font-bold uppercase #{status_badge}">#{need.status}</span>
      </td>
      <td class="py-3.5 px-4">
        #{assign_form}
      </td>
    </tr>
    """
  end

  defp render_zone_options(zones) do
    if zones == [] do
      "<option value='Zona General'>Zona General</option>"
    else
      Enum.map_join(zones, "\n", fn z ->
        "<option value='#{z.name}'>#{z.name}</option>"
      end)
    end
  end
end
