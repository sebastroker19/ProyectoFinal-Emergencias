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
          <td colspan="6" class="text-center py-10 text-slate-400 text-xs">
            No hay recursos registrados en el inventario del sistema.
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
          Sin movimientos de inventario registrados recientemente.
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
        <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Gestión de Suministros e Inventario Logístico</h1>
        <p class="text-slate-500 text-sm mt-0.5">
          Control atómico y supervisado de entradas, salidas y transferencias entre centros de acopio y albergues oficiales.
        </p>
      </div>

      <!-- Cuadrícula Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Tabla de Inventario (2 columnas) -->
        <div class="lg:col-span-2 space-y-6">
          <div class="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="p-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/70">
              <h2 class="font-bold text-slate-800 text-sm flex items-center gap-2">
                <span>📦</span> Inventario Oficial en Tiempo Real
              </h2>
              <span class="text-xs text-slate-500 font-medium">#{length(resources)} ítems en inventario</span>
            </div>

            <div class="overflow-x-auto">
              <table class="w-full text-left text-xs">
                <thead class="bg-slate-50 text-[11px] font-bold text-slate-400 uppercase border-b border-slate-100">
                  <tr>
                    <th class="py-3 px-4">Código</th>
                    <th class="py-3 px-4">Nombre del Suministro / Categoría</th>
                    <th class="py-3 px-4">Stock Disponible</th>
                    <th class="py-3 px-4">Centro / Ubicación</th>
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
          <div class="bg-white rounded-3xl border border-slate-200 shadow-sm p-6 space-y-3">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2 border-b pb-2">
              <span>📜</span> Trazabilidad de Movimientos y Transferencias
            </h3>
            <div class="space-y-2">
              #{history_rows}
            </div>
          </div>
        </div>

        <!-- Columna Lateral: Formularios -->
        <div class="space-y-6">
          <!-- Formulario: Registrar / Ingresar Recurso -->
          <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-3">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2 border-b pb-2">
              <span>➕</span> Entrada de Suministros
            </h3>
            <form action="/resources" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Código del Suministro</label>
                <input type="text" name="code" placeholder="Ej: AGUA-02 / MED-03" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Nombre Descriptivo</label>
                <input type="text" name="name" placeholder="Ej: Suero Fisiológico 500ml" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block text-xs font-bold text-slate-700 mb-1">Cantidad</label>
                  <input type="number" name="quantity" min="1" placeholder="Ej: 150" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
                </div>
                <div>
                  <label class="block text-xs font-bold text-slate-700 mb-1">Unidad de Medida</label>
                  <input type="text" name="unit" placeholder="cajas / bidones / kits" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
                </div>
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Centro de Acopio / Almacén</label>
                <input type="text" name="location" placeholder="Ej: Centro de Acopio Estadio Centenario" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl transition shadow-sm">
                Registrar Entrada de Inventario
              </button>
            </form>
          </div>

          <!-- Formulario: Transferencia entre Centros -->
          <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-3">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2 border-b pb-2">
              <span>🔄</span> Transferencia Inter-Almacenes
            </h3>
            <form action="/resources/transfer" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Suministro a Transferir</label>
                <select name="code" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-white">
                  #{render_resource_select(resources)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Ubicación Origen Exacta</label>
                <input type="text" name="origin" placeholder="Ej: Centro de Acopio Estadio Centenario" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Albergue o Centro Destino</label>
                <input type="text" name="target" placeholder="Ej: Albergue Polideportivo Norte" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Cantidad a Transferir</label>
                <input type="number" name="quantity" min="1" placeholder="Ej: 30" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl transition shadow-sm">
                Ejecutar Transferencia Inmediata
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

    case EmergencySystem.register_resource(user.username, code, name, "Suministros Humanitarios", qty_num, unit, loc) do
      {:ok, _res} ->
        conn
        |> put_flash(:info, "Entrada de inventario registrada: #{code} - #{name} (#{qty_num} #{unit}) en #{loc}.")
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
        |> put_flash(:info, "Transferencia de #{qty_num} unidades de #{code} desde '#{origin}' hacia '#{target}' completada con éxito.")
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
        "<span class='px-2.5 py-0.5 rounded-full bg-red-100 text-red-700 border border-red-300 font-bold text-[10px] animate-pulse'>STOCK CRÍTICO</span>"
      else
        "<span class='px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-700 border border-emerald-300 font-bold text-[10px]'>DISPONIBLE</span>"
      end

    """
    <tr class="hover:bg-slate-50 transition">
      <td class="py-3 px-4 font-mono font-bold text-slate-800 text-xs">#{r.code}</td>
      <td class="py-3 px-4">
        <div class="font-bold text-slate-900 text-xs">#{r.name}</div>
        <div class="text-[11px] text-slate-500">#{r.category}</div>
      </td>
      <td class="py-3 px-4 font-mono">
        <span class="text-sm font-bold text-slate-900">#{r.available}</span>
        <span class="text-xs text-slate-500 font-normal">#{r.unit}</span>
      </td>
      <td class="py-3 px-4 text-slate-600 font-medium text-xs">#{r.location}</td>
      <td class="py-3 px-4">#{status_badge}</td>
    </tr>
    """
  end

  defp render_history_item(h) do
    type_badge =
      case h.type do
        :entry -> "<span class='px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 font-bold text-[10px]'>ENTRADA</span>"
        :exit -> "<span class='px-2 py-0.5 rounded bg-red-100 text-red-800 font-bold text-[10px]'>SALIDA</span>"
        :transfer -> "<span class='px-2 py-0.5 rounded bg-blue-100 text-blue-800 font-bold text-[10px]'>TRANSFERENCIA</span>"
      end

    """
    <div class="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs">
      <div>
        <div class="flex items-center gap-2">
          #{type_badge}
          <span class="font-mono font-bold text-slate-800">#{h.code}</span>
        </div>
        #{if h[:from] && h[:to], do: "<div class='text-[11px] text-slate-500 mt-0.5'>#{h.from} &rarr; #{h.to}</div>", else: "<div class='text-[11px] text-slate-400 mt-0.5'>Ubicación: #{h[:location]}</div>"}
      </div>
      <div class="font-extrabold text-slate-900 text-sm font-mono">#{h.amount} unid.</div>
    </div>
    """
  end

  defp render_resource_select(resources) do
    if resources == [] do
      "<option value=''>Sin recursos</option>"
    else
      Enum.map_join(resources, "\n", fn r ->
        "<option value='#{r.code}'>#{r.code} - #{r.name} (Disp: #{r.available} en #{r.location})</option>"
      end)
    end
  end
end
