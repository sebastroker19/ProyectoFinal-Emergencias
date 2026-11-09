defmodule EmergencySystem.ResourceManager do
  @moduledoc """
  Gestión de inventario de recursos en centros de acopio y puntos de atención.
  Garantiza consistencia y atocimidad concurrente (requerimiento 1.4.5 y regla obligatoria de concurrencia).
  """
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "resources"

  defstruct resources: %{}, history: []

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_resource(code, name, category, quantity, unit, location) when is_number(quantity) and quantity >= 0 do
    GenServer.call(__MODULE__, {:register, code, name, category, quantity, unit, location})
  end

  def register_resource(_code, _name, _category, _quantity, _unit, _location) do
    {:error, :invalid_negative_quantity}
  end

  def deduct_resource(code, quantity) when is_number(quantity) and quantity > 0 do
    GenServer.call(__MODULE__, {:deduct, code, quantity})
  end

  def deduct_resource(_code, _quantity) do
    {:error, :invalid_quantity}
  end

  def transfer_resource(code, origin_loc, target_loc, quantity) when is_number(quantity) and quantity > 0 do
    GenServer.call(__MODULE__, {:transfer, code, origin_loc, target_loc, quantity})
  end

  def transfer_resource(_code, _origin_loc, _target_loc, _quantity) do
    {:error, :invalid_quantity}
  end

  def list_resources(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list, filters})
  end

  def get_resource(code) do
    GenServer.call(__MODULE__, {:get, code})
  end

  def get_critical_resources(threshold \\ 10) do
    GenServer.call(__MODULE__, {:get_critical, threshold})
  end

  def get_history(code \\ nil) do
    GenServer.call(__MODULE__, {:get_history, code})
  end

  # Callbacks de GenServer
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
          location: location,
          created_at: DateTime.utc_now()
        }

        new_resources = Map.put(state.resources, code, resource)
        log = %{type: :entry, code: code, amount: quantity, location: location, timestamp: DateTime.utc_now()}

        new_state = %{state | resources: new_resources, history: [log | state.history]}
        Persistence.save(@persistence_key, new_resources)
        {:reply, {:ok, resource}, new_state}

      existing ->
        # Entrada de inventario al recurso existente
        updated = %{existing | available: existing.available + quantity, location: location}
        new_resources = Map.put(state.resources, code, updated)
        log = %{type: :entry, code: code, amount: quantity, location: location, timestamp: DateTime.utc_now()}

        new_state = %{state | resources: new_resources, history: [log | state.history]}
        Persistence.save(@persistence_key, new_resources)
        {:reply, {:ok, updated}, new_state}
    end
  end

  # =========================================================================
  # REGLA DE CONCURRENCIA OBLIGATORIA:
  # El GenServer procesa mensajes de forma atómica y secuencial por su mailbox,
  # evitando carreras de inventario y sobreasignaciones en ambientes paralelos.
  # =========================================================================
  @impl true
  def handle_call({:deduct, code, quantity}, _from, state) do
    case Map.get(state.resources, code) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{available: available} when available < quantity ->
        {:reply, {:error, {:insufficient_inventory, available: available, requested: quantity}}, state}

      resource ->
        updated = %{resource | available: resource.available - quantity}
        new_resources = Map.put(state.resources, code, updated)
        log = %{type: :exit, code: code, amount: quantity, location: resource.location, timestamp: DateTime.utc_now()}

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

      %{location: origin_location, available: available} = resource when available >= quantity ->
        # Si la ubicación coincide o permitimos transferir desde su ubicación actual
        if origin_location != origin do
          {:reply, {:error, {:wrong_origin_location, actual: origin_location, expected: origin}}, state}
        else
          updated = %{resource | available: resource.available - quantity}
          target_code = "#{code}_#{target}"

          target_resource =
            Map.get(state.resources, target_code, %{
              code: target_code,
              name: resource.name,
              category: resource.category,
              available: 0,
              unit: resource.unit,
              location: target,
              created_at: DateTime.utc_now()
            })

          updated_target = %{target_resource | available: target_resource.available + quantity}

          new_resources =
            state.resources
            |> Map.put(code, updated)
            |> Map.put(target_code, updated_target)

          log = %{type: :transfer, code: code, from: origin, to: target, amount: quantity, timestamp: DateTime.utc_now()}
          new_state = %{state | resources: new_resources, history: [log | state.history]}
          Persistence.save(@persistence_key, new_resources)

          {:reply, {:ok, :transferred, updated, updated_target}, new_state}
        end

      %{available: available} ->
        {:reply, {:error, {:insufficient_inventory, available: available, requested: quantity}}, state}
    end
  end

  @impl true
  def handle_call({:list, filters}, _from, state) do
    filtered =
      state.resources
      |> Map.values()
      |> Enum.filter(fn r ->
        Enum.all?(filters, fn {k, v} ->
          k_atom = if is_binary(k), do: String.to_existing_atom(k), else: k
          Map.get(r, k_atom) == v
        end)
      end)

    {:reply, filtered, state}
  end

  @impl true
  def handle_call({:get, code}, _from, state) do
    {:reply, Map.fetch(state.resources, code), state}
  end

  @impl true
  def handle_call({:get_critical, threshold}, _from, state) do
    critical =
      state.resources
      |> Map.values()
      |> Enum.filter(&(&1.available <= threshold))
      |> Enum.sort_by(& &1.available)

    {:reply, critical, state}
  end

  @impl true
  def handle_call({:get_history, nil}, _from, state) do
    {:reply, state.history, state}
  end

  @impl true
  def handle_call({:get_history, code}, _from, state) do
    filtered = Enum.filter(state.history, &(&1.code == code))
    {:reply, filtered, state}
  end
end
