defmodule EmergencySystem.ZoneManager do
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "zones"

  defstruct zones: %{}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_zone(code, name, level) when level in ["critico", "alto", "medio", "bajo"] do
    GenServer.call(__MODULE__, {:register_zone, code, name, level})
  end

  def add_sector(zone_code, sector_name) do
    GenServer.call(__MODULE__, {:add_sector, zone_code, sector_name})
  end

  def add_point_of_attention(zone_code, sector_name, point_name, affected_count) do
    GenServer.call(__MODULE__, {:add_point, zone_code, sector_name, point_name, affected_count})
  end

  def get_total_affected(zone_code) do
    GenServer.call(__MODULE__, {:get_total_affected, zone_code})
  end

  def get_zone(code) do
    GenServer.call(__MODULE__, {:get_zone, code})
  end

  # GenServer Callbacks
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{zones: persisted}}
  end

  @impl true
  def handle_call({:register_zone, code, name, level}, _from, state) do
    if Map.has_key?(state.zones, code) do
      {:reply, {:error, :already_exists}, state}
    else
      zone = %{code: code, name: name, level: level, sectors: %{}}
      new_zones = Map.put(state.zones, code, zone)
      Persistence.save(@persistence_key, new_zones)
      {:reply, {:ok, zone}, %{state | zones: new_zones}}
    end
  end

  @impl true
  def handle_call({:add_sector, zone_code, sector_name}, _from, state) do
    case Map.get(state.zones, zone_code) do
      nil -> {:reply, {:error, :zone_not_found}, state}
      zone ->
        updated_sectors = Map.put_new(zone.sectors, sector_name, %{points: []})
        updated_zone = %{zone | sectors: updated_sectors}
        new_zones = Map.put(state.zones, zone_code, updated_zone)
        Persistence.save(@persistence_key, new_zones)
        {:reply, {:ok, updated_zone}, %{state | zones: new_zones}}
    end
  end

  @impl true
  def handle_call({:add_point, zone_code, sector_name, point_name, count}, _from, state) do
    case Map.get(state.zones, zone_code) do
      nil -> {:reply, {:error, :zone_not_found}, state}
      zone ->
        case Map.get(zone.sectors, sector_name) do
          nil -> {:reply, {:error, :sector_not_found}, state}
          sector ->
            point = %{name: point_name, affected: count}
            updated_sector = %{sector | points: [point | sector.points]}
            updated_sectors = Map.put(zone.sectors, sector_name, updated_sector)
            updated_zone = %{zone | sectors: updated_sectors}
            new_zones = Map.put(state.zones, zone_code, updated_zone)
            Persistence.save(@persistence_key, new_zones)
            {:reply, {:ok, updated_zone}, %{state | zones: new_zones}}
        end
    end
  end

  @impl true
  def handle_call({:get_total_affected, zone_code}, _from, state) do
    case Map.get(state.zones, zone_code) do
      nil -> {:reply, {:error, :zone_not_found}, state}
      zone ->
        total = sum_zone_affected(Map.values(zone.sectors))
        {:reply, {:ok, total}, state}
    end
  end

  @impl true
  def handle_call({:get_zone, code}, _from, state) do
    {:reply, Map.fetch(state.zones, code), state}
  end

  # Algorithm Recursivo sobre la Estructura Jerárquica (Zona -> Sectores -> Puntos)
  defp sum_zone_affected([]), do: 0
  defp sum_zone_affected([sector | tail]) do
    sum_points(sector.points) + sum_zone_affected(tail)
  end

  defp sum_points([]), do: 0
  defp sum_points([%{affected: count} | tail]) do
    count + sum_points(tail)
  end
end
