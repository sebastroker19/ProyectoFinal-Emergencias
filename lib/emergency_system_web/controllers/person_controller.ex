defmodule EmergencySystemWeb.PersonController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout
  alias EmergencySystem.PersonManager

  def index(conn, params) do
    search_query = params["q"] || ""
    filters = if search_query != "", do: %{"name" => search_query}, else: %{}
    people = PersonManager.search_people(filters)
    selected_doc = params["doc"] || (if people != [], do: hd(people).document, else: nil)

    selected_person =
      if selected_doc do
        case PersonManager.find_person(selected_doc) do
          {:ok, p} -> p
          _ -> nil
        end
      else
        nil
      end

    messages =
      if selected_doc do
        PersonManager.list_messages(selected_doc)
      else
        []
      end

    people_list =
      if people == [] do
        """
        <div class="text-center py-8 text-slate-400 text-xs">
          No se encontraron personas con este criterio.
        </div>
        """
      else
        Enum.map_join(people, "\n", fn p ->
          is_selected = p.document == selected_doc

          """
          <a href="/people?doc=#{p.document}" class="block p-3 rounded-xl border transition #{if is_selected, do: "bg-red-50 border-red-300 shadow-sm", else: "bg-white border-slate-200 hover:bg-slate-50"}">
            <div class="flex justify-between items-start">
              <div>
                <div class="font-bold text-xs text-slate-800">#{p.name}</div>
                <div class="text-[11px] text-slate-500 font-mono">Doc: #{p.document} &bull; Edad: #{p.age}</div>
              </div>
              <span class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase bg-slate-100 text-slate-700">
                #{p.status}
              </span>
            </div>
          </a>
          """
        end)
      end

    detail_panel =
      if selected_person do
        render_person_detail(selected_person, messages)
      else
        """
        <div class="text-center py-16 bg-white rounded-2xl border border-dashed border-slate-300">
          <p class="text-slate-500 text-sm font-medium">Seleccione una persona de la lista o registre una nueva.</p>
        </div>
        """
      end

    html_content = """
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Comunicación entre Familiares y Localización</h1>
        <p class="text-slate-500 text-sm mt-0.5">
          Directorio de personas afectadas, trazabilidad de traslados/estados y buzón de mensajes familiares.
        </p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Columna Izquierda: Búsqueda y Lista -->
        <div class="space-y-4">
          <form action="/people" method="get" class="flex gap-2">
            <input type="text" name="q" value="#{search_query}" placeholder="Buscar por nombre..." class="flex-grow text-xs px-3 py-2 border rounded-xl outline-none focus:ring-2 focus:ring-red-500">
            <button type="submit" class="px-3 py-2 bg-slate-900 text-white rounded-xl text-xs font-bold">Buscar</button>
          </form>

          <!-- Listado -->
          <div class="space-y-2 max-h-[500px] overflow-y-auto pr-1">
            #{people_list}
          </div>

          <!-- Formulario: Reportar Persona -->
          <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm mt-6">
            <h3 class="font-bold text-slate-900 text-sm mb-3 flex items-center gap-2">
              <span>➕</span> Registrar Persona Afectada
            </h3>
            <form action="/people" method="post" class="space-y-3">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Documento / Referencia</label>
                <input type="text" name="document" placeholder="Ej: 10949001" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nombre Completo</label>
                <input type="text" name="name" placeholder="Ej: Carlos Gómez" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div class="grid grid-cols-2 gap-2">
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Edad</label>
                  <input type="number" name="age" min="0" placeholder="Ej: 35" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
                <div>
                  <label class="block text-xs font-semibold text-slate-600 mb-1">Zona</label>
                  <input type="text" name="zone" placeholder="Ej: zona_centro" required class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none">
                </div>
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Estado</label>
                <select name="status" class="w-full text-xs px-3 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  <option value="reportada">Reportada</option>
                  <option value="localizada" selected>Localizada</option>
                  <option value="en_albergue">En Albergue</option>
                  <option value="trasladada">Trasladada</option>
                  <option value="reunificada">Reunificada</option>
                  <option value="sin_informacion">Sin Información</option>
                </select>
              </div>
              <button type="submit" class="w-full py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-lg transition shadow-sm">
                Registrar Persona
              </button>
            </form>
          </div>
        </div>

        <!-- Columna Derecha: Detalle, Historial y Mensajes Familiares (2 columnas) -->
        <div class="lg:col-span-2">
          #{detail_panel}
        </div>
      </div>
    </div>
    """

    html(conn, Layout.render(conn, "people", "Localización y Familiares", html_content))
  end

  def report(conn, %{"document" => doc, "name" => name, "age" => age, "zone" => zone, "status" => status}) do
    user = conn.assigns[:current_user]
    age_num = String.to_integer(age)

    case EmergencySystem.report_person(user.username, doc, name, age_num, zone, status) do
      {:ok, _p} ->
        conn
        |> put_flash(:info, "Persona #{name} (#{doc}) registrada exitosamente.")
        |> redirect(to: "/people?doc=#{doc}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al registrar persona: #{inspect(reason)}")
        |> redirect(to: "/people")
    end
  end

  def update_status(conn, %{"document" => doc, "status" => status, "zone" => zone}) do
    user = conn.assigns[:current_user]

    case EmergencySystem.update_person_status(user.username, doc, status, zone) do
      {:ok, _p} ->
        conn
        |> put_flash(:info, "Estado actualizado a '#{status}'.")
        |> redirect(to: "/people?doc=#{doc}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al actualizar estado: #{inspect(reason)}")
        |> redirect(to: "/people?doc=#{doc}")
    end
  end

  def send_message(conn, %{"document" => doc, "content" => content}) do
    user = conn.assigns[:current_user]

    case EmergencySystem.send_family_message(user.username, doc, content) do
      {:ok, _msg} ->
        conn
        |> put_flash(:info, "Mensaje guardado para el familiar.")
        |> redirect(to: "/people?doc=#{doc}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al enviar mensaje: #{inspect(reason)}")
        |> redirect(to: "/people?doc=#{doc}")
    end
  end

  def mark_delivered(conn, %{"id" => id, "doc" => doc}) do
    user = conn.assigns[:current_user]
    id_num = String.to_integer(id)

    case EmergencySystem.mark_message_delivered(user.username, id_num) do
      :ok ->
        conn
        |> put_flash(:info, "Mensaje marcado como entregado.")
        |> redirect(to: "/people?doc=#{doc}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error al actualizar mensaje: #{inspect(reason)}")
        |> redirect(to: "/people?doc=#{doc}")
    end
  end

  defp render_person_detail(person, messages) do
    history_items =
      Enum.map_join(person.history, "\n", fn h ->
        """
        <li class="flex items-center gap-2 text-xs text-slate-600">
          <span class="w-1.5 h-1.5 rounded-full bg-red-600"></span>
          <span class="font-bold text-slate-800">#{h.status}</span> en #{h.zone}
        </li>
        """
      end)

    messages_items =
      if messages == [] do
        """
        <div class="text-xs text-slate-400 italic py-3">No hay mensajes familiares registrados para esta persona.</div>
        """
      else
        Enum.map_join(messages, "\n", fn m ->
          is_delivered = m.status == "entregado"

          status_badge =
            if is_delivered do
              "<span class='text-[10px] text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded'>✓ ENTREGADO</span>"
            else
              """
              <form action="/people/messages/#{m.id}/deliver" method="post" class="inline">
                <input type="hidden" name="doc" value="#{person.document}">
                <button type="submit" class="text-[10px] text-blue-600 font-bold hover:underline">
                  Marcar como entregado &rarr;
                </button>
              </form>
              """
            end

          """
          <div class="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs space-y-1">
            <div class="flex justify-between items-center">
              <span class="font-bold text-slate-700">De: #{m.sender}</span>
              #{status_badge}
            </div>
            <p class="text-slate-800 text-xs">\"#{m.content}\"</p>
          </div>
          """
        end)
      end

    """
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-6">
      <div class="flex items-start justify-between border-b border-slate-100 pb-4">
        <div>
          <div class="flex items-center gap-3">
            <h2 class="text-xl font-bold text-slate-900">#{person.name}</h2>
            <span class="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase bg-red-100 text-red-800">
              #{person.status}
            </span>
          </div>
          <p class="text-xs text-slate-500 font-mono mt-1">Doc: #{person.document} &bull; Edad: #{person.age} años &bull; Zona: #{person.zone}</p>
        </div>

        <!-- Formulario Actualizar Estado Rápido -->
        <form action="/people/status" method="post" class="flex gap-2">
          <input type="hidden" name="document" value="#{person.document}">
          <input type="hidden" name="zone" value="#{person.zone}">
          <select name="status" class="text-xs border rounded-lg px-2.5 py-1.5 bg-white outline-none">
            <option value="localizada">Localizada</option>
            <option value="en_albergue">En Albergue</option>
            <option value="trasladada">Trasladada</option>
            <option value="reunificada">Reunificada</option>
          </select>
          <button type="submit" class="text-xs px-3 py-1.5 bg-slate-800 text-white font-bold rounded-lg hover:bg-slate-700">
            Actualizar
          </button>
        </form>
      </div>

      <!-- Historial de Cambios -->
      <div class="space-y-2">
        <h4 class="text-xs font-bold text-slate-400 uppercase tracking-wider">Historial de Estados / Trazabilidad:</h4>
        <ul class="space-y-1 bg-slate-50 p-3 rounded-xl border border-slate-100">
          #{history_items}
        </ul>
      </div>

      <!-- Buzón de Mensajes Familiares -->
      <div class="space-y-3 pt-2">
        <h4 class="text-xs font-bold text-slate-400 uppercase tracking-wider">Buzón de Mensajes Familiares:</h4>
        <div class="space-y-2">
          #{messages_items}
        </div>

        <!-- Formulario para dejar mensaje -->
        <form action="/people/messages" method="post" class="mt-4 pt-4 border-t border-slate-100 flex gap-2">
          <input type="hidden" name="document" value="#{person.document}">
          <input type="text" name="content" placeholder="Escribir mensaje para la persona o sus familiares..." required class="flex-grow text-xs px-3 py-2 border rounded-xl outline-none focus:ring-2 focus:ring-red-500">
          <button type="submit" class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl shadow-sm">
            Enviar Mensaje
          </button>
        </form>
      </div>
    </div>
    """
  end
end
