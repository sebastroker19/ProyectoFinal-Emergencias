defmodule EmergencySystem.Persistence do
  @moduledoc """
  Modulo de persistencia en archivos de texto plano (.txt).
  """

  @data_dir "data"

  def save(filename, data) do
    File.mkdir_p!(@data_dir)
    path = Path.join(@data_dir, "#{filename}.txt")
    
    encoded = 
      data
      |> :erlang.term_to_binary()
      |> Base64.encode64()

    File.write(path, encoded)
  end

  def load(filename, default) do
    path = Path.join(@data_dir, "#{filename}.txt")

    if File.exists?(path) do
      case File.read(path) do
        {:ok, content} ->
          case Base64.decode(String.trim(content)) do
            {:ok, binary} ->
              try do
                :erlang.binary_to_term(binary)
              rescue
                _ -> default
              end
            _ -> default
          end
        _ -> default
      end
    else
      default
    end
  end
end