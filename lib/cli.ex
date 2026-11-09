defmodule EmergencySystem.CLI do
  @moduledoc """
  Interfaz de línea de comandos (CLI) interactiva.
  Soporta todos los comandos sugeridos en la especificación del proyecto (Páginas 6 y 7).
  """

  def main(_args \\ []) do
    {:ok, _} = Application.ensure_all_started(:emergency_system)
    IO.puts("""
    ========================================================================
     SISTEMA DISTRIBUIDO DE COORDINACIÓN Y GESTIÓN DE EMERGENCIAS (ELIXIR)
    ========================================================================
    Escriba 'help' para ver la lista de comandos disponibles o 'exit' para salir.
    """)
    loop(nil)
  end

  defp loop(current_user) do
    prompt = if current_user, do: "#{current_user}> ", else: "invitado> "
    input = IO.gets(prompt) |> to_string() |> String.trim()

    tokens = parse_tokens(input)

    case tokens do
      [] ->
        loop(current_user)

      ["exit"] ->
        if current_user, do: EmergencySystem.disconnect(current_user)
        IO.puts("Cerrando sesión y saliendo del sistema. ¡Hasta luego!")

      ["help"] ->
        print_help()
        loop(current_user)

      ["connect", user, pass | rest] ->
        role = Enum.at(rest, 0) || "ciudadano"
        zone = Enum.at(rest, 1) || "centro"

        case EmergencySystem.connect(user, pass, role, zone) do
          {:ok, :registered_and_connected, assigned_role} ->
            IO.puts(">> Usuario '#{user}' registrado y conectado exitosamente con rol: #{assigned_role} en zona: #{zone}")
            loop(user)

          {:ok, :connected, assigned_role} ->
            IO.puts(">> Bienvenido nuevamente #{user}. Conectado con rol: #{assigned_role}")
            loop(user)

          {:error, reason} ->
            IO.puts(">> Error de autenticación: #{inspect(reason)}")
            loop(current_user)
        end

      ["disconnect"] ->
        if current_user do
          EmergencySystem.disconnect(current_user)
          IO.puts(">> Desconectado exitosamente.")
        else
          IO.puts(">> No hay ninguna sesión activa.")
        end
        loop(nil)

      ["register_zone", code, name, level] ->
        case EmergencySystem.register_zone(current_user, code, name, level) do
          {:ok, zone} -> IO.puts(">> Zona registrada: [#{zone.code}] #{zone.name} (Nivel: #{zone.level})")
          err -> print_error(err)
        end
        loop(current_user)

      ["add_sector", zone_code, sector_name] ->
        case EmergencySystem.add_sector(current_user, zone_code, sector_name) do
          {:ok, _zone} -> IO.puts(">> Sector '#{sector_name}' añadido a la zona #{zone_code}")
          err -> print_error(err)
        end
        loop(current_user)

      ["add_point", zone_code, sector_name, point_name, count] ->
        count_num = String.to_integer(count)
        case EmergencySystem.add_point_of_attention(current_user, zone_code, sector_name, point_name, count_num) do
          {:ok, _zone} -> IO.puts(">> Punto '#{point_name}' añadido al sector '#{sector_name}' con #{count_num} afectados.")
          err -> print_error(err)
        end
        loop(current_user)

      ["zone_stats", zone_code] ->
        case EmergencySystem.get_zone_stats(current_user, zone_code) do
          {:ok, stats} ->
            IO.puts("""
            >> ESTADÍSTICAS DE ZONA #{stats.zone_code} (#{stats.zone_name})
               Nivel: #{stats.level}
               Sectores: #{stats.total_sectors} | Puntos totales: #{stats.total_points}
               Total personas afectadas acumuladas: #{stats.total_affected}
            """)
          err -> print_error(err)
        end
        loop(current_user)

      ["register_need", type, qty, priority, zone | desc_words] ->
        desc = Enum.join(desc_words, " ")
        qty_num = String.to_integer(qty)

        case EmergencySystem.register_need(current_user, type, qty_num, priority, zone, desc) do
          {:ok, need} -> IO.puts(">> Necesidad registrada exitosamente con ID: #{need.id} (Prioridad: #{need.priority})")
          err -> print_error(err)
        end
        loop(current_user)

      ["list_needs" | filter_tokens] ->
        filters = parse_filter_pairs(filter_tokens)
        case EmergencySystem.list_needs(current_user, filters) do
          {:ok, []} -> IO.puts(">> No hay necesidades que coincidan con los filtros.")
          {:ok, list} ->
            IO.puts(">> NECESIDADES (Ordenadas por prioridad):")
            Enum.each(list, fn n ->
              IO.puts("   [#{n.id}] (#{n.priority}) #{n.type} x#{n.quantity} [Zona: #{n.zone}] Estado: #{n.status} - #{n.description}")
            end)
          err -> print_error(err)
        end
        loop(current_user)

      ["pending_needs"] ->
        case EmergencySystem.list_needs(current_user, %{"status" => "pendiente"}) do
          {:ok, list} ->
            IO.puts(">> NECESIDADES PENDIENTES (#{length(list)}):")
            Enum.each(list, &IO.puts("   [#{&1.id}] (#{String.upcase(&1.priority)}) #{&1.type} x#{&1.quantity} - #{&1.description}"))
          err -> print_error(err)
        end
        loop(current_user)

      ["assign_resource", need_id, resource_code, qty] ->
        qty_num = String.to_integer(qty)
        case EmergencySystem.assign_resource(current_user, need_id, resource_code, qty_num) do
          {:ok, need} ->
            IO.puts(">> Recurso #{resource_code} (#{qty_num}) asignado a #{need.id}. Nuevo estado: #{need.status} (Restante: #{need.remaining_quantity})")
          err -> print_error(err)
        end
        loop(current_user)

      ["register_resource", code, name, qty, unit, location] ->
        qty_num = String.to_integer(qty)
        case EmergencySystem.register_resource(current_user, code, name, "general", qty_num, unit, location) do
          {:ok, res} -> IO.puts(">> Recurso registrado: [#{res.code}] #{res.name} (#{res.available} #{res.unit}) en #{res.location}")
          err -> print_error(err)
        end
        loop(current_user)

      ["list_resources"] ->
        case EmergencySystem.list_resources(current_user) do
          {:ok, list} ->
            IO.puts(">> INVENTARIO DE RECURSOS DISPONIBLES:")
            Enum.each(list, fn r ->
              IO.puts("   [#{r.code}] #{r.name} - #{r.available} #{r.unit} (Ubicación: #{r.location})")
            end)
          err -> print_error(err)
        end
        loop(current_user)

      ["critical_resources"] ->
        case EmergencySystem.critical_resources(current_user, 10) do
          {:ok, list} ->
            IO.puts(">> RECURSOS CRÍTICOS (Stock <= 10):")
            Enum.each(list, fn r ->
              IO.puts("   ALERTA: [#{r.code}] #{r.name} - Solo #{r.available} #{r.unit} disponibles en #{r.location}")
            end)
          err -> print_error(err)
        end
        loop(current_user)

      ["transfer_resource", code, origin, target, qty] ->
        qty_num = String.to_integer(qty)
        case EmergencySystem.transfer_resource(current_user, code, origin, target, qty_num) do
          {:ok, :transferred, orig, dest} ->
            IO.puts(">> Transferencia exitosa de #{qty_num} unidades de #{code} desde '#{origin}' hacia '#{target}'.")
            IO.puts("   Stock origen: #{orig.available} | Stock destino: #{dest.available}")
          err -> print_error(err)
        end
        loop(current_user)

      ["report_person", doc, name, zone, status] ->
        case EmergencySystem.report_person(current_user, doc, name, 0, zone, status) do
          {:ok, p} -> IO.puts(">> Persona registrada: #{p.name} (Doc: #{p.document}) en Zona: #{p.zone} con Estado: #{p.status}")
          err -> print_error(err)
        end
        loop(current_user)

      ["find_person", doc] ->
        case EmergencySystem.find_person(current_user, doc) do
          {:ok, p} ->
            IO.puts("""
            >> PERSONA LOCALIZADA:
               Nombre: #{p.name} | Doc: #{p.document}
               Zona: #{p.zone} | Estado actual: #{p.status}
               Historial de cambios: #{length(p.history)} registros
            """)
          :error -> IO.puts(">> No se encontró registro para el documento #{doc}.")
          err -> print_error(err)
        end
        loop(current_user)

      ["send_family_message", doc, message] ->
        case EmergencySystem.send_family_message(current_user, doc, message) do
          {:ok, msg} -> IO.puts(">> Mensaje guardado para familiar #{doc} (ID mensaje: #{msg.id})")
          err -> print_error(err)
        end
        loop(current_user)

      ["list_family_messages", doc] ->
        case EmergencySystem.list_family_messages(current_user, doc) do
          {:ok, []} -> IO.puts(">> No hay mensajes registrados para el documento #{doc}.")
          {:ok, msgs} ->
            IO.puts(">> MENSAJES PARA FAMILIAR #{doc}:")
            Enum.each(msgs, &IO.puts("   [#{&1.status}] De: #{&1.sender}: \"#{&1.content}\""))
          err -> print_error(err)
        end
        loop(current_user)

      ["report_pet", type, species, name, color, size, zone, contact] ->
        case EmergencySystem.report_pet(current_user, type, species, name, "", color, size, zone, contact) do
          {:ok, pet} -> IO.puts(">> Reporte de mascota creado con ID #{pet.id} (#{pet.type} #{pet.species} '#{pet.name}')")
          err -> print_error(err)
        end
        loop(current_user)

      ["match_pets"] ->
        case EmergencySystem.match_pets(current_user, 50) do
          {:ok, []} -> IO.puts(">> No se encontraron posibles coincidencias de mascotas.")
          {:ok, matches} ->
            IO.puts(">> COINCIDENCIAS DE MASCOTAS DETECTADAS:")
            Enum.each(matches, fn m ->
              IO.puts("   * [#{m.score}%] #{m.lost_pet.name} (#{m.lost_pet.id}) <=> Encontrado #{m.found_pet.id} (#{m.found_pet.species}, #{m.found_pet.color}) en #{m.found_pet.zone}")
            end)
          err -> print_error(err)
        end
        loop(current_user)

      ["confirm_pet_match", lost_id, found_id] ->
        case EmergencySystem.confirm_pet_match(current_user, lost_id, found_id) do
          {:ok, lost, found} ->
            IO.puts(">> Coincidencia confirmada. Reportes #{lost.id} y #{found.id} marcados como RESUELTOS.")
          err -> print_error(err)
        end
        loop(current_user)

      ["register_shelter", code, name, zone, max_cap] ->
        cap_num = String.to_integer(max_cap)
        case EmergencySystem.register_shelter(current_user, code, name, zone, cap_num) do
          {:ok, s} -> IO.puts(">> Albergue registrado: [#{s.code}] #{s.name} (Capacidad: #{s.max_capacity})")
          err -> print_error(err)
        end
        loop(current_user)

      ["check_shelter", code] ->
        case EmergencySystem.check_shelter(current_user, code) do
          {:ok, s} ->
            IO.puts("""
            >> ALBERGUE [#{s.code}] #{s.name}
               Zona: #{s.zone}
               Ocupación: #{s.current_occupancy} / #{s.max_capacity}
               Cupos disponibles: #{s.available_spots}
            """)
          err -> print_error(err)
        end
        loop(current_user)

      ["register_entry", code, doc] ->
        case EmergencySystem.register_shelter_entry(current_user, code, doc) do
          {:ok, s} -> IO.puts(">> Ingreso registrado. Ocupación en #{s.name}: #{s.current_occupancy}/#{s.max_capacity}")
          err -> print_error(err)
        end
        loop(current_user)

      ["register_exit", code, doc] ->
        case EmergencySystem.register_shelter_exit(current_user, code, doc) do
          {:ok, s} -> IO.puts(">> Salida registrada. Ocupación en #{s.name}: #{s.current_occupancy}/#{s.max_capacity}")
          err -> print_error(err)
        end
        loop(current_user)

      ["summary"] ->
        res = EmergencySystem.summary(current_user)
        IO.inspect(res, label: ">> RESUMEN GLOBAL DEL SISTEMA")
        loop(current_user)

      _ ->
        IO.puts(">> Comando no reconocido o parámetros insuficientes. Escriba 'help' para ver ejemplos.")
        loop(current_user)
    end
  end

  defp parse_tokens(input) do
    Regex.scan(~r/"([^"]*)"|(\S+)/, input)
    |> Enum.map(fn
      [_, quoted] when quoted != "" -> quoted
      [_, _, unquoted] -> unquoted
      [token] -> token
    end)
  end

  defp parse_filter_pairs(tokens) do
    Enum.reduce(tokens, %{}, fn token, acc ->
      case String.split(token, "=", parts: 2) do
        [k, v] -> Map.put(acc, k, v)
        _ -> acc
      end
    end)
  end

  defp print_error({:error, reason}), do: IO.puts(">> ERROR: #{inspect(reason)}")
  defp print_error(other), do: IO.puts(">> ERROR: #{inspect(other)}")

  defp print_help do
    IO.puts("""
    COMANDOS DISPONIBLES:
      connect <usuario> <password> <rol> <zona>
      disconnect
      register_zone <codigo> <nombre> <nivel>
      add_sector <zona_code> <sector_name>
      add_point <zona_code> <sector_name> <punto_name> <afectados>
      zone_stats <zona_code>
      register_need <tipo> <cantidad> <prioridad> <zona> <descripcion>
      list_needs [zona=X] [prioridad=Y]
      pending_needs
      assign_resource <need_id> <recurso_codigo> <cantidad>
      register_resource <codigo> <nombre> <cantidad> <unidad> <ubicacion>
      list_resources
      critical_resources
      transfer_resource <codigo> <origen> <destino> <cantidad>
      report_person <documento> <nombre> <zona> <estado>
      find_person <documento>
      send_family_message <documento> "<mensaje>"
      list_family_messages <documento>
      report_pet <lost|found> <especie> <nombre> <color> <tamaño> <zona> <contacto>
      match_pets
      confirm_pet_match <lost_id> <found_id>
      register_shelter <codigo> "<nombre>" <zona> <capacidad_max>
      check_shelter <codigo>
      register_entry <albergue_codigo> <documento>
      register_exit <albergue_codigo> <documento>
      summary
      exit
    """)
  end
end
