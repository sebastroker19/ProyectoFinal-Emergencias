defmodule EmergencySystem.Shelter do
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "shelters"

  defstruct shelters: %{}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_shelter(code, name, zone, max_capacity) do
    GenServer.call(__MODULE__, {:register, code, name, zone, max_capacity})
  end

  def register_entry(shelter_code, person_doc) do
    GenServer.call(__MODULE__, {:entry, shelter_code, person_doc})
  end

  def register_exit(shelter_code, person_doc) do
    GenServer.call(__MODULE__, {:exit, shelter_code, person_doc})
  end

  def check_shelter(code) do
    GenServer.call(__MODULE__, {:check, code})
  end

  # Callbacks
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{shelters: persisted}}
  end

  @impl true
  def handle_call({:register, code, name, zone, max_capacity}, _from, state) do
    shelter = %{
      code: code,
      name: name,
      zone: zone,
      max_capacity: max_capacity,
      current_occupancy: 0,
      occupants: MapSet.new()
    }

    new_shelters = Map.put(state.shelters, code, shelter)
    Persistence.save(@persistence_key, new_shelters)
    {:reply, {:ok, shelter}, %{state | shelters: new_shelters}}
  end

  @impl true
  def handle_call({:entry, code, doc}, _from, state) do
    case Map.get(state.shelters, code) do
      nil ->
        {:reply, {:error, :shelter_not_found}, state}

      %{current_occupancy: occ, max_capacity: max} when occ >= max ->
        {:reply, {:error, :shelter_full}, state}

      shelter ->
        updated_occupants = MapSet.put(shelter.occupants, doc)
        updated = %{shelter | current_occupancy: MapSet.size(updated_occupants), occupants: updated_occupants}
        new_shelters = Map.put(state.shelters, code, updated)
        Persistence.save(@persistence_key, new_shelters)
        {:reply, {:ok, updated}, %{state | shelters: new_shelters}}
    end
  end

  @impl true
  def handle_call({:exit, code, doc}, _from, state) do
    case Map.get(state.shelters, code) do
      nil ->
        {:reply, {:error, :shelter_not_found}, state}

      shelter ->
        updated_occupants = MapSet.delete(shelter.occupants, doc)
        updated = %{shelter | current_occupancy: MapSet.size(updated_occupants), occupants: updated_occupants}
        new_shelters = Map.put(state.shelters, code, updated)
        Persistence.save(@persistence_key, new_shelters)
        {:reply, {:ok, updated}, %{state | shelters: new_shelters}}
    end
  end

  @impl true
  def handle_call({:check, code}, _from, state) do
    {:reply, Map.fetch(state.shelters, code), state}
  end
end
