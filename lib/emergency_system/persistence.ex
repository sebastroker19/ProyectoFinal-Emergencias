defmodule EmergencySystem.Persistence do
  @moduledoc """
  Módulo de persistencia en archivos de texto plano (.txt).
  Almacena las estructuras de datos formateadas en texto plano legible
  cumpliendo el requerimiento 1.4.9 del proyecto.
  """

  @data_dir "data"

  @doc """
  Guarda un término Elixir en un archivo de texto plano legible.
  """
  def save(filename, data) do
    File.mkdir_p!(@data_dir)
    path = Path.join(@data_dir, "#{filename}.txt")

    content = inspect(data, pretty: true, limit: :infinity, printable_limit: :infinity)
    File.write!(path, content)
  end

  @doc """
  Carga un término Elixir desde un archivo de texto plano.
  Si el archivo no existe o contiene un error, retorna el valor default.
  """
  def load(filename, default) do
    path = Path.join(@data_dir, "#{filename}.txt")

    if File.exists?(path) do
      case File.read(path) do
        {:ok, content} ->
          trimmed = String.trim(content)

          if trimmed == "" do
            default
          else
            try do
              {term, _bindings} = Code.eval_string(trimmed)
              term
            rescue
              _ -> default
            end
          end

        _ ->
          default
      end
    else
      default
    end
  end
end
