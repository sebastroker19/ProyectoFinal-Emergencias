defmodule EmergencySystem.NeedManager do
  use GenServer
  alias EmergencySystem.Persistence
  alias EmergencySystem.ResourceManager

  @persistence_key "needs"
  @valid_statuses ["pendiente", "asignada", "en_atencion", "atendida", "cancelada"]
  @priority_weight %{"critica" => 4, "alta" => 3, "media" => 2, "baja" => 1}

  defstruct needs: %{}, counter: 1

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_need(type, quantity, priority, zone, description, reporter) do
    GenServer.call(__MODULE__, {:register, type, quantity, priority, zone, description, reporter})
  end

  def assign_resources(need_id, resource_code, quantity) do
    GenServer.call(__MODULE__, {:assign_resource, need_id, resource_code, quantity})
  end

  def list_needs(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list, filters})
  end

  # GenServer Callbacks
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{needs: persisted, counter: Map.size(persisted) + 1}}
  end

  @impl true
  def handle_call({:register, type, quantity, priority, zone, description, reporter}, _from, state) do
    id = "N" <> String.pad_leading("#{state.counter}", 3, "0")

    need = %{
      id: id,
      type: type,
      quantity: quantity,
      priority: priority,
      zone: zone,
      description: description,
      reporter: reporter,
      status: "pendiente",
      assigned_resources: []
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
        {:reply, {:error, :need_already_closed}, state}

      need ->
        case ResourceManager.deduct_resource(resource_code, quantity) do
          {:ok, _resource} ->
            updated_need = %{need | status: "atendida", assigned_resources: [{resource_code, quantity} | need.assigned_resources]}
            new_needs = Map.put(state.needs, need_id, updated_need)
            Persistence.save(@persistence_key, new_needs)
            {:reply, {:ok, updated_need}, %{state | needs: new_needs}}

          error ->
            {:reply, error, state}
        end
    end
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
      Enum.all?(filters, fn {k, v} -> Map.get(need, k) == v end)
    end)
  end

  defp sort_by_priority(needs) do
    Enum.sort_by(needs, &Map.get(@priority_weight, &1.priority, 0), :desc)
  end
end
