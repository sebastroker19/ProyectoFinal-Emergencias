defmodule EmergencySystem.Auth do
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "users"

  defstruct users: %{}, active_sessions: %{}, activity_log: []

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def connect(username, password, role \\ "ciudadano", zone \\ "centro") do
    GenServer.call(__MODULE__, {:connect, username, password, role, zone})
  end

  def disconnect(username) do
    GenServer.call(__MODULE__, {:disconnect, username})
  end

  def authorize(username, required_roles) do
    GenServer.call(__MODULE__, {:authorize, username, required_roles})
  end

  def log_activity(username, action) do
    GenServer.cast(__MODULE__, {:log_activity, username, action})
  end

  # Callbacks de GenServer
  @impl true
  def init(_) do
    persisted_users = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{users: persisted_users}}
  end

  @impl true
  def handle_call({:connect, username, password, role, zone}, _from, state) do
    case Map.get(state.users, username) do
      nil ->
        new_user = %{
          username: username,
          password: password,
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
        new_sessions = Map.put(state.active_sessions, username, user_role)
        {:reply, {:ok, :connected, user_role}, %{state | active_sessions: new_sessions}}

      %{password: _wrong_pass} ->
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
        if role in required_roles or "administrador" == role do
          {:reply, :ok, state}
        else
          {:reply, {:error, :unauthorized}, state}
        end
    end
  end

  @impl true
  def handle_cast({:log_activity, username, action}, state) do
    entry = %{username: username, action: action, timestamp: DateTime.utc_now()}
    {:noreply, %{state | activity_log: [entry | state.activity_log]}}
  end
end
