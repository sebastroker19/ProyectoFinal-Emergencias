defmodule EmergencySystemWeb.DashboardController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout

  def index(conn, _params) do
    user = conn.assigns[:current_user]
    summary = EmergencySystem.summary(user.username)
    zones = EmergencySystem.ZoneManager.list_zones()
    _people = EmergencySystem.PersonManager.search_people(%{})

    total_affected =
      Enum.reduce(zones, 0, fn z, acc ->
        acc + EmergencySystem.ZoneManager.sum_zone_affected(Map.values(z.sectors))
      end)

    critical_res_count = length(summary.critical_resources)
    pending_needs_count = length(summary.pending_needs)
    pet_matches_count = length(summary.pet_matches)
    shelters_count = length(summary.shelters_occupancy)

    html_content = """
    <div class="space-y-6">
      <!-- Banner de Bienvenida -->
      <div class="bg-gradient-to-r from-slate-900 to-red-950 rounded-3xl p-6 sm:p-8 text-white shadow-xl border border-red-900/50">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-red-600/30 text-red-300 text-xs font-bold mb-3 border border-red-500/30">
              <span class="w-2 h-2 rounded-full bg-red-400 animate-pulse"></span>
              SISTEMA ACTIVO &bull; SESIÓN: #{user[:full_name]} (#{String.upcase(to_string(user[:role]))})
            </div>
            <h1 class="text-2xl sm:text-3xl font-extrabold tracking-tight">Centro de Mando y Coordinación de Emergencias</h1>
            <p class="text-slate-300 text-xs sm:text-sm mt-1 max-w-2xl leading-relaxed">
              Plataforma distribuida en Elixir / OTP para coordinar atención médica, suministros humanitarios, albergues y búsqueda de personas y mascotas post-terremoto.
            </p>
          </div>
          <div class="flex flex-wrap gap-2.5">
            <a href="/login" class="px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-xs font-bold transition shadow-sm border border-slate-700 flex items-center gap-1.5">
              <span>👤</span> Cambiar Perfil
            </a>
            <a href="/concurrency" class="px-4 py-2.5 bg-red-600 hover:bg-red-700 text-white rounded-xl text-xs font-bold transition shadow-md shadow-red-900/40 flex items-center gap-1.5">
              <span>⚡</span> Probar Concurrencia
            </a>
          </div>
        </div>
      </div>

      <!-- Tarjetas de Métricas Principales -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Afectados -->
        <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Personas Afectadas</span>
            <span class="p-2 bg-red-100 text-red-600 rounded-xl text-lg">👥</span>
          </div>
          <div class="mt-4 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold text-slate-900">#{total_affected}</span>
            <span class="text-xs text-slate-500">en #{length(zones)} zonas</span>
          </div>
          <p class="text-xs text-slate-400 mt-2">Cálculo acumulado mediante algoritmos recursivos</p>
        </div>

        <!-- Recursos Críticos -->
        <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Recursos Críticos</span>
            <span class="p-2 bg-amber-100 text-amber-600 rounded-xl text-lg">⚠️</span>
          </div>
          <div class="mt-4 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold #{if critical_res_count > 0, do: "text-amber-600", else: "text-emerald-600"}">#{critical_res_count}</span>
            <span class="text-xs text-slate-500">stock &le; 10 unidades</span>
          </div>
          <p class="text-xs text-slate-400 mt-2">Monitoreo atómico de inventario</p>
        </div>

        <!-- Necesidades Pendientes -->
        <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Necesidades Pendientes</span>
            <span class="p-2 bg-blue-100 text-blue-600 rounded-xl text-lg">📋</span>
          </div>
          <div class="mt-4 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold text-blue-600">#{pending_needs_count}</span>
            <span class="text-xs text-slate-500">solicitudes activas</span>
          </div>
          <p class="text-xs text-slate-400 mt-2">Priorizadas por criticidad</p>
        </div>

        <!-- Albergues y Mascotas -->
        <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Albergues & Mascotas</span>
            <span class="p-2 bg-emerald-100 text-emerald-600 rounded-xl text-lg">🏕️</span>
          </div>
          <div class="mt-4 flex items-baseline gap-2">
            <span class="text-3xl font-extrabold text-emerald-600">#{shelters_count}</span>
            <span class="text-xs text-slate-500">albergues (#{pet_matches_count} matches)</span>
          </div>
          <p class="text-xs text-slate-400 mt-2">Capacidad y coincidencias</p>
        </div>
      </div>

      <!-- Sección de Dos Columnas: Alertas de Recursos y Necesidades Críticas -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Necesidades de Mayor Prioridad -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-base font-bold text-slate-900 flex items-center gap-2">
              <span>🚨</span> Necesidades Prioritarias
            </h2>
            <a href="/needs" class="text-xs text-red-600 hover:text-red-700 font-semibold">Ver todas &rarr;</a>
          </div>

          #{render_needs_table(summary.pending_needs)}
        </div>

        <!-- Recursos en Estado Crítico -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-base font-bold text-slate-900 flex items-center gap-2">
              <span>⚠️</span> Alerta de Stock Crítico (&le; 10)
            </h2>
            <a href="/resources" class="text-xs text-blue-600 hover:text-blue-700 font-semibold">Ver inventario &rarr;</a>
          </div>

          #{render_resources_alert(summary.critical_resources)}
        </div>
      </div>

      <!-- Resumen de Albergues y Coincidencias de Mascotas -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Ocupación de Albergues -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-base font-bold text-slate-900 flex items-center gap-2">
              <span>🏕️</span> Nivel de Ocupación en Albergues
            </h2>
            <a href="/shelters" class="text-xs text-blue-600 hover:text-blue-700 font-semibold">Gestionar &rarr;</a>
          </div>

          #{render_shelters_summary(summary.shelters_occupancy)}
        </div>

        <!-- Coincidencias de Mascotas -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-base font-bold text-slate-900 flex items-center gap-2">
              <span>🐾</span> Coincidencias de Mascotas Detectadas
            </h2>
            <a href="/pets" class="text-xs text-blue-600 hover:text-blue-700 font-semibold">Ver módulo &rarr;</a>
          </div>

          #{render_pet_matches_summary(summary.pet_matches)}
        </div>
      </div>
    </div>
    """

    html(conn, Layout.render(conn, "dashboard", "Panel de Mando", html_content))
  end

  defp render_needs_table([]) do
    """
    <div class="text-center py-8 text-slate-400 text-sm">
      No hay necesidades pendientes registradas actualmente.
    </div>
    """
  end

  defp render_needs_table(needs) do
    rows =
      needs
      |> Enum.take(5)
      |> Enum.map_join("\n", fn n ->
        badge_cls =
          case n.priority do
            "critica" -> "bg-red-100 text-red-800 border-red-300"
            "alta" -> "bg-amber-100 text-amber-800 border-amber-300"
            _ -> "bg-blue-100 text-blue-800 border-blue-300"
          end

        """
        <tr class="border-b border-slate-100 hover:bg-slate-50 text-xs">
          <td class="py-2.5 font-mono font-bold text-slate-700">#{n.id}</td>
          <td class="py-2.5 font-medium text-slate-800">#{n.type} (x#{n.quantity})</td>
          <td class="py-2.5"><span class="px-2 py-0.5 rounded-full border text-[10px] font-bold uppercase #{badge_cls}">#{n.priority}</span></td>
          <td class="py-2.5 text-slate-500">#{n.zone}</td>
          <td class="py-2.5 text-right">
            <a href="/needs" class="text-red-600 hover:underline font-semibold">Atender</a>
          </td>
        </tr>
        """
      end)

    """
    <div class="overflow-x-auto">
      <table class="w-full text-left">
        <thead>
          <tr class="text-[11px] font-bold text-slate-400 uppercase border-b border-slate-200">
            <th class="pb-2">ID</th>
            <th class="pb-2">Tipo</th>
            <th class="pb-2">Prioridad</th>
            <th class="pb-2">Zona</th>
            <th class="pb-2 text-right">Acción</th>
          </tr>
        </thead>
        <tbody>
          #{rows}
        </tbody>
      </table>
    </div>
    """
  end

  defp render_resources_alert([]) do
    """
    <div class="text-center py-8 text-emerald-600 text-sm font-medium bg-emerald-50/50 rounded-xl border border-emerald-100">
      ✓ Todos los recursos cuentan con niveles adecuados de inventario.
    </div>
    """
  end

  defp render_resources_alert(resources) do
    rows =
      resources
      |> Enum.take(5)
      |> Enum.map_join("\n", fn r ->
        """
        <div class="flex items-center justify-between p-3 rounded-xl bg-amber-50/60 border border-amber-200/60 text-xs">
          <div>
            <div class="font-bold text-slate-800 font-mono">#{r.code} - #{r.name}</div>
            <div class="text-[11px] text-slate-500">Ubicación: #{r.location}</div>
          </div>
          <div class="text-right">
            <div class="text-sm font-extrabold text-amber-700">#{r.available} #{r.unit}</div>
            <span class="text-[10px] text-amber-600 font-semibold">STOCK CRÍTICO</span>
          </div>
        </div>
        """
      end)

    """
    <div class="space-y-2.5">
      #{rows}
    </div>
    """
  end

  defp render_shelters_summary([]) do
    """
    <div class="text-center py-8 text-slate-400 text-sm">
      No hay albergues registrados. <a href="/shelters" class="text-red-600 underline">Registrar albergue</a>
    </div>
    """
  end

  defp render_shelters_summary(shelters) do
    items =
      shelters
      |> Enum.take(4)
      |> Enum.map_join("\n", fn s ->
        bar_color =
          cond do
            s.occupancy_percentage >= 90 -> "bg-red-600"
            s.occupancy_percentage >= 70 -> "bg-amber-500"
            true -> "bg-emerald-500"
          end

        """
        <div class="space-y-1 text-xs">
          <div class="flex justify-between font-medium">
            <span class="text-slate-800">#{s.name} <span class="text-slate-400 font-mono text-[11px]">(#{s.code})</span></span>
            <span class="font-bold text-slate-700">#{s.current_occupancy} / #{s.max_capacity} (#{s.occupancy_percentage}%)</span>
          </div>
          <div class="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
            <div class="#{bar_color} h-2 rounded-full transition-all" style="width: #{min(100, s.occupancy_percentage)}%"></div>
          </div>
        </div>
        """
      end)

    """
    <div class="space-y-3.5">
      #{items}
    </div>
    """
  end

  defp render_pet_matches_summary([]) do
    """
    <div class="text-center py-8 text-slate-400 text-sm">
      Sin coincidencias automáticas pendientes de confirmar.
    </div>
    """
  end

  defp render_pet_matches_summary(matches) do
    items =
      matches
      |> Enum.take(3)
      |> Enum.map_join("\n", fn m ->
        """
        <div class="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs">
          <div>
            <div class="font-semibold text-slate-800">#{m.lost_pet.name} (#{m.lost_pet.species})</div>
            <div class="text-[11px] text-slate-500">Perdida en #{m.lost_pet.zone} &bull; Encontrada en #{m.found_pet.zone}</div>
          </div>
          <div class="text-right">
            <span class="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 font-bold text-xs">
              #{m.score}% Similitud
            </span>
            <div class="mt-1">
              <a href="/pets" class="text-[11px] text-blue-600 font-semibold hover:underline">Revisar</a>
            </div>
          </div>
        </div>
        """
      end)

    """
    <div class="space-y-2.5">
      #{items}
    </div>
    """
  end
end
