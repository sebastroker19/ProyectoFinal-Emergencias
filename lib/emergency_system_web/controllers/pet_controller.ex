defmodule EmergencySystemWeb.PetController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.PetManager

  def index(conn, _params) do
    reports = PetManager.list_reports()
    matches = PetManager.match_pets(50)

    lost_pets = Enum.filter(reports, &(&1.type == "perdida"))
    found_pets = Enum.filter(reports, &(&1.type == "encontrada"))

    matches_html =
      if matches == [] do
        """
        <div class="text-center py-6 bg-slate-50 rounded-xl border border-dashed border-slate-300 text-xs text-slate-500">
          No hay coincidencias automáticas detectadas con puntaje &ge; 50% en este momento.
        </div>
        """
      else
        Enum.map_join(matches, "\n", &render_match_card/1)
      end

    lost_cards =
      if lost_pets == [] do
        "<div class='text-xs text-slate-400 italic py-4'>Sin mascotas perdidas reportadas.</div>"
      else
        Enum.map_join(lost_pets, "\n", &render_pet_card/1)
      end

    found_cards =
      if found_pets == [] do
        "<div class='text-xs text-slate-400 italic py-4'>Sin mascotas encontradas reportadas.</div>"
      else
        Enum.map_join(found_pets, "\n", &render_pet_card/1)
      end

    html_content = """
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Gestión de Mascotas Perdidas y Encontradas</h1>
        <p class="text-slate-500 text-sm mt-0.5">
          Algoritmo inteligente de coincidencia por puntuación ponderada y resolución mutua sin duplicidad.
        </p>
      </div>

      <!-- Sección de Coincidencias Detectadas (Scoring) -->
      <div class="bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center gap-2 mb-4">
          <span class="text-xl">🎯</span>
          <div>
            <h2 class="text-base font-bold text-emerald-950">Coincidencias Automáticas Sugeridas (Scoring &ge; 50%)</h2>
            <p class="text-xs text-emerald-700">Calculado sobre especie, zona, color, tamaño y nombre.</p>
          </div>
        </div>

        <div class="space-y-3">
          #{matches_html}
        </div>
      </div>

      <!-- Cuadrícula: Listas y Formulario -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Mascotas Perdidas -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 space-y-4">
          <div class="flex items-center justify-between border-b pb-3">
            <h3 class="font-bold text-slate-800 text-sm flex items-center gap-2">
              <span>🔍</span> Perdidas (#{length(lost_pets)})
            </h3>
            <span class="text-xs text-amber-600 font-semibold">Buscando hogar</span>
          </div>
          <div class="space-y-3 max-h-[500px] overflow-y-auto pr-1">
            #{lost_cards}
          </div>
        </div>

        <!-- Mascotas Encontradas -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 space-y-4">
          <div class="flex items-center justify-between border-b pb-3">
            <h3 class="font-bold text-slate-800 text-sm flex items-center gap-2">
              <span>🏠</span> Encontradas / Resguardadas (#{length(found_pets)})
            </h3>
            <span class="text-xs text-blue-600 font-semibold">En custodia</span>
          </div>
          <div class="space-y-3 max-h-[500px] overflow-y-auto pr-1">
            #{found_cards}
          </div>
        </div>

        <!-- Formulario de Registro -->
        <div class="space-y-6">
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>➕</span> Registrar Mascota
            </h3>
            <form action="/pets" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Tipo de Reporte</label>
                <select name="type" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  <option value="perdida">Mascota Perdida (Busco a mi mascota)</option>
                  <option value="encontrada">Mascota Encontrada (Hallé un animal)</option>
                </select>
              </div>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Especie</label>
                  <input type="text" name="species" placeholder="perro / gato" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre</label>
                  <input type="text" name="name" placeholder="Ej: Luna / desconocido" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
              </div>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Color</label>
                  <input type="text" name="color" placeholder="negro / blanco" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Tamaño</label>
                  <select name="size" class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                    <option value="pequeño">Pequeño</option>
                    <option value="mediano" selected>Mediano</option>
                    <option value="grande">Grande</option>
                  </select>
                </div>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Zona</label>
                <input type="text" name="zone" placeholder="Ej: zona_norte" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Características / Rasgos</label>
                <input type="text" name="traits" placeholder="Ej: collar rojo, mancha en oreja" class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Contacto Telefónico</label>
                <input type="text" name="contact" placeholder="Ej: 3001234567" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <button type="submit" class="w-full py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Publicar Reporte
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    """

    html(conn, Layout.render(conn, "pets", "Gestión de Mascotas", html_content))
  end

  def report(conn, %{"type" => type, "species" => spec, "name" => name, "color" => col, "size" => size, "zone" => zone, "contact" => cont} = params) do
    user = conn.assigns[:current_user]
    traits = params["traits"] || ""

    case EmergencySystem.report_pet(user.username, type, spec, name, traits, col, size, zone, cont) do
      {:ok, pet} ->
        conn
        |> put_flash(:info, "Reporte de mascota registrado con ID [#{pet.id}].")
        |> redirect(to: "/pets")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al registrar reporte: #{inspect(reason)}")
        |> redirect(to: "/pets")
    end
  end

  def confirm_match(conn, %{"lost_id" => lost_id, "found_id" => found_id}) do
    user = conn.assigns[:current_user]

    case EmergencySystem.confirm_pet_match(user.username, lost_id, found_id) do
      {:ok, _lost, _found} ->
        conn
        |> put_flash(:info, "¡Coincidencia confirmada! Ambos reportes (#{lost_id} y #{found_id}) han sido cerrados como RESUELTOS.")
        |> redirect(to: "/pets")

      {:error, reason} ->
        conn
        |> put_flash(:error, "No se pudo confirmar la coincidencia: #{inspect(reason)}")
        |> redirect(to: "/pets")
    end
  end

  defp render_match_card(m) do
    """
    <div class="bg-white p-4 rounded-xl border border-emerald-300 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <div class="flex items-center gap-2">
          <span class="text-xs font-bold text-emerald-800 bg-emerald-100 px-2.5 py-0.5 rounded-full border border-emerald-300">
            #{m.score}% Similitud
          </span>
          <span class="font-bold text-slate-800 text-xs">
            Perdida [#{m.lost_pet.id} - #{m.lost_pet.name}] &harr; Encontrada [#{m.found_pet.id}]
          </span>
        </div>
        <p class="text-xs text-slate-600 mt-1">
          Especie: <strong class="capitalize">#{m.lost_pet.species}</strong> &bull; Color: <strong class="capitalize">#{m.lost_pet.color}</strong> &bull; Zona: <strong>#{m.lost_pet.zone}</strong>
        </p>
      </div>

      <form action="/pets/match/confirm" method="post">
        <input type="hidden" name="lost_id" value="#{m.lost_pet.id}">
        <input type="hidden" name="found_id" value="#{m.found_pet.id}">
        <button type="submit" class="w-full sm:w-auto px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-sm transition">
          ✓ Confirmar y Cerrar Reportes
        </button>
      </form>
    </div>
    """
  end

  defp render_pet_card(pet) do
    is_resolved = pet.status == "resuelta"

    status_badge =
      if is_resolved do
        "<span class='text-[10px] bg-slate-100 text-slate-700 font-bold px-2 py-0.5 rounded'>RESUELTA</span>"
      else
        "<span class='text-[10px] bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded'>ACTIVA</span>"
      end

    """
    <div class="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs space-y-1">
      <div class="flex justify-between items-start">
        <div>
          <span class="font-mono font-bold text-slate-800">#{pet.id}</span>
          <span class="font-bold text-slate-900 ml-1">#{pet.name}</span>
          <span class="text-slate-500 capitalize">(#{pet.species})</span>
        </div>
        #{status_badge}
      </div>
      <div class="text-slate-600 text-[11px]">
        Color: <strong class="capitalize">#{pet.color}</strong> &bull; Tamaño: <strong class="capitalize">#{pet.size}</strong> &bull; Zona: <strong>#{pet.zone}</strong>
      </div>
      #{if pet.traits != "", do: "<div class='text-[11px] text-slate-500 italic'>\"#{pet.traits}\"</div>", else: ""}
      <div class="text-[10px] text-slate-400 font-mono">Contacto: #{pet.contact}</div>
    </div>
    """
  end
end
