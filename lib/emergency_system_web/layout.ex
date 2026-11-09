defmodule EmergencySystemWeb.Layout do
  @moduledoc """
  Plantilla principal y diseño visual responsivo para la interfaz web.
  Utiliza Tailwind CSS moderno con soporte para roles, alertas y navegación.
  """

  def render(conn, active_tab, title, content) do
    user = conn.assigns[:current_user] || %{username: "invitado", role: "ciudadano"}
    flash = conn.assigns[:flash] || %{}
    flash_info = Phoenix.Flash.get(flash, :info)
    flash_error = Phoenix.Flash.get(flash, :error)

    badge_color =
      case user.role do
        "administrador" -> "bg-purple-100 text-purple-800 border-purple-300"
        "coordinador" -> "bg-blue-100 text-blue-800 border-blue-300"
        "voluntario" -> "bg-emerald-100 text-emerald-800 border-emerald-300"
        _ -> "bg-amber-100 text-amber-800 border-amber-300"
      end

    tabs = [
      {"dashboard", "/", "📊 Panel General"},
      {"zones", "/zones", "🗺️ Zonas & Recursión"},
      {"resources", "/resources", "📦 Recursos"},
      {"needs", "/needs", "🚨 Necesidades"},
      {"shelters", "/shelters", "🏕️ Albergues"},
      {"people", "/people", "👨‍👩‍👧 Familiares"},
      {"pets", "/pets", "🐾 Mascotas"},
      {"concurrency", "/concurrency", "⚡ Test Concurrencia"}
    ]

    tabs_html =
      Enum.map_join(tabs, "\n", fn {key, url, label} ->
        is_active = key == active_tab

        classes =
          if is_active do
            "bg-red-700 text-white font-semibold shadow-sm"
          else
            "text-slate-300 hover:bg-slate-800 hover:text-white"
          end

        """
        <a href="#{url}" class="px-3 py-2 rounded-lg text-sm transition-colors flex items-center gap-1.5 #{classes}">
          #{label}
        </a>
        """
      end)

    flash_html =
      cond do
        flash_info ->
          """
          <div class="max-w-7xl mx-auto px-4 mt-4">
            <div class="bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-r-lg shadow-sm flex items-center justify-between">
              <div class="flex items-center">
                <span class="text-emerald-700 font-medium">✓ #{flash_info}</span>
              </div>
            </div>
          </div>
          """

        flash_error ->
          """
          <div class="max-w-7xl mx-auto px-4 mt-4">
            <div class="bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg shadow-sm flex items-center justify-between">
              <div class="flex items-center">
                <span class="text-red-700 font-medium">⚠️ #{flash_error}</span>
              </div>
            </div>
          </div>
          """

        true ->
          ""
      end

    """
    <!DOCTYPE html>
    <html lang="es" class="h-full bg-slate-50">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>#{title} - Gestión de Emergencias Elixir</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
      <style>
        body { font-family: 'Inter', sans-serif; }
      </style>
    </head>
    <body class="flex flex-col min-h-full text-slate-800">
      <!-- Barra superior / Header -->
      <header class="bg-slate-900 border-b border-slate-800 text-white sticky top-0 z-50 shadow-md">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-16">
            <!-- Logo y título -->
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-red-600 flex items-center justify-center font-bold text-xl shadow-lg shadow-red-900/50">
                🚨
              </div>
              <div>
                <a href="/" class="text-lg font-bold tracking-tight hover:text-red-400 transition-colors">
                  CoordEmergencias <span class="text-xs bg-red-900/80 text-red-300 px-2 py-0.5 rounded font-mono">Elixir OTP</span>
                </a>
                <p class="text-xs text-slate-400">Atención Post-Terremoto | Universidad del Quindío</p>
              </div>
            </div>

            <!-- Selector de Rol Activo -->
            <div class="flex items-center gap-4">
              <form action="/session/switch" method="post" class="flex items-center gap-2">
                <span class="text-xs text-slate-400 hidden sm:inline">Rol actual:</span>
                <span class="text-xs uppercase px-2.5 py-1 rounded-full border font-bold #{badge_color}">
                  #{user.role}
                </span>
                <select name="role" onchange="this.form.submit()" class="text-xs bg-slate-800 text-white border border-slate-700 rounded-lg px-2.5 py-1.5 focus:ring-2 focus:ring-red-500 outline-none">
                  <option value="coordinador" #{if user.role == "coordinador", do: "selected", else: ""}>Cambiar a Coordinador</option>
                  <option value="administrador" #{if user.role == "administrador", do: "selected", else: ""}>Cambiar a Administrador</option>
                  <option value="voluntario" #{if user.role == "voluntario", do: "selected", else: ""}>Cambiar a Voluntario</option>
                  <option value="ciudadano" #{if user.role == "ciudadano", do: "selected", else: ""}>Cambiar a Ciudadano</option>
                </select>
              </form>
            </div>
          </div>
        </div>

        <!-- Barra de navegación con pestañas -->
        <div class="bg-slate-950 border-t border-slate-800 px-4 sm:px-6 lg:px-8">
          <div class="max-w-7xl mx-auto flex items-center gap-1.5 py-2 overflow-x-auto no-scrollbar">
            #{tabs_html}
          </div>
        </div>
      </header>

      <!-- Mensajes Flash -->
      #{flash_html}

      <!-- Contenido Principal -->
      <main class="flex-grow max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        #{content}
      </main>

      <!-- Footer -->
      <footer class="bg-white border-t border-slate-200 mt-auto py-6 text-center text-xs text-slate-500">
        <div class="max-w-7xl mx-auto px-4">
          <p class="font-medium text-slate-700">Sistema Distribuido de Coordinación y Gestión de Emergencias en Elixir</p>
          <p class="mt-1">Programación III | Concurrencia GenServer, Supervisión OTP, 4 Algoritmos Recursivos y Persistencia en Texto Plano</p>
        </div>
      </footer>
    </body>
    </html>
    """
  end
end
