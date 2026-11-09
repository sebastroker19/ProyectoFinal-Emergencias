defmodule EmergencySystem.PetManager do
  @moduledoc """
  Gestión de mascotas perdidas y encontradas.
  Cumple el requerimiento 1.4.7: algoritmo de similitud con scoring,
  búsqueda de coincidencias, confirmación y cierre conjunto de reportes.
  """
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "pets"


  defstruct reports: %{}, counter: 1

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def report_pet(type, species, name, traits, color, size, zone, contact) do
    normalized_type =
      case String.downcase(to_string(type)) do
        "lost" -> "perdida"
        "found" -> "encontrada"
        other -> other
      end

    if normalized_type in ["perdida", "encontrada"] do
      GenServer.call(__MODULE__, {:report, normalized_type, species, name, traits, color, size, zone, contact})
    else
      {:error, {:invalid_pet_type, type}}
    end
  end

  def match_pets(min_score \\ 50) do
    GenServer.call(__MODULE__, {:match_pets, min_score})
  end

  def confirm_match(lost_id, found_id) do
    GenServer.call(__MODULE__, {:confirm_match, lost_id, found_id})
  end

  def get_report(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def list_reports(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list, filters})
  end

  # Callbacks de GenServer
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    count = map_size(persisted) + 1
    {:ok, %__MODULE__{reports: persisted, counter: count}}
  end

  @impl true
  def handle_call({:report, type, species, name, traits, color, size, zone, contact}, _from, state) do
    id = "PET" <> String.pad_leading("#{state.counter}", 3, "0")

    report = %{
      id: id,
      type: type,
      species: String.downcase(to_string(species)),
      name: to_string(name),
      traits: to_string(traits),
      color: String.downcase(to_string(color)),
      size: String.downcase(to_string(size)),
      zone: to_string(zone),
      contact: to_string(contact),
      status: "activa",
      resolved_with: nil,
      resolved_at: nil,
      created_at: DateTime.utc_now()
    }

    new_reports = Map.put(state.reports, id, report)
    new_state = %{state | reports: new_reports, counter: state.counter + 1}
    Persistence.save(@persistence_key, new_reports)

    {:reply, {:ok, report}, new_state}
  end

  @impl true
  def handle_call({:match_pets, min_score}, _from, state) do
    lost = Enum.filter(Map.values(state.reports), &(&1.type == "perdida" and &1.status != "resuelta"))
    found = Enum.filter(Map.values(state.reports), &(&1.type == "encontrada" and &1.status != "resuelta"))

    matches =
      for l <- lost, f <- found, score = calculate_score(l, f), score >= min_score do
        %{
          score: score,
          lost_pet: l,
          found_pet: f,
          summary: "Coincidencia del #{score}% entre #{l.name} (#{l.id}) y reporte #{f.id}"
        }
      end
      |> Enum.sort_by(& &1.score, :desc)

    {:reply, matches, state}
  end

  # =========================================================================
  # REGLA: Confirmar coincidencia y cerrar ambos reportes relacionados.
  # No se puede cerrar dos veces una necesidad o un reporte.
  # =========================================================================
  @impl true
  def handle_call({:confirm_match, lost_id, found_id}, _from, state) do
    case {Map.get(state.reports, lost_id), Map.get(state.reports, found_id)} do
      {nil, _} ->
        {:reply, {:error, :lost_pet_not_found}, state}

      {_, nil} ->
        {:reply, {:error, :found_pet_not_found}, state}

      {%{status: "resuelta"}, _} ->
        {:reply, {:error, :lost_pet_already_resolved}, state}

      {_, %{status: "resuelta"}} ->
        {:reply, {:error, :found_pet_already_resolved}, state}

      {lost_report, found_report} ->
        now = DateTime.utc_now()

        updated_lost = %{lost_report | status: "resuelta", resolved_with: found_id, resolved_at: now}
        updated_found = %{found_report | status: "resuelta", resolved_with: lost_id, resolved_at: now}

        new_reports =
          state.reports
          |> Map.put(lost_id, updated_lost)
          |> Map.put(found_id, updated_found)

        Persistence.save(@persistence_key, new_reports)
        {:reply, {:ok, updated_lost, updated_found}, %{state | reports: new_reports}}
    end
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, Map.fetch(state.reports, id), state}
  end

  @impl true
  def handle_call({:list, filters}, _from, state) do
    results =
      state.reports
      |> Map.values()
      |> Enum.filter(fn pet ->
        Enum.all?(filters, fn {k, v} ->
          k_atom = if is_binary(k), do: String.to_existing_atom(k), else: k
          to_string(Map.get(pet, k_atom)) == to_string(v)
        end)
      end)

    {:reply, results, state}
  end

  # Algoritmo de Coincidencia por Ponderación de Atributos
  defp calculate_score(lost, found) do
    score = 0

    # 1. Especie (30%)
    score = if String.downcase(lost.species) == String.downcase(found.species), do: score + 30, else: score

    # 2. Zona (25%)
    score = if String.downcase(lost.zone) == String.downcase(found.zone), do: score + 25, else: score

    # 3. Color (20%)
    score =
      if String.downcase(lost.color) == String.downcase(found.color) or
         String.contains?(String.downcase(found.color), String.downcase(lost.color)) do
        score + 20
      else
        score
      end

    # 4. Tamaño (15%)
    score = if String.downcase(lost.size) == String.downcase(found.size), do: score + 15, else: score

    # 5. Nombre (10%)
    score =
      if lost.name not in ["", "desconocido", nil] and
         String.downcase(lost.name) == String.downcase(found.name) do
        score + 10
      else
        score
      end

    score
  end
end
