defmodule EmergencySystemWeb.ResourceController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.ResourceManager

  def index(conn, _params) do
    resources = ResourceManager.list_resources()
    history = ResourceManager.get_history()

    resources_rows =
      if resources == [] do
        """
        <tr>
          <td colspan="6" class="text-center py-8 text-slate-400 text-sm">
            No hay recursos registrados en el inventario.
          </td>
        </tr>
        """
      else
        Enum.map_join(resources, "\n", &render_resource_row/1)
      end

    history_rows =
      if history == [] do
        """
        <div class="text-center py-6 text-slate-400 text-xs">
          Sin movimientos de inventario registrados.
        </div>
        """
      else
        history
        |> Enum.take(8)
        |> Enum.map_join("\n", &render_history_item/1)
      end

    html_content = """
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Gestión de Recursos e Inventario Concurrente</h1>
        <p class="text-slate-500 text-sm mt-0.5">
          Control atómico de entradas, salidas y transferencias entre centros de acopio y albergues (GenServer aislado).
        </p>
      </div>

      <!-- Cuadrícula Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Tabla de Inventario (2 columnas) -->
        <div class="lg:col-span-2 space-y-6">
          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="p-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
              <h2 class="font-bold text-slate-800 text-sm flex items-center gap-2">
                <span>📦</span> Inventario en Tiempo Real
              </h2>
              <span class="text-xs text-slate-500">#{length(resources)} items registrados</span>
            </div>

            <div class="overflow-x-auto">
              <table class="w-full text-left text-xs">
                <thead class="bg-slate-50 text-[11px] font-bold text-slate-400 uppercase border-b border-slate-100">
                  <tr>
                    <th class="py-3 px-4">Código</th>
                    <th class="py-3 px-4">Nombre / Categoría</th>
                    <th class="py-3 px-4">Stock Disponible</th>
                    <th class="py-3 px-4">Ubicación</th>
                    <th class="py-3 px-4">Estado</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                  #{resources_rows}
                </tbody>
              </table>
            </div>
          </div>

          <!-- Historial de Movimientos -->
          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>📜</span> Historial Reciente de Movimientos
            </h3>
            <div class="space-y-2">
              #{history_rows}
            </div>
          </div>
        </div>

        <!-- Columna Lateral: Formularios -->
        <div class="space-y-6">
          <!-- Formulario: Registrar / Ingresar Recurso -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>➕</span> Registrar Entrada de Recurso
            </h3>
            <form action="/resources" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Código de Recurso</label>
                <input type="text" name="code" placeholder="Ej: R_AGUA_01" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre</label>
                <input type="text" name="name" placeholder="Ej: Agua Potable Bidón" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Cantidad</label>
                  <input type="number" name="quantity" min="1" placeholder="Ej: 200" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Unidad</label>
                  <input type="text" name="unit" placeholder="litros / cajas" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Ubicación / Centro</label>
                <input type="text" name="location" placeholder="Ej: centro_acopio_norte" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Entrada
              </button>
            </form>
          </div>

          <!-- Formulario: Transferencia entre Centros -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>🔄</span> Transferir Recursos
            </h3>
            <form action="/resources/transfer" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Código del Recurso</label>
                <input type="text" name="code" placeholder="Ej: R_AGUA_01" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Ubicación Origen</label>
                <input type="text" name="origin" placeholder="Ej: centro_acopio_norte" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Ubicación Destino</label>
                <input type="text" name="target" placeholder="Ej: albergue_cordillera" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Cantidad a Transferir</label>
                <input type="number" name="quantity" min="1" placeholder="Ej: 50" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Ejecutar Transferencia
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """

    html(conn, Layout.render(conn, "resources", "Gestión de Recursos", html_content))
  end

  def create(conn, %{"code" => code, "name" => name, "quantity" => qty, "unit" => unit, "location" => loc}) do
    user = conn.assigns[:current_user]
    qty_num = String.to_integer(qty)

    case EmergencySystem.register_resource(user.username, code, name, "general", qty_num, unit, loc) do
      {:ok, _res} ->
        conn
        |> put_flash(:info, "Entrada de inventario registrada: #{code} (#{qty_num} #{unit}) en #{loc}.")
        |> redirect(to: "/resources")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al registrar recurso: #{inspect(reason)}")
        |> redirect(to: "/resources")
    end
  end

  def transfer(conn, %{"code" => code, "origin" => origin, "target" => target, "quantity" => qty}) do
    user = conn.assigns[:current_user]
    qty_num = String.to_integer(qty)

    case EmergencySystem.transfer_resource(user.username, code, origin, target, qty_num) do
      {:ok, :transferred, _orig, _dest} ->
        conn
        |> put_flash(:info, "Transferencia de #{qty_num} unidades de #{code} completada con éxito.")
        |> redirect(to: "/resources")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Fallo en transferencia: #{inspect(reason)}")
        |> redirect(to: "/resources")
    end
  end

  defp render_resource_row(r) do
    is_critical = r.available <= 10

    status_badge =
      if is_critical do
        "<span class='px-2.5 py-0.5 rounded-full bg-red-100 text-red-700 border border-red-300 font-bold text-[10px]'>CRÍTICO</span>"
      else
        "<span class='px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-700 border border-emerald-300 font-bold text-[10px]'>DISPONIBLE</span>"
      end

    """
    <tr class="hover:bg-slate-50 transition">
      <td class="py-3 px-4 font-mono font-bold text-slate-800">#{r.code}</td>
      <td class="py-3 px-4">
        <div class="font-medium text-slate-800">#{r.name}</div>
        <div class="text-[11px] text-slate-400 capitalize">#{r.category}</div>
      </td>
      <td class="py-3 px-4 font-bold text-slate-900">
        #{r.available} <span class="text-xs text-slate-500 font-normal">#{r.unit}</span>
      </td>
      <td class="py-3 px-4 text-slate-600">#{r.location}</td>
      <td class="py-3 px-4">#{status_badge}</td>
    </tr>
    """
  end

  defp render_history_item(h) do
    type_badge =
      case h.type do
        :entry -> "<span class='text-emerald-700 font-bold'>[ENTRADA]</span>"
        :exit -> "<span class='text-red-700 font-bold'>[SALIDA]</span>"
        :transfer -> "<span class='text-blue-700 font-bold'>[TRANSFERENCIA]</span>"
      end

    """
    <div class="flex items-center justify-between p-2.5 bg-slate-50 rounded-lg border border-slate-100 text-xs">
      <div>
        #{type_badge} <span class="font-mono font-semibold text-slate-800">#{h.code}</span>
        #{if h[:from] && h[:to], do: "<span class='text-slate-500'>(#{h.from} &rarr; #{h.to})</span>", else: ""}
      </div>
      <div class="font-bold text-slate-700">#{h.amount} unidades</div>
    </div>
    """
  end
end
