defmodule EmergencySystemWeb.NeedController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.NeedManager
  alias EmergencySystem.ResourceManager

  def index(conn, params) do
    filters = Map.take(params, ["status", "priority", "zone"]) |> Enum.reject(fn {_, v} -> v == "" end) |> Map.new()
    needs = NeedManager.list_needs(filters)
    resources = ResourceManager.list_resources()

    needs_rows =
      if needs == [] do
        """
        <tr>
          <td colspan="7" class="text-center py-8 text-slate-400 text-sm">
            No hay solicitudes de ayuda registradas con estos criterios.
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
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Gestión de Necesidades Puntuales</h1>
          <p class="text-slate-500 text-sm mt-0.5">
            Solicitudes de auxilio ordenadas por criticidad, con asignación directa de recursos e inmunidad a doble consumo.
          </p>
        </div>
      </div>

      <!-- Cuadrícula Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Tabla de Necesidades (2 columnas) -->
        <div class="lg:col-span-2 space-y-4">
          <!-- Filtros Rápidos -->
          <form action="/needs" method="get" class="bg-white p-3 rounded-xl border border-slate-200 shadow-sm flex flex-wrap gap-3 items-center text-xs">
            <span class="font-bold text-slate-500">Filtrar:</span>
            <select name="priority" onchange="this.form.submit()" class="border rounded-lg px-2.5 py-1.5 bg-white outline-none">
              <option value="">Todas las Prioridades</option>
              <option value="critica" #{if params["priority"] == "critica", do: "selected", else: ""}>Crítica</option>
              <option value="alta" #{if params["priority"] == "alta", do: "selected", else: ""}>Alta</option>
              <option value="media" #{if params["priority"] == "media", do: "selected", else: ""}>Media</option>
              <option value="baja" #{if params["priority"] == "baja", do: "selected", else: ""}>Baja</option>
            </select>
            <select name="status" onchange="this.form.submit()" class="border rounded-lg px-2.5 py-1.5 bg-white outline-none">
              <option value="">Todos los Estados</option>
              <option value="pendiente" #{if params["status"] == "pendiente", do: "selected", else: ""}>Pendiente</option>
              <option value="en_atencion" #{if params["status"] == "en_atencion", do: "selected", else: ""}>En Atención</option>
              <option value="atendida" #{if params["status"] == "atendida", do: "selected", else: ""}>Atendida</option>
            </select>
            <a href="/needs" class="text-slate-400 hover:text-slate-600 font-medium ml-auto">Limpiar filtros</a>
          </form>

          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="overflow-x-auto">
              <table class="w-full text-left text-xs">
                <thead class="bg-slate-50 text-[11px] font-bold text-slate-400 uppercase border-b border-slate-100">
                  <tr>
                    <th class="py-3 px-3">ID / Prioridad</th>
                    <th class="py-3 px-3">Tipo / Descripción</th>
                    <th class="py-3 px-3">Cant. Requerida</th>
                    <th class="py-3 px-3">Zona</th>
                    <th class="py-3 px-3">Estado</th>
                    <th class="py-3 px-3">Asignar Recurso</th>
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
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>➕</span> Registrar Solicitud de Ayuda
            </h3>
            <form action="/needs" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Tipo de Necesidad</label>
                <select name="type" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  <option value="agua">Agua potable</option>
                  <option value="alimentos">Alimentos no perecederos</option>
                  <option value="medicamentos">Medicamentos / Salud</option>
                  <option value="primeros_auxilios">Primeros Auxilios</option>
                  <option value="refugio">Refugio / Carpas</option>
                  <option value="transporte">Transporte / Evacuación</option>
                  <option value="rescate">Rescate</option>
                  <option value="otra">Otra necesidad</option>
                </select>
              </div>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Cantidad</label>
                  <input type="number" name="quantity" min="1" placeholder="Ej: 50" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Prioridad</label>
                  <select name="priority" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                    <option value="critica">Crítica (Urgente)</option>
                    <option value="alta" selected>Alta</option>
                    <option value="media">Media</option>
                    <option value="baja">Baja</option>
                  </select>
                </div>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Zona Afectada</label>
                <input type="text" name="zone" placeholder="Ej: zona_centro / sector_3" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Descripción del requerimiento</label>
                <textarea name="description" rows="3" placeholder="Detalle de personas necesitadas, estado de la emergencia..." required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none"></textarea>
              </div>
              <button type="submit" class="w-full py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Necesidad
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
        |> put_flash(:info, "Necesidad registrada con ID [#{need.id}] (Prioridad #{prio}).")
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
        |> put_flash(:info, "Asignados #{qty_num} de #{res_code} a necesidad #{need.id}. Nuevo estado: #{need.status}.")
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
        "critica" -> "bg-red-100 text-red-800 border-red-300"
        "alta" -> "bg-amber-100 text-amber-800 border-amber-300"
        "media" -> "bg-blue-100 text-blue-800 border-blue-300"
        _ -> "bg-slate-100 text-slate-800 border-slate-300"
      end

    status_badge =
      case need.status do
        "atendida" -> "bg-emerald-100 text-emerald-800"
        "en_atencion" -> "bg-blue-100 text-blue-800"
        _ -> "bg-amber-100 text-amber-800"
      end

    assign_form =
      if need.status in ["atendida", "cancelada"] do
        "<span class='text-[11px] text-emerald-700 font-bold'>✓ ATENDIDA</span>"
      else
        resource_options =
          Enum.map_join(resources, "\n", fn r ->
            "<option value='#{r.code}'>#{r.name} (Disp: #{r.available})</option>"
          end)

        """
        <form action="/needs/assign" method="post" class="flex items-center gap-1">
          <input type="hidden" name="need_id" value="#{need.id}">
          <select name="resource_code" required class="text-[10px] border rounded px-1.5 py-1 bg-white outline-none max-w-[110px]">
            #{resource_options}
          </select>
          <input type="number" name="quantity" value="#{need.remaining_quantity}" min="1" max="#{need.remaining_quantity}" class="text-[10px] w-12 border rounded px-1 py-1 outline-none">
          <button type="submit" class="px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded text-[10px]">
            Asignar
          </button>
        </form>
        """
      end

    """
    <tr class="hover:bg-slate-50 transition">
      <td class="py-3 px-3">
        <div class="font-mono font-bold text-slate-800">#{need.id}</div>
        <span class="px-2 py-0.5 rounded-full border text-[9px] font-bold uppercase #{prio_badge}">#{need.priority}</span>
      </td>
      <td class="py-3 px-3">
        <div class="font-bold text-slate-800 capitalize">#{need.type}</div>
        <div class="text-[11px] text-slate-500 max-w-xs truncate">#{need.description}</div>
      </td>
      <td class="py-3 px-3">
        <div class="font-bold text-slate-800">#{need.remaining_quantity} / #{need.quantity}</div>
        <div class="text-[10px] text-slate-400">pendiente</div>
      </td>
      <td class="py-3 px-3 font-medium text-slate-700">#{need.zone}</td>
      <td class="py-3 px-3">
        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase #{status_badge}">#{need.status}</span>
      </td>
      <td class="py-3 px-3">
        #{assign_form}
      </td>
    </tr>
    """
  end
end
