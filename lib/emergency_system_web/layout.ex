defmodule EmergencySystemWeb.Layout do
  @moduledoc """
  Plantilla principal y diseño visual responsivo para la interfaz web.
  Incluye estilos embebidos completos para asegurar que la interfaz se vea impecable
  y totalmente terminada, con o sin conexión a internet.
  """

  def render(conn, active_tab, title, content) do
    user = conn.assigns[:current_user] || %{
      username: "laura.morales",
      full_name: "Dra. Laura Morales",
      role: "coordinador",
      zone: "Zona 1 - Centro Histórico"
    }

    flash = conn.assigns[:flash] || %{}
    flash_info = Phoenix.Flash.get(flash, :info)
    flash_error = Phoenix.Flash.get(flash, :error)

    # Iniciales para el avatar
    initials =
      user[:full_name]
      |> to_string()
      |> String.split(" ", trim: true)
      |> Enum.take(2)
      |> Enum.map_join("", &String.first/1)
      |> String.upcase()

    initials = if initials == "", do: "US", else: initials

    {role_badge_bg, role_label} =
      case user[:role] do
        "administrador" -> {"bg-purple-600 text-white", "Administradora General"}
        "coordinador" -> {"bg-blue-600 text-white", "Coordinadora de Zona"}
        "voluntario" -> {"bg-emerald-600 text-white", "Voluntario Socorrista"}
        _ -> {"bg-amber-600 text-white", "Ciudadano"}
      end

    tabs = [
      {"dashboard", "/", "📊 Panel General"},
      {"zones", "/zones", "🗺️ Zonas & Jerarquía"},
      {"resources", "/resources", "📦 Suministros"},
      {"needs", "/needs", "🚨 Solicitudes de Auxilio"},
      {"shelters", "/shelters", "🏕️ Albergues y Aforo"},
      {"people", "/people", "👨‍👩‍👧 Búsqueda y Familias"},
      {"pets", "/pets", "🐾 Rescate Animal"},
      {"concurrency", "/concurrency", "⚡ Test Concurrencia"}
    ]

    tabs_html =
      Enum.map_join(tabs, "\n", fn {key, url, label} ->
        is_active = key == active_tab

        classes =
          if is_active do
            "bg-red-600 text-white font-bold shadow-sm"
          else
            "text-slate-300 hover:bg-slate-800 hover:text-white"
          end

        """
        <a href="#{url}" class="px-3.5 py-2 rounded-xl text-xs transition-all flex items-center gap-1.5 whitespace-nowrap #{classes}">
          #{label}
        </a>
        """
      end)

    flash_html =
      cond do
        flash_info ->
          """
          <div class="max-w-7xl mx-auto px-4 mt-4">
            <div class="bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-xl shadow-sm flex items-center justify-between text-xs text-emerald-800 font-medium">
              <div class="flex items-center gap-2">
                <span class="text-base">✓</span>
                <span>#{flash_info}</span>
              </div>
            </div>
          </div>
          """

        flash_error ->
          """
          <div class="max-w-7xl mx-auto px-4 mt-4">
            <div class="bg-red-50 border-l-4 border-red-500 p-4 rounded-xl shadow-sm flex items-center justify-between text-xs text-red-800 font-medium">
              <div class="flex items-center gap-2">
                <span class="text-base">⚠️</span>
                <span>#{flash_error}</span>
              </div>
            </div>
          </div>
          """

        true ->
          ""
      end

    """
    <!DOCTYPE html>
    <html lang="es" class="h-full bg-slate-100">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>#{title} | Plataforma de Gestión de Emergencias</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
      <style>
        * { font-family: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif; }
        code, pre, .font-mono { font-family: 'JetBrains Mono', monospace; }
        /* Fallbacks si no carga el CDN de Tailwind */
        body { background-color: #f1f5f9; color: #0f172a; margin: 0; }
        a { text-decoration: none; }
        .no-scrollbar::-webkit-scrollbar { display: none; }
        .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
      </style>
    </head>
    <body class="flex flex-col min-h-full">
      <!-- Encabezado Principal / Header Corporativo -->
      <header class="bg-slate-900 border-b border-slate-800 text-white sticky top-0 z-50 shadow-md">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-20">
            <!-- Logo y Título Institucional -->
            <div class="flex items-center gap-3.5">
              <div class="w-11 h-11 rounded-2xl bg-gradient-to-tr from-red-600 to-rose-500 flex items-center justify-center font-bold text-2xl shadow-lg shadow-red-900/40">
                🚨
              </div>
              <div>
                <a href="/" class="text-lg font-extrabold tracking-tight hover:text-red-400 transition flex items-center gap-2">
                  <span>SISTEMA DE GESTIÓN DE EMERGENCIAS</span>
                  <span class="text-[10px] bg-red-950 text-red-300 border border-red-800/80 px-2 py-0.5 rounded font-mono font-semibold">ELIXIR OTP</span>
                </a>
                <p class="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                  <span>Puesto de Mando Unificado (PMU)</span>
                  <span>&bull;</span>
                  <span class="text-slate-300">Universidad del Quindío</span>
                </p>
              </div>
            </div>

            <!-- Ficha del Usuario Autenticado (Con Nombres Reales) -->
            <div class="flex items-center gap-3">
              <!-- Tarjeta de Identidad del Usuario Activo -->
              <div class="hidden sm:flex items-center gap-3 px-3.5 py-1.5 bg-slate-800/90 rounded-2xl border border-slate-700/80 shadow-sm">
                <!-- Avatar Circular -->
                <div class="w-9 h-9 rounded-xl bg-gradient-to-tr from-slate-700 to-slate-600 border border-slate-500 text-white flex items-center justify-center font-bold text-xs shadow-inner">
                  #{initials}
                </div>
                <!-- Información Humana -->
                <div class="text-left">
                  <div class="text-xs font-bold text-white flex items-center gap-1.5">
                    <span>#{user[:full_name]}</span>
                  </div>
                  <div class="flex items-center gap-1.5 mt-0.5">
                    <span class="text-[10px] font-bold px-2 py-0.2 rounded-full #{role_badge_bg}">
                      #{role_label}
                    </span>
                    <span class="text-[10px] text-slate-400 truncate max-w-[130px]" title="#{user[:zone]}">
                      📍 #{user[:zone]}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Botones de Cambio / Cierre de Sesión -->
              <div class="flex items-center gap-2">
                <a href="/login" class="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 rounded-xl text-xs font-semibold transition flex items-center gap-1.5 shadow-sm" title="Cambiar usuario o perfil de demostración">
                  <span>🔄</span>
                  <span class="hidden md:inline">Cambiar Usuario</span>
                </a>
                <a href="/logout" class="px-3 py-2 bg-red-950/80 hover:bg-red-900 text-red-200 border border-red-800/50 rounded-xl text-xs font-semibold transition flex items-center gap-1" title="Cerrar sesión">
                  <span>🚪</span>
                  <span class="hidden md:inline">Salir</span>
                </a>
              </div>
            </div>
          </div>
        </div>

        <!-- Barra de Navegación por Pestañas -->
        <div class="bg-slate-950 border-t border-slate-800/80 px-4 sm:px-6 lg:px-8">
          <div class="max-w-7xl mx-auto flex items-center gap-1.5 py-2.5 overflow-x-auto no-scrollbar">
            #{tabs_html}
          </div>
        </div>
      </header>

      <!-- Mensajes Flash / Notificaciones -->
      #{flash_html}

      <!-- Contenedor Principal -->
      <main class="flex-grow max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        #{content}
      </main>

      <!-- Pie de Página Institucional -->
      <footer class="bg-white border-t border-slate-200 mt-auto py-6 text-center text-xs text-slate-500 shadow-inner">
        <div class="max-w-7xl mx-auto px-4 space-y-1">
          <p class="font-bold text-slate-800">
            Sistema Distribuido de Coordinación y Gestión de Emergencias &bull; Proyecto Final Programación III
          </p>
          <p class="text-slate-500">
            Facultad de Ingeniería &bull; Ingeniería de Sistemas y Computación &bull; Universidad del Quindío
          </p>
          <div class="pt-2 flex justify-center items-center gap-4 text-[11px] text-slate-400 font-mono">
            <span>OTP Supervisor: Activo</span>
            <span>&bull;</span>
            <span>7 GenServers Supervisados</span>
            <span>&bull;</span>
            <span>Persistencia en Texto Plano (.txt)</span>
          </div>
        </div>
      </footer>
    </body>
    </html>
    """
  end
end
