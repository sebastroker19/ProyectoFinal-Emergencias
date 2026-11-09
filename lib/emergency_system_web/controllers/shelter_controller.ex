defmodule EmergencySystemWeb.ShelterController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.Shelter

  def index(conn, _params) do
    shelters = Shelter.occupancy_report()

    shelters_cards =
      if shelters == [] do
        """
        <div class="text-center py-12 bg-white rounded-2xl border border-dashed border-slate-300">
          <p class="text-slate-500 font-medium">No hay albergues registrados.</p>
          <p class="text-xs text-slate-400 mt-1">Utiliza el formulario lateral para dar de alta un albergue.</p>
        </div>
        """
      else
        Enum.map_join(shelters, "\n", &render_shelter_card/1)
      end

    html_content = """
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Gestión de Albergues y Control de Aforo</h1>
        <p class="text-slate-500 text-sm mt-0.5">
          Reporte ordenado por mayor nivel de ocupación, registro de ingresos y salidas con garantía de no sobrecupo.
        </p>
      </div>

      <!-- Cuadrícula Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Tarjetas de Albergues (2 columnas) -->
        <div class="lg:col-span-2 space-y-4">
          #{shelters_cards}
        </div>

        <!-- Columna de Formularios -->
        <div class="space-y-6">
          <!-- Formulario: Registrar Albergue -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>➕</span> Registrar Nuevo Albergue
            </h3>
            <form action="/shelters" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Código del Albergue</label>
                <input type="text" name="code" placeholder="Ej: ALB_NORTE" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre</label>
                <input type="text" name="name" placeholder="Ej: Albergue Polideportivo Norte" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Zona</label>
                <input type="text" name="zone" placeholder="Ej: zona_norte" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Capacidad Máxima (personas)</label>
                <input type="number" name="max_capacity" min="1" placeholder="Ej: 150" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Albergue
              </button>
            </form>
          </div>

          <!-- Formulario: Registrar Ingreso -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>📥</span> Registrar Ingreso de Persona
            </h3>
            <form action="/shelters/entry" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Albergue</label>
                <select name="shelter_code" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  #{render_shelter_options(shelters)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Documento de la Persona</label>
                <input type="text" name="person_doc" placeholder="Ej: 10949001" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Ingreso
              </button>
            </form>
          </div>

          <!-- Formulario: Registrar Salida -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>📤</span> Registrar Salida de Persona
            </h3>
            <form action="/shelters/exit" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Albergue</label>
                <select name="shelter_code" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  #{render_shelter_options(shelters)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Documento de la Persona</label>
                <input type="text" name="person_doc" placeholder="Ej: 10949001" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Salida
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """

    html(conn, Layout.render(conn, "shelters", "Gestión de Albergues", html_content))
  end

  def create(conn, %{"code" => code, "name" => name, "zone" => zone, "max_capacity" => max_cap}) do
    user = conn.assigns[:current_user]
    cap_num = String.to_integer(max_cap)

    case EmergencySystem.register_shelter(user.username, code, name, zone, cap_num) do
      {:ok, s} ->
        conn
        |> put_flash(:info, "Albergue [#{s.code}] #{s.name} registrado con capacidad de #{s.max_capacity}.")
        |> redirect(to: "/shelters")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al registrar albergue: #{inspect(reason)}")
        |> redirect(to: "/shelters")
    end
  end

  def entry(conn, %{"shelter_code" => code, "person_doc" => doc}) do
    user = conn.assigns[:current_user]

    case EmergencySystem.register_shelter_entry(user.username, code, doc) do
      {:ok, s} ->
        conn
        |> put_flash(:info, "Ingreso registrado para doc #{doc}. Ocupación actual: #{s.current_occupancy}/#{s.max_capacity}.")
        |> redirect(to: "/shelters")

      {:error, :shelter_full} ->
        conn
        |> put_flash(:error, "¡ALERTA DE SOBRECUP0! El albergue #{code} ha alcanzado su capacidad máxima.")
        |> redirect(to: "/shelters")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error en ingreso: #{inspect(reason)}")
        |> redirect(to: "/shelters")
    end
  end

  def exit(conn, %{"shelter_code" => code, "person_doc" => doc}) do
    user = conn.assigns[:current_user]

    case EmergencySystem.register_shelter_exit(user.username, code, doc) do
      {:ok, s} ->
        conn
        |> put_flash(:info, "Salida registrada para doc #{doc}. Ocupación actual: #{s.current_occupancy}/#{s.max_capacity}.")
        |> redirect(to: "/shelters")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error en salida: #{inspect(reason)}")
        |> redirect(to: "/shelters")
    end
  end

  defp render_shelter_card(s) do
    bar_color =
      cond do
        s.occupancy_percentage >= 95 -> "bg-red-600"
        s.occupancy_percentage >= 75 -> "bg-amber-500"
        true -> "bg-emerald-500"
      end

    """
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 space-y-3">
      <div class="flex items-start justify-between">
        <div>
          <div class="flex items-center gap-2">
            <span class="font-mono font-bold text-xs bg-slate-100 text-slate-800 px-2 py-0.5 rounded border border-slate-200">#{s.code}</span>
            <h3 class="font-bold text-slate-900 text-base">#{s.name}</h3>
          </div>
          <p class="text-xs text-slate-400 mt-0.5">Zona de ubicación: #{s.zone}</p>
        </div>
        <div class="text-right">
          <div class="text-lg font-extrabold text-slate-900">#{s.occupancy_percentage}%</div>
          <span class="text-[10px] text-slate-400 font-semibold uppercase">Ocupación</span>
        </div>
      </div>

      <!-- Barra de Capacidad -->
      <div class="space-y-1">
        <div class="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
          <div class="#{bar_color} h-3 rounded-full transition-all" style="width: #{min(100, s.occupancy_percentage)}%"></div>
        </div>
        <div class="flex justify-between text-xs text-slate-500 font-medium">
          <span>Ocupantes actuales: <strong>#{s.current_occupancy}</strong></span>
          <span>Cupos libres: <strong class="text-emerald-600">#{s.available_spots}</strong> / #{s.max_capacity}</span>
        </div>
      </div>
    </div>
    """
  end

  defp render_shelter_options(shelters) do
    if shelters == [] do
      "<option value=''>Primero cree un albergue</option>"
    else
      Enum.map_join(shelters, "\n", fn s ->
        "<option value='#{s.code}'>[#{s.code}] #{s.name} (Libres: #{s.available_spots})</option>"
      end)
    end
  end
end
