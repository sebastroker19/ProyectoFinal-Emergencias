defmodule EmergencySystem.PetManager do
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "pets"

  defstruct reports: %{}, counter: 1

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def report_pet(type, species, name, traits, color, size, zone, contact) do
    GenServer.call(__MODULE__, {:report, type, species, name, traits, color, size, zone, contact})
  end

  def match_pets do
    GenServer.call(__MODULE__, :match_pets)
  end

  # Callbacks
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{reports: persisted, counter: Map.size(persisted) + 1}}
  end

  @impl true
  def handle_call({:report, type, species, name, traits, color, size, zone, contact}, _from, state) do
    id = "PET" <> String.pad_leading("#{state.counter}", 3, "0")

    report = %{
      id: id,
      type: type, # "perdida" o "encontrada"
      species: species,
      name: name,
      traits: traits,
      color: color,
      size: size,
      zone: zone,
      contact: contact,
      status: "activa"
    }

    new_reports = Map.put(state.reports, id, report)
    new_state = %{state | reports: new_reports, counter: state.counter + 1}
    Persistence.save(@persistence_key, new_reports)

    {:reply, {:ok, report}, new_state}
  end

  @impl true
  def handle_call(:match_pets, _from, state) do
    lost = Enum.filter(Map.values(state.reports), &(&1.type == "perdida" and &1.status == "activa"))
    found = Enum.filter(Map.values(state.reports), &(&1.type == "encontrada" and &1.status == "activa"))

    matches =
      for l <- lost, f <- found, score = calculate_score(l, f), score >= 60 do
        {score, l, f}
      end
      |> Enum.sort_by(fn {score, _, _} -> score end, :desc)

    {:reply, matches, state}
  end

  # Algoritmo de Coincidencia por Scoring de Atributos
  defp calculate_score(lost, found) do
    score = 0

    score = if lost.species == found.species, do: score + 30, else: score
    score = if lost.zone == found.zone, do: score + 25, else: score
    score = if lost.color == found.color, do: score + 20, else: score
    score = if lost.size == found.size, do: score + 15, else: score
    score = if lost.name != "desconocido" and lost.name == found.name, do: score + 10, else: score

    score
  end
end
