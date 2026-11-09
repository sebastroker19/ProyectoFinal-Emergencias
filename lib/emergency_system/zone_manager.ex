defmodule EmergencySystem.ZoneManager do
  @moduledoc """
  Gestión jerárquica de zonas, sectores y puntos de atención.
  Cumple el requerimiento 1.4.3 y la regla de 4 funciones recursivas propias.
  Estructura: Zona -> Sectores -> Puntos de atención.
  """
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "zones"
  @valid_levels ["critico", "alto", "medio", "bajo"]

  defstruct zones: %{}

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_zone(code, name, level) when level in @valid_levels do
    GenServer.call(__MODULE__, {:register_zone, code, name, level})
  end

  def register_zone(_code, _name, level) do
    {:error, {:invalid_level, level, @valid_levels}}
  end

  def add_sector(zone_code, sector_name) do
    GenServer.call(__MODULE__, {:add_sector, zone_code, sector_name})
  end

  def add_point_of_attention(zone_code, sector_name, point_name, affected_count) when affected_count >= 0 do
    GenServer.call(__MODULE__, {:add_point, zone_code, sector_name, point_name, affected_count})
  end

  def add_point_of_attention(_zone_code, _sector_name, _point_name, _affected_count) do
    {:error, :invalid_negative_count}
  end

  def get_total_affected(zone_code) do
    GenServer.call(__MODULE__, {:get_total_affected, zone_code})
  end

  def get_zone(code) do
    GenServer.call(__MODULE__, {:get_zone, code})
  end

  def list_zones do
    GenServer.call(__MODULE__, :list_zones)
  end

  def zone_statistics(zone_code) do
    GenServer.call(__MODULE__, {:zone_statistics, zone_code})
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
      zone = %{
        code: code,
        name: name,
        level: level,
        sectors: %{},
        created_at: DateTime.utc_now()
      }

      new_zones = Map.put(state.zones, code, zone)
      Persistence.save(@persistence_key, new_zones)
      {:reply, {:ok, zone}, %{state | zones: new_zones}}
    end
  end

  @impl true
  def handle_call({:add_sector, zone_code, sector_name}, _from, state) do
    case Map.get(state.zones, zone_code) do
      nil ->
        {:reply, {:error, :zone_not_found}, state}

      zone ->
        updated_sectors = Map.put_new(zone.sectors, sector_name, %{name: sector_name, points: []})
        updated_zone = %{zone | sectors: updated_sectors}
        new_zones = Map.put(state.zones, zone_code, updated_zone)
        Persistence.save(@persistence_key, new_zones)
        {:reply, {:ok, updated_zone}, %{state | zones: new_zones}}
    end
  end

  @impl true
  def handle_call({:add_point, zone_code, sector_name, point_name, count}, _from, state) do
    case Map.get(state.zones, zone_code) do
      nil ->
        {:reply, {:error, :zone_not_found}, state}

      zone ->
        case Map.get(zone.sectors, sector_name) do
          nil ->
            {:reply, {:error, :sector_not_found}, state}

          sector ->
            point = %{name: point_name, affected: count, created_at: DateTime.utc_now()}
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
      nil ->
        {:reply, {:error, :zone_not_found}, state}

      zone ->
        total = sum_zone_affected(Map.values(zone.sectors))
        {:reply, {:ok, total}, state}
    end
  end

  @impl true
  def handle_call({:get_zone, code}, _from, state) do
    {:reply, Map.fetch(state.zones, code), state}
  end

  @impl true
  def handle_call(:list_zones, _from, state) do
    {:reply, Map.values(state.zones), state}
  end

  @impl true
  def handle_call({:zone_statistics, zone_code}, _from, state) do
    case Map.get(state.zones, zone_code) do
      nil ->
        {:reply, {:error, :zone_not_found}, state}

      zone ->
        sectors_list = Map.values(zone.sectors)
        total_affected = sum_zone_affected(sectors_list)
        total_points = count_total_points(sectors_list)
        critical_points = collect_critical_points(sectors_list, 50)

        stats = %{
          zone_code: zone.code,
          zone_name: zone.name,
          level: zone.level,
          total_sectors: length(sectors_list),
          total_points: total_points,
          total_affected: total_affected,
          critical_points_above_50: critical_points
        }

        {:reply, {:ok, stats}, state}
    end
  end

  # =========================================================================
  # ALGORITMOS RECURSIVOS SOBRE LA ESTRUCTURA JERÁRQUICA (RÚBRICA: 4 PROPIAS)
  # =========================================================================

  @doc """
  Función Recursiva 1: Recorre la lista de sectores sumando las personas afectadas
  en cada sector mediante paso recursivo.
  """
  def sum_zone_affected([]), do: 0
  def sum_zone_affected([sector | tail]) do
    sum_points(sector.points) + sum_zone_affected(tail)
  end

  @doc """
  Función Recursiva 2: Recorre la lista de puntos de atención dentro de un sector
  sumando el conteo de afectados.
  """
  def sum_points([]), do: 0
  def sum_points([%{affected: count} | tail]) do
    count + sum_points(tail)
  end

  @doc """
  Función Recursiva 3: Recorre recursivamente los sectores acumulando la cantidad
  total de puntos de atención registrados en la zona.
  """
  def count_total_points([]), do: 0
  def count_total_points([sector | tail]) do
    count_sector_points(sector.points) + count_total_points(tail)
  end

  defp count_sector_points([]), do: 0
  defp count_sector_points([_point | tail]), do: 1 + count_sector_points(tail)

  @doc """
  Función Recursiva 4: Recorre recursivamente sectores y puntos de atención
  filtrando y acumulando aquellos puntos cuya afectación supere un umbral crítico.
  """
  def collect_critical_points([], _threshold), do: []
  def collect_critical_points([sector | tail], threshold) do
    filter_points_above(sector.points, sector.name, threshold) ++
      collect_critical_points(tail, threshold)
  end

  defp filter_points_above([], _sector_name, _threshold), do: []
  defp filter_points_above([point | tail], sector_name, threshold) do
    if point.affected >= threshold do
      [Map.put(point, :sector, sector_name) | filter_points_above(tail, sector_name, threshold)]
    else
      filter_points_above(tail, sector_name, threshold)
    end
  end
end
