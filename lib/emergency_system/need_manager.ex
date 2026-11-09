defmodule EmergencySystem.NeedManager do
  @moduledoc """
  Gestión de solicitudes de ayuda y necesidades puntuales.
  Cumple el requerimiento 1.4.4: priorización, transiciones de estado,
  asignación de recursos y prevención de doble consumo/cierre.
  """
  use GenServer
  alias EmergencySystem.Persistence
  alias EmergencySystem.ResourceManager

  @persistence_key "needs"
  @valid_statuses ["pendiente", "asignada", "en_atencion", "atendida", "cancelada"]
  @valid_priorities ["critica", "alta", "media", "baja"]
  @priority_weight %{"critica" => 4, "alta" => 3, "media" => 2, "baja" => 1}

  defstruct needs: %{}, counter: 1

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_need(type, quantity, priority, zone, description, reporter)
      when is_number(quantity) and quantity > 0 and priority in @valid_priorities do
    GenServer.call(__MODULE__, {:register, type, quantity, priority, zone, description, reporter})
  end

  def register_need(_type, _qty, _prio, _zone, _desc, _reporter) do
    {:error, :invalid_need_parameters}
  end

  def assign_resources(need_id, resource_code, quantity) when is_number(quantity) and quantity > 0 do
    GenServer.call(__MODULE__, {:assign_resource, need_id, resource_code, quantity})
  end

  def assign_resources(_need_id, _resource_code, _quantity) do
    {:error, :invalid_quantity}
  end

  def update_status(need_id, new_status) when new_status in @valid_statuses do
    GenServer.call(__MODULE__, {:update_status, need_id, new_status})
  end

  def update_status(_need_id, invalid_status) do
    {:error, {:invalid_status, invalid_status, @valid_statuses}}
  end

  def get_need(need_id) do
    GenServer.call(__MODULE__, {:get, need_id})
  end

  def list_needs(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list, filters})
  end

  # Callbacks de GenServer
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    count = map_size(persisted) + 1
    {:ok, %__MODULE__{needs: persisted, counter: count}}
  end

  @impl true
  def handle_call({:register, type, quantity, priority, zone, description, reporter}, _from, state) do
    id = "N" <> String.pad_leading("#{state.counter}", 3, "0")

    need = %{
      id: id,
      type: type,
      quantity: quantity,
      remaining_quantity: quantity,
      priority: priority,
      zone: zone,
      description: description,
      reporter: reporter,
      status: "pendiente",
      assigned_resources: [],
      created_at: DateTime.utc_now()
    }

    new_needs = Map.put(state.needs, id, need)
    new_state = %{state | needs: new_needs, counter: state.counter + 1}
    Persistence.save(@persistence_key, new_needs)

    {:reply, {:ok, need}, new_state}
  end

  @impl true
  def handle_call({:assign_resource, need_id, resource_code, quantity}, _from, state) do
    case Map.get(state.needs, need_id) do
      nil ->
        {:reply, {:error, :need_not_found}, state}

      %{status: status} when status in ["atendida", "cancelada"] ->
        # Regla: Evitar que una necesidad atendida o cerrada vuelva a consumir recursos
        {:reply, {:error, :need_already_closed}, state}

      need ->
        case ResourceManager.deduct_resource(resource_code, quantity) do
          {:ok, _resource} ->
            new_remaining = max(0, need.remaining_quantity - quantity)
            new_status = if new_remaining == 0, do: "atendida", else: "en_atencion"

            updated_need = %{
              need |
              remaining_quantity: new_remaining,
              status: new_status,
              assigned_resources: [{resource_code, quantity, DateTime.utc_now()} | need.assigned_resources]
            }

            new_needs = Map.put(state.needs, need_id, updated_need)
            Persistence.save(@persistence_key, new_needs)
            {:reply, {:ok, updated_need}, %{state | needs: new_needs}}

          error ->
            {:reply, error, state}
        end
    end
  end

  @impl true
  def handle_call({:update_status, need_id, new_status}, _from, state) do
    case Map.get(state.needs, need_id) do
      nil ->
        {:reply, {:error, :need_not_found}, state}

      %{status: status} when status in ["atendida", "cancelada"] ->
        {:reply, {:error, :cannot_change_closed_need}, state}

      need ->
        updated_need = %{need | status: new_status}
        new_needs = Map.put(state.needs, need_id, updated_need)
        Persistence.save(@persistence_key, new_needs)
        {:reply, {:ok, updated_need}, %{state | needs: new_needs}}
    end
  end

  @impl true
  def handle_call({:get, need_id}, _from, state) do
    {:reply, Map.fetch(state.needs, need_id), state}
  end

  @impl true
  def handle_call({:list, filters}, _from, state) do
    result =
      state.needs
      |> Map.values()
      |> filter_needs(filters)
      |> sort_by_priority()

    {:reply, result, state}
  end

  defp filter_needs(needs, filters) do
    Enum.filter(needs, fn need ->
      Enum.all?(filters, fn {k, v} ->
        k_key = if is_binary(k), do: String.to_existing_atom(k), else: k
        to_string(Map.get(need, k_key)) == to_string(v)
      end)
    end)
  end

  defp sort_by_priority(needs) do
    Enum.sort_by(needs, &Map.get(@priority_weight, &1.priority, 0), :desc)
  end
end
