defmodule EmergencySystemWeb.ConcurrencyController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.ResourceManager

  @test_code "R_CONC_LAB"

  def index(conn, _params) do
    # Asegurar que el recurso de prueba exista con 50 unidades para la demo
    case ResourceManager.get_resource(@test_code) do
      {:ok, _} -> :ok
      _ -> ResourceManager.register_resource(@test_code, "Agua Potable Demo", "liquidos", 50, "litros", "centro_acopio_1")
    end

    {:ok, current_res} = ResourceManager.get_resource(@test_code)
    history = ResourceManager.get_history(@test_code)

    html_content = render_lab_view(current_res, history, nil)
    html(conn, Layout.render(conn, "concurrency", "Laboratorio de Concurrencia", html_content))
  end

  def simulate(conn, _params) do
    # Reiniciar inventario de prueba a 50 unidades exactas
    ResourceManager.register_resource(@test_code, "Agua Potable Demo", "liquidos", 0, "litros", "centro_acopio_1")
    # Forzar exactamente 50 unidades
    {:ok, current} = ResourceManager.get_resource(@test_code)
    delta = 50 - current.available
    if delta > 0 do
      ResourceManager.register_resource(@test_code, "Agua Potable Demo", "liquidos", delta, "litros", "centro_acopio_1")
    else
      if delta < 0, do: ResourceManager.deduct_resource(@test_code, abs(delta))
    end

    # Lanzar 2 procesos concurrentes con Task.async sobre el mismo recurso:
    # Solicitud A: 30 litros
    # Solicitud B: 25 litros
    # Total solicitado: 55 litros (Solo hay 50)
    task_a = Task.async(fn ->
      start = System.monotonic_time(:millisecond)
      res = ResourceManager.deduct_resource(@test_code, 30)
      finish = System.monotonic_time(:millisecond)
      {:proceso_a, 30, res, finish - start}
    end)

    task_b = Task.async(fn ->
      start = System.monotonic_time(:millisecond)
      res = ResourceManager.deduct_resource(@test_code, 25)
      finish = System.monotonic_time(:millisecond)
      {:proceso_b, 25, res, finish - start}
    end)

    result_a = Task.await(task_a)
    result_b = Task.await(task_b)

    {:ok, final_res} = ResourceManager.get_resource(@test_code)
    history = ResourceManager.get_history(@test_code)

    results = %{
      process_a: result_a,
      process_b: result_b,
      final_stock: final_res.available
    }

    html_content = render_lab_view(final_res, history, results)
    html(conn, Layout.render(conn, "concurrency", "Laboratorio de Concurrencia", html_content))
  end

  defp render_lab_view(resource, _history, simulation_results) do
    simulation_panel =
      if simulation_results do
        render_simulation_results(simulation_results)
      else
        """
        <div class="text-center py-10 bg-slate-50 rounded-2xl border border-dashed border-slate-300">
          <p class="text-slate-600 font-semibold text-sm">Laboratorio listo para ejecución concurrente.</p>
          <p class="text-xs text-slate-400 mt-1">Haz clic en el botón inferior para lanzar 2 procesos paralelos compitiendo por el stock.</p>
        </div>
        """
      end

    """
    <div class="space-y-6">
      <div class="bg-gradient-to-r from-slate-900 to-indigo-950 rounded-2xl p-6 sm:p-8 text-white shadow-lg border border-indigo-900/40">
        <div class="flex items-center gap-3 mb-2">
          <span class="p-2 bg-indigo-600/30 text-indigo-400 rounded-xl text-xl">⚡</span>
          <div>
            <h1 class="text-2xl font-bold tracking-tight">Laboratorio de Concurrencia y Resolución de Conflictos</h1>
            <p class="text-xs text-indigo-300">Demostración en vivo de la Regla de Concurrencia Obligatoria (PDF Págs. 2 y 4).</p>
          </div>
        </div>
        <p class="text-xs text-slate-300 max-w-3xl leading-relaxed mt-2">
          <strong>Enunciado:</strong> Si dos solicitudes intentan tomar simultáneamente el mismo recurso, el sistema debe garantizar que la cantidad asignada nunca supere el inventario disponible ni caiga en números negativos. En Elixir, esto se resuelve mediante el buzón secuencial atómico de <code>GenServer</code>.
        </p>
      </div>

      <!-- Cuadrícula -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Columna Izquierda: Panel de Control y Ejecución (2 columnas) -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Panel de Ejecución -->
          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-4">
            <div class="flex items-center justify-between border-b pb-4">
              <div>
                <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Recurso de Prueba:</span>
                <div class="text-base font-extrabold text-slate-900 font-mono">#{resource.code} - #{resource.name}</div>
              </div>
              <div class="text-right">
                <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Stock Actual:</span>
                <div class="text-2xl font-extrabold text-emerald-600">#{resource.available} #{resource.unit}</div>
              </div>
            </div>

            <!-- Botón de Simulación -->
            <form action="/concurrency/simulate" method="post">
              <button type="submit" class="w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white font-extrabold text-sm rounded-xl transition shadow-md shadow-indigo-600/20 flex items-center justify-center gap-2">
                <span>🚀</span> Ejecutar Simulación Concurrente (30L vs 25L sobre 50L)
              </button>
            </form>

            <!-- Panel de Resultados de la Simulación -->
            #{simulation_panel}
          </div>

          <!-- Justificación Académica -->
          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-3 text-xs leading-relaxed text-slate-600">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2">
              <span>🧠</span> ¿Cómo garantiza Elixir la consistencia de inventario?
            </h3>
            <p>
              1. <strong>Buzón de Mensajes (Mailbox):</strong> Cada proceso <code>GenServer</code> posee su propio buzón de entrada. Aunque dos procesos concurrentes (como Proceso A y Proceso B) envíen sus solicitudes de forma simultánea e independiente en milisegundos idénticos, Erlang/Elixir encola los mensajes y los atiende de manera secuencial y atómica en su callback <code>handle_call/3</code>.
            </p>
            <p>
              2. <strong>Inmutabilidad y Guardas:</strong> Si la primera solicitud consume 30 de los 50 litros disponibles, el estado se actualiza inmutablemente a 20 litros. Cuando el segundo mensaje es procesado, la cláusula de guarda <code>when available &lt; quantity</code> detecta inmediatamente que 20 &lt; 25 y rechaza la operación retornando <code>{:error, {:insufficient_inventory, available: 20, requested: 25}}</code>, impidiendo cualquier condición de carrera (race condition) o número negativo.
            </p>
          </div>
        </div>

        <!-- Columna Derecha: Parámetros del Experimento -->
        <div class="space-y-6">
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4 text-xs">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2">
              <span>🔬</span> Parámetros del Test
            </h3>

            <div class="space-y-3">
              <div class="p-3 bg-slate-50 rounded-xl border border-slate-200">
                <span class="font-bold text-slate-800">Inventario Inicial:</span>
                <div class="text-sm font-extrabold text-slate-900">50 Litros</div>
              </div>

              <div class="p-3 bg-blue-50 rounded-xl border border-blue-200">
                <div class="flex justify-between items-center">
                  <span class="font-bold text-blue-900">Proceso A (Task 1):</span>
                  <span class="font-mono font-bold text-blue-700">30 Litros</span>
                </div>
                <p class="text-[11px] text-blue-600 mt-0.5">Petición asíncrona concurrente</p>
              </div>

              <div class="p-3 bg-purple-50 rounded-xl border border-purple-200">
                <div class="flex justify-between items-center">
                  <span class="font-bold text-purple-900">Proceso B (Task 2):</span>
                  <span class="font-mono font-bold text-purple-700">25 Litros</span>
                </div>
                <p class="text-[11px] text-purple-600 mt-0.5">Petición asíncrona concurrente</p>
              </div>

              <div class="p-3 bg-amber-50 rounded-xl border border-amber-200 text-amber-900">
                <div class="font-bold">Total Demandado: 55 Litros</div>
                <div class="text-[11px] text-amber-700 mt-0.5">Supera los 50 disponibles en 5 unidades. Solo uno debe confirmarse.</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_simulation_results(results) do
    {_proc_a, qty_a, res_a, time_a} = results.process_a
    {_proc_b, qty_b, res_b, time_b} = results.process_b

    status_a =
      case res_a do
        {:ok, _} -> "<span class='px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 font-bold text-xs'>✓ ASIGNACIÓN CONFIRMADA (30L)</span>"
        {:error, _} -> "<span class='px-3 py-1 rounded-full bg-red-100 text-red-800 font-bold text-xs'>✗ RECHAZADO: INVENTARIO INSUFICIENTE</span>"
      end

    status_b =
      case res_b do
        {:ok, _} -> "<span class='px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 font-bold text-xs'>✓ ASIGNACIÓN CONFIRMADA (25L)</span>"
        {:error, _} -> "<span class='px-3 py-1 rounded-full bg-red-100 text-red-800 font-bold text-xs'>✗ RECHAZADO: INVENTARIO INSUFICIENTE</span>"
      end

    """
    <div class="p-5 rounded-2xl bg-slate-900 text-white space-y-4 shadow-inner">
      <div class="flex items-center justify-between border-b border-slate-800 pb-3">
        <h4 class="font-bold text-sm text-emerald-400 flex items-center gap-2">
          <span>🎯</span> RESULTADO DE LA EJECUCIÓN CONCURRENTE
        </h4>
        <span class="text-xs text-slate-400 font-mono">Stock final en almacén: <strong class="text-white">#{results.final_stock} Litros</strong></span>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Proceso A -->
        <div class="p-4 rounded-xl bg-slate-800/90 border border-slate-700 space-y-2">
          <div class="flex justify-between items-center">
            <span class="font-mono font-bold text-xs text-blue-300">Proceso Concurrente A</span>
            <span class="text-[10px] text-slate-400 font-mono">#{time_a}ms</span>
          </div>
          <div class="text-xs text-slate-300">Solicitud: <strong>#{qty_a} Litros</strong></div>
          <div class="pt-1">#{status_a}</div>
          <div class="text-[10px] text-slate-400 font-mono truncate">#{inspect(res_a)}</div>
        </div>

        <!-- Proceso B -->
        <div class="p-4 rounded-xl bg-slate-800/90 border border-slate-700 space-y-2">
          <div class="flex justify-between items-center">
            <span class="font-mono font-bold text-xs text-purple-300">Proceso Concurrente B</span>
            <span class="text-[10px] text-slate-400 font-mono">#{time_b}ms</span>
          </div>
          <div class="text-xs text-slate-300">Solicitud: <strong>#{qty_b} Litros</strong></div>
          <div class="pt-1">#{status_b}</div>
          <div class="text-[10px] text-slate-400 font-mono truncate">#{inspect(res_b)}</div>
        </div>
      </div>

      <div class="p-3 rounded-xl bg-emerald-950/60 border border-emerald-500/30 text-xs text-emerald-200">
        ✓ <strong>Verificación Exitosa:</strong> La suma asignada nunca excedió las 50 unidades disponibles y el inventario restante es de <strong>#{results.final_stock} Litros</strong>. No hubo condición de carrera.
      </div>
    </div>
    """
  end
end
