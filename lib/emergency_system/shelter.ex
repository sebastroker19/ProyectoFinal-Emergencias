defmodule EmergencySystem.Shelter do
  @moduledoc """
  Gestión de albergues, control de aforo y cupos disponibles.
  Cumple el requerimiento 1.4.8: límites de capacidad máxima, ingreso/salida,
  asociación de recursos/necesidades y reporte de ocupación.
  """
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "shelters"

  defstruct shelters: %{}

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_shelter(code, name, zone, max_capacity) when is_number(max_capacity) and max_capacity > 0 do
    GenServer.call(__MODULE__, {:register, code, name, zone, max_capacity})
  end

  def register_shelter(_code, _name, _zone, _max_capacity) do
    {:error, :invalid_max_capacity}
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

  def associate_resource(shelter_code, resource_code, quantity) do
    GenServer.call(__MODULE__, {:associate_resource, shelter_code, resource_code, quantity})
  end

  def associate_need(shelter_code, need_id) do
    GenServer.call(__MODULE__, {:associate_need, shelter_code, need_id})
  end

  def occupancy_report do
    GenServer.call(__MODULE__, :occupancy_report)
  end

  def list_shelters do
    GenServer.call(__MODULE__, :list)
  end

  # Callbacks de GenServer
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{shelters: persisted}}
  end

  @impl true
  def handle_call({:register, code, name, zone, max_capacity}, _from, state) do
    case Map.get(state.shelters, code) do
      nil ->
        shelter = %{
          code: code,
          name: name,
          zone: zone,
          max_capacity: max_capacity,
          current_occupancy: 0,
          occupants: MapSet.new(),
          associated_resources: [],
          associated_needs: [],
          created_at: DateTime.utc_now()
        }

        new_shelters = Map.put(state.shelters, code, shelter)
        Persistence.save(@persistence_key, new_shelters)
        {:reply, {:ok, shelter}, %{state | shelters: new_shelters}}

      _already ->
        {:reply, {:error, :shelter_already_exists}, state}
    end
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
        new_count = MapSet.size(updated_occupants)
        updated = %{shelter | current_occupancy: new_count, occupants: updated_occupants}
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
        new_count = MapSet.size(updated_occupants)
        updated = %{shelter | current_occupancy: new_count, occupants: updated_occupants}
        new_shelters = Map.put(state.shelters, code, updated)
        Persistence.save(@persistence_key, new_shelters)
        {:reply, {:ok, updated}, %{state | shelters: new_shelters}}
    end
  end

  @impl true
  def handle_call({:check, code}, _from, state) do
    case Map.get(state.shelters, code) do
      nil ->
        {:reply, {:error, :shelter_not_found}, state}

      shelter ->
        available = max(0, shelter.max_capacity - shelter.current_occupancy)
        response = Map.put(shelter, :available_spots, available)
        {:reply, {:ok, response}, state}
    end
  end

  @impl true
  def handle_call({:associate_resource, code, res_code, qty}, _from, state) do
    case Map.get(state.shelters, code) do
      nil ->
        {:reply, {:error, :shelter_not_found}, state}

      shelter ->
        updated = %{shelter | associated_resources: [{res_code, qty, DateTime.utc_now()} | shelter.associated_resources]}
        new_shelters = Map.put(state.shelters, code, updated)
        Persistence.save(@persistence_key, new_shelters)
        {:reply, {:ok, updated}, %{state | shelters: new_shelters}}
    end
  end

  @impl true
  def handle_call({:associate_need, code, need_id}, _from, state) do
    case Map.get(state.shelters, code) do
      nil ->
        {:reply, {:error, :shelter_not_found}, state}

      shelter ->
        updated = %{shelter | associated_needs: [need_id | shelter.associated_needs]}
        new_shelters = Map.put(state.shelters, code, updated)
        Persistence.save(@persistence_key, new_shelters)
        {:reply, {:ok, updated}, %{state | shelters: new_shelters}}
    end
  end

  @impl true
  def handle_call(:occupancy_report, _from, state) do
    report =
      state.shelters
      |> Map.values()
      |> Enum.map(fn s ->
        pct = if s.max_capacity > 0, do: Float.round((s.current_occupancy / s.max_capacity) * 100, 1), else: 0.0
        available = max(0, s.max_capacity - s.current_occupancy)

        %{
          code: s.code,
          name: s.name,
          zone: s.zone,
          max_capacity: s.max_capacity,
          current_occupancy: s.current_occupancy,
          available_spots: available,
          occupancy_percentage: pct
        }
      end)
      |> Enum.sort_by(& &1.occupancy_percentage, :desc)

    {:reply, report, state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, Map.values(state.shelters), state}
  end
end
