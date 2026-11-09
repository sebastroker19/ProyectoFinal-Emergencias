defmodule EmergencySystem.Auth do
  @moduledoc """
  Gestión de usuarios, autenticación, autorización y registro de actividades.
  Cumple los requerimientos 1.4.1 y 1.4.2 del proyecto.
  """
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "users"
  @valid_roles ["ciudadano", "voluntario", "coordinador", "administrador"]

  defstruct users: %{}, active_sessions: %{}, activity_log: []

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Conecta a un usuario validando credenciales o registrándolo automáticamente si no existe.
  """
  def connect(username, password, role \\ "ciudadano", zone \\ "centro", full_name \\ "") do
    GenServer.call(__MODULE__, {:connect, username, password, role, zone, full_name})
  end

  @doc """
  Desconecta a un usuario activo.
  """
  def disconnect(username) do
    GenServer.call(__MODULE__, {:disconnect, username})
  end

  @doc """
  Verifica si el usuario tiene permiso para ejecutar una acción según sus roles requeridos.
  """
  def authorize(username, required_roles) do
    GenServer.call(__MODULE__, {:authorize, username, required_roles})
  end

  @doc """
  Registra la actividad realizada por un usuario.
  """
  def log_activity(username, action) do
    GenServer.cast(__MODULE__, {:log_activity, username, action})
  end

  @doc """
  Obtiene el usuario por nombre de usuario.
  """
  def get_user(username) do
    GenServer.call(__MODULE__, {:get_user, username})
  end

  @doc """
  Lista las sesiones activas en el sistema.
  """
  def list_active_sessions do
    GenServer.call(__MODULE__, :list_active_sessions)
  end

  @doc """
  Obtiene el historial de actividades (opcionalmente filtrado por usuario).
  """
  def get_activity_log(username \\ nil) do
    GenServer.call(__MODULE__, {:get_activity_log, username})
  end

  # Callbacks de GenServer
  @impl true
  def init(_) do
    persisted_users = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{users: persisted_users}}
  end

  @impl true
  def handle_call({:connect, username, password, role, zone, full_name}, _from, state) do
    role = if role in @valid_roles, do: role, else: "ciudadano"
    display_name = if full_name == "" or is_nil(full_name), do: username, else: full_name

    case Map.get(state.users, username) do
      nil ->
        # Registro automático cuando no existe
        new_user = %{
          username: username,
          password: password,
          full_name: display_name,
          role: role,
          zone: zone,
          created_at: DateTime.utc_now()
        }

        new_users = Map.put(state.users, username, new_user)
        new_sessions = Map.put(state.active_sessions, username, role)

        new_state = %{state | users: new_users, active_sessions: new_sessions}
        Persistence.save(@persistence_key, new_users)

        {:reply, {:ok, :registered_and_connected, role}, new_state}

      %{password: ^password, role: user_role} ->
        # Usuario existente con contraseña correcta
        new_sessions = Map.put(state.active_sessions, username, user_role)
        {:reply, {:ok, :connected, user_role}, %{state | active_sessions: new_sessions}}

      %{password: _wrong_pass} ->
        # Contraseña inválida
        {:reply, {:error, :invalid_credentials}, state}
    end
  end

  @impl true
  def handle_call({:disconnect, username}, _from, state) do
    new_sessions = Map.delete(state.active_sessions, username)
    {:reply, :ok, %{state | active_sessions: new_sessions}}
  end

  @impl true
  def handle_call({:authorize, username, required_roles}, _from, state) do
    case Map.get(state.active_sessions, username) do
      nil ->
        {:reply, {:error, :unauthenticated}, state}

      role ->
        if role in required_roles or role == "administrador" do
          {:reply, :ok, state}
        else
          {:reply, {:error, :unauthorized}, state}
        end
    end
  end

  @impl true
  def handle_call({:get_user, username}, _from, state) do
    case Map.get(state.users, username) do
      nil -> {:reply, {:error, :user_not_found}, state}
      user -> {:reply, {:ok, Map.drop(user, [:password])}, state}
    end
  end

  @impl true
  def handle_call(:list_active_sessions, _from, state) do
    {:reply, state.active_sessions, state}
  end

  @impl true
  def handle_call({:get_activity_log, nil}, _from, state) do
    {:reply, state.activity_log, state}
  end

  @impl true
  def handle_call({:get_activity_log, username}, _from, state) do
    filtered = Enum.filter(state.activity_log, &(&1.username == username))
    {:reply, filtered, state}
  end

  @impl true
  def handle_cast({:log_activity, username, action}, state) do
    entry = %{username: username, action: action, timestamp: DateTime.utc_now()}
    {:noreply, %{state | activity_log: [entry | state.activity_log]}}
  end
end
