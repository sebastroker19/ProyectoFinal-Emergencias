defmodule EmergencySystemWeb.ShelterController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.Shelter
  alias EmergencySystem.PersonManager

  def index(conn, _params) do
    shelters = Shelter.occupancy_report()
    people = PersonManager.search_people(%{})

    shelters_cards =
      if shelters == [] do
        """
        <div class="text-center py-12 bg-white rounded-3xl border border-dashed border-slate-300">
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
        <h1 class="text-2xl font-extrabold text-slate-900 tracking-tight">Gestión de Albergues y Control de Aforo</h1>
        <p class="text-slate-500 text-sm mt-0.5">
          Reporte clasificado de mayor a menor nivel de ocupación, censo de personas albergadas y control estricto que impide el sobrecupo.
        </p>
      </div>

      <!-- Cuadrícula Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Tarjetas de Albergues (2 columnas) -->
        <div class="lg:col-span-2 space-y-5">
          #{shelters_cards}
        </div>

        <!-- Columna de Formularios -->
        <div class="space-y-6">
          <!-- Formulario: Registrar Albergue -->
          <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-3">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2 border-b pb-2">
              <span>➕</span> Registrar Nuevo Albergue
            </h3>
            <form action="/shelters" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Código Oficial</label>
                <input type="text" name="code" placeholder="Ej: ALB-03" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Nombre del Albergue</label>
                <input type="text" name="name" placeholder="Ej: Albergue Gimnasio del Quindío" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Zona Territorial</label>
                <input type="text" name="zone" placeholder="Ej: Zona 1 - Centro Histórico" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Capacidad Máxima (Aforo)</label>
                <input type="number" name="max_capacity" min="1" placeholder="Ej: 150" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl transition shadow-sm">
                Registrar Albergue
              </button>
            </form>
          </div>

          <!-- Formulario: Registrar Ingreso -->
          <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-3">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2 border-b pb-2">
              <span>📥</span> Registrar Ingreso de Persona
            </h3>
            <form action="/shelters/entry" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Albergue de Destino</label>
                <select name="shelter_code" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-emerald-500 outline-none bg-white">
                  #{render_shelter_options(shelters)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Seleccionar Persona Registrada</label>
                <select onchange="if(this.value) document.getElementById('input_person_doc').value = this.value" class="w-full text-xs px-3.5 py-2 border rounded-xl bg-slate-50 text-slate-700 outline-none mb-1">
                  <option value="">-- Seleccionar de la lista de afectados --</option>
                  #{render_people_options(people)}
                </select>
                <input type="text" id="input_person_doc" name="person_doc" placeholder="O escribir documento de identidad" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-emerald-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl transition shadow-sm">
                Confirmar Ingreso a Albergue
              </button>
            </form>
          </div>

          <!-- Formulario: Registrar Salida -->
          <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-3">
            <h3 class="font-bold text-slate-900 text-sm flex items-center gap-2 border-b pb-2">
              <span>📤</span> Registrar Salida / Traslado
            </h3>
            <form action="/shelters/exit" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Albergue</label>
                <select name="shelter_code" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-slate-500 outline-none bg-white">
                  #{render_shelter_options(shelters)}
                </select>
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Documento de Identidad</label>
                <input type="text" name="person_doc" placeholder="Ej: 10949001" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-slate-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2.5 bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs rounded-xl transition shadow-sm">
                Registrar Salida y Liberar Cupo
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
        |> put_flash(:info, "Albergue [#{s.code}] #{s.name} registrado con capacidad de #{s.max_capacity} personas.")
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
        # Actualizar estado de la persona a 'en_albergue' si existe
        EmergencySystem.update_person_status(user.username, doc, "en_albergue", s.zone)

        conn
        |> put_flash(:info, "Ingreso registrado para doc #{doc}. Ocupación actual: #{s.current_occupancy}/#{s.max_capacity}.")
        |> redirect(to: "/shelters")

      {:error, :shelter_full} ->
        conn
        |> put_flash(:error, "¡ALERTA DE SOBRECUP0! El albergue #{code} ha alcanzado su capacidad máxima permitida.")
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

    # Consultar detalle del albergue para listar los ocupantes con nombres reales
    occupants_list =
      case Shelter.check_shelter(s.code) do
        {:ok, shelter_detail} ->
          shelter_detail.occupants
          |> MapSet.to_list()
          |> Enum.map(fn doc ->
            case PersonManager.find_person(doc) do
              {:ok, p} -> "#{p.name} (Doc: #{doc} &bull; #{p.age} años)"
              _ -> "Ciudadano Doc: #{doc}"
            end
          end)

        _ ->
          []
      end

    occupants_html =
      if occupants_list == [] do
        "<span class='text-xs text-slate-400 italic'>Sin personas albergadas en este momento.</span>"
      else
        occupants_list
        |> Enum.map_join("\n", fn label ->
          """
          <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-slate-100 text-slate-700 text-xs font-medium border border-slate-200">
            <span>👤</span>
            <span>#{label}</span>
          </span>
          """
        end)
      end

    """
    <div class="bg-white rounded-3xl border border-slate-200 shadow-sm p-6 space-y-4">
      <div class="flex items-start justify-between">
        <div>
          <div class="flex items-center gap-2">
            <span class="font-mono font-bold text-xs bg-slate-900 text-white px-2.5 py-1 rounded-lg">#{s.code}</span>
            <h3 class="font-extrabold text-slate-900 text-base">#{s.name}</h3>
          </div>
          <p class="text-xs text-slate-500 mt-1 flex items-center gap-1">
            <span>📍</span> <span>#{s.zone}</span>
          </p>
        </div>
        <div class="text-right">
          <div class="text-xl font-extrabold text-slate-900">#{s.occupancy_percentage}%</div>
          <span class="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Aforo Ocupado</span>
        </div>
      </div>

      <!-- Barra Visual de Capacidad -->
      <div class="space-y-1.5">
        <div class="w-full bg-slate-100 rounded-full h-3.5 overflow-hidden p-0.5 border border-slate-200">
          <div class="#{bar_color} h-2.5 rounded-full transition-all" style="width: #{min(100, s.occupancy_percentage)}%"></div>
        </div>
        <div class="flex justify-between text-xs font-semibold text-slate-600">
          <span>Ocupantes actuales: <strong class="text-slate-900">#{s.current_occupancy}</strong></span>
          <span>Cupos disponibles: <strong class="text-emerald-700">#{s.available_spots}</strong> de #{s.max_capacity}</span>
        </div>
      </div>

      <!-- Censo de Ocupantes Reales -->
      <div class="pt-3 border-t border-slate-100">
        <span class="block text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-2">Censo de Personas en este Albergue:</span>
        <div class="flex flex-wrap gap-2">
          #{occupants_html}
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
        "<option value='#{s.code}'>#{s.name} (Libres: #{s.available_spots} cupos)</option>"
      end)
    end
  end

  defp render_people_options(people) do
    Enum.map_join(people, "\n", fn p ->
      "<option value='#{p.document}'>#{p.name} - #{p.document} (#{p.status})</option>"
    end)
  end
end
