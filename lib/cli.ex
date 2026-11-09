defmodule EmergencySystem.CLI do
  def main(_args \\ []) do
    {:ok, _} = EmergencySystem.Supervisor.start_link([])
    IO.puts("=== SISTEMA DISTRIBUIDO DE GESTIÓN DE EMERGENCIAS (ELIXIR) ===")
    loop(nil)
  end

  defp loop(current_user) do
    prompt = if current_user, do: "#{current_user}> ", else: "invitado> "
    input = IO.gets(prompt) |> to_string() |> String.trim()

    case String.split(input) do
      ["connect", user, pass, role, zone] ->
        case EmergencySystem.connect(user, pass, role, zone) do
          {:ok, _, _} ->
            IO.puts("Conectado exitosamente como #{user}")
            loop(user)
          {:error, reason} ->
            IO.puts("Error al conectar: #{inspect(reason)}")
            loop(current_user)
        end

      ["disconnect"] ->
        if current_user, do: EmergencySystem.disconnect(current_user)
        IO.puts("Desconectado.")
        loop(nil)

      ["register_need", type, qty, priority, zone | desc_words] ->
        desc = Enum.join(desc_words, " ")
        qty_num = String.to_integer(qty)
        case EmergencySystem.register_need(current_user, type, qty_num, priority, zone, desc) do
          {:ok, need} -> IO.puts("Necesidad registrada con ID: #{need.id}")
          err -> IO.puts("Error: #{inspect(err)}")
        end
        loop(current_user)

      ["register_resource", code, name, qty, unit, location] ->
        qty_num = String.to_integer(qty)
        case EmergencySystem.register_resource(current_user, code, name, "general", qty_num, unit, location) do
          {:ok, res} -> IO.puts("Recurso #{res.code} registrado.")
          err -> IO.puts("Error: #{inspect(err)}")
        end
        loop(current_user)

      ["assign_resource", need_id, resource_code, qty] ->
        qty_num = String.to_integer(qty)
        case EmergencySystem.assign_resource(current_user, need_id, resource_code, qty_num) do
          {:ok, need} -> IO.puts("Recurso asignado a necesidad #{need.id}.")
          err -> IO.puts("Error asignando recurso: #{inspect(err)}")
        end
        loop(current_user)

      ["summary"] ->
        res = EmergencySystem.summary(current_user)
        IO.inspect(res, label: "RESUMEN DEL SISTEMA")
        loop(current_user)

      ["exit"] ->
        IO.puts("Cerrando sistema...")

      _ ->
        IO.puts("Comando no reconocido o parámetros insuficientes.")
        loop(current_user)
    end
  end
end
