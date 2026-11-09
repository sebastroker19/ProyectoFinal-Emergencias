defmodule EmergencySystem.ResourceManager do
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "resources"

  defstruct resources: %{}, history: []

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_resource(code, name, category, quantity, unit, location) when quantity >= 0 do
    GenServer.call(__MODULE__, {:register, code, name, category, quantity, unit, location})
  end

  def deduct_resource(code, quantity) when quantity > 0 do
    GenServer.call(__MODULE__, {:deduct, code, quantity})
  end

  def transfer_resource(code, origin_loc, target_loc, quantity) when quantity > 0 do
    GenServer.call(__MODULE__, {:transfer, code, origin_loc, target_loc, quantity})
  end

  def list_resources do
    GenServer.call(__MODULE__, :list)
  end

  def get_critical_resources(threshold \\ 10) do
    GenServer.call(__MODULE__, {:get_critical, threshold})
  end

  # GenServer Callbacks
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{resources: persisted}}
  end

  @impl true
  def handle_call({:register, code, name, category, quantity, unit, location}, _from, state) do
    case Map.get(state.resources, code) do
      nil ->
        resource = %{
          code: code,
          name: name,
          category: category,
          available: quantity,
          unit: unit,
          location: location
        }
        new_resources = Map.put(state.resources, code, resource)
        log = %{type: :entry, code: code, amount: quantity, timestamp: DateTime.utc_now()}

        new_state = %{state | resources: new_resources, history: [log | state.history]}
        Persistence.save(@persistence_key, new_resources)
        {:reply, {:ok, resource}, new_state}

      existing ->
        updated = %{existing | available: existing.available + quantity}
        new_resources = Map.put(state.resources, code, updated)
        log = %{type: :entry, code: code, amount: quantity, timestamp: DateTime.utc_now()}

        new_state = %{state | resources: new_resources, history: [log | state.history]}
        Persistence.save(@persistence_key, new_resources)
        {:reply, {:ok, updated}, new_state}
    end
  end

  # ATÓMICO: Evita sobreasignaciones en ambientes concurrentes
  @impl true
  def handle_call({:deduct, code, quantity}, _from, state) do
    case Map.get(state.resources, code) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{available: available} when available < quantity ->
        {:reply, {:error, :insufficient_inventory, available: available}, state}

      resource ->
        updated = %{resource | available: resource.available - quantity}
        new_resources = Map.put(state.resources, code, updated)
        log = %{type: :exit, code: code, amount: quantity, timestamp: DateTime.utc_now()}

        new_state = %{state | resources: new_resources, history: [log | state.history]}
        Persistence.save(@persistence_key, new_resources)
        {:reply, {:ok, updated}, new_state}
    end
  end

  @impl true
  def handle_call({:transfer, code, origin, target, quantity}, _from, state) do
    case Map.get(state.resources, code) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{location: ^origin, available: available} = resource when available >= quantity ->
        updated = %{resource | available: resource.available - quantity}
        target_code = "#{code}_#{target}"

        target_resource =
          Map.get(state.resources, target_code, %{
            code: target_code,
            name: resource.name,
            category: resource.category,
            available: 0,
            unit: resource.unit,
            location: target
          })

        updated_target = %{target_resource | available: target_resource.available + quantity}

        new_resources =
          state.resources
          |> Map.put(code, updated)
          |> Map.put(target_code, updated_target)

        log = %{type: :transfer, code: code, from: origin, to: target, amount: quantity}
        new_state = %{state | resources: new_resources, history: [log | state.history]}
        Persistence.save(@persistence_key, new_resources)

        {:reply, {:ok, :transferred}, new_state}

      %{available: available} ->
        {:reply, {:error, :insufficient_inventory, available: available}, state}
    end
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, Map.values(state.resources), state}
  end

  @impl true
  def handle_call({:get_critical, threshold}, _from, state) do
    critical =
      state.resources
      |> Map.values()
      |> Enum.filter(&(&1.available <= threshold))
    {:reply, critical, state}
  end
end
