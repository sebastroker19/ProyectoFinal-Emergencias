defmodule EmergencySystem.PersonManager do
  @moduledoc """
  Comunicación entre familiares, registro de personas afectadas y mensajes.
  Cumple el requerimiento 1.4.6: seguimiento de estado, historial, búsqueda
  y mensajería entre familiares.
  """
  use GenServer
  alias EmergencySystem.Persistence

  @people_key "people"
  @messages_key "family_messages"
  @valid_statuses ["sin_informacion", "reportada", "localizada", "trasladada", "en_albergue", "reunificada"]

  defstruct people: %{}, messages: []

  # API Pública
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def report_person(document, name, age \\ 0, zone \\ "desconocida", status \\ "reportada") do
    GenServer.call(__MODULE__, {:report, document, name, age, zone, status})
  end

  def find_person(document) do
    GenServer.call(__MODULE__, {:find, document})
  end

  def search_people(filters \\ %{}) do
    GenServer.call(__MODULE__, {:search, filters})
  end

  def update_person_status(document, status, zone \\ nil) do
    GenServer.call(__MODULE__, {:update_status, document, status, zone})
  end

  def send_message(document, sender, content) do
    GenServer.call(__MODULE__, {:send_message, document, sender, content})
  end

  def list_messages(document) do
    GenServer.call(__MODULE__, {:list_messages, document})
  end

  def mark_message_delivered(message_id) do
    GenServer.call(__MODULE__, {:mark_message, message_id, "entregado"})
  end

  def mark_message_status(message_id, status) do
    GenServer.call(__MODULE__, {:mark_message, message_id, status})
  end

  # Callbacks de GenServer
  @impl true
  def init(_) do
    persisted_people = Persistence.load(@people_key, %{})
    persisted_messages = Persistence.load(@messages_key, [])
    {:ok, %__MODULE__{people: persisted_people, messages: persisted_messages}}
  end

  @impl true
  def handle_call({:report, doc, name, age, zone, status}, _from, state) do
    now = DateTime.utc_now()
    valid_status = if status in @valid_statuses, do: status, else: "reportada"

    case Map.get(state.people, doc) do
      nil ->
        person = %{
          document: doc,
          name: name,
          age: age,
          zone: zone,
          status: valid_status,
          history: [%{status: valid_status, zone: zone, timestamp: now}],
          created_at: now
        }

        new_people = Map.put(state.people, doc, person)
        Persistence.save(@people_key, new_people)
        {:reply, {:ok, person}, %{state | people: new_people}}

      existing ->
        updated = %{
          existing |
          name: if(name != "", do: name, else: existing.name),
          age: if(age > 0, do: age, else: existing.age),
          zone: zone,
          status: valid_status,
          history: [%{status: valid_status, zone: zone, timestamp: now} | existing.history]
        }

        new_people = Map.put(state.people, doc, updated)
        Persistence.save(@people_key, new_people)
        {:reply, {:ok, updated}, %{state | people: new_people}}
    end
  end

  @impl true
  def handle_call({:find, doc}, _from, state) do
    {:reply, Map.fetch(state.people, doc), state}
  end

  @impl true
  def handle_call({:search, filters}, _from, state) do
    results =
      state.people
      |> Map.values()
      |> Enum.filter(fn person ->
        Enum.all?(filters, fn {k, v} ->
          k_atom = if is_binary(k), do: String.to_existing_atom(k), else: k
          actual_val = Map.get(person, k_atom)

          if is_binary(actual_val) and is_binary(v) do
            String.contains?(String.downcase(actual_val), String.downcase(v))
          else
            to_string(actual_val) == to_string(v)
          end
        end)
      end)

    {:reply, results, state}
  end

  @impl true
  def handle_call({:update_status, doc, new_status, new_zone}, _from, state) do
    case Map.get(state.people, doc) do
      nil ->
        {:reply, {:error, :person_not_found}, state}

      existing ->
        now = DateTime.utc_now()
        target_zone = new_zone || existing.zone

        updated = %{
          existing |
          status: new_status,
          zone: target_zone,
          history: [%{status: new_status, zone: target_zone, timestamp: now} | existing.history]
        }

        new_people = Map.put(state.people, doc, updated)
        Persistence.save(@people_key, new_people)
        {:reply, {:ok, updated}, %{state | people: new_people}}
    end
  end

  @impl true
  def handle_call({:send_message, doc, sender, content}, _from, state) do
    msg = %{
      id: :erlang.unique_integer([:positive]),
      recipient_doc: doc,
      sender: sender,
      content: content,
      status: "pendiente",
      timestamp: DateTime.utc_now()
    }

    new_messages = [msg | state.messages]
    Persistence.save(@messages_key, new_messages)
    {:reply, {:ok, msg}, %{state | messages: new_messages}}
  end

  @impl true
  def handle_call({:list_messages, doc}, _from, state) do
    msgs = Enum.filter(state.messages, &(&1.recipient_doc == doc))
    {:reply, msgs, state}
  end

  @impl true
  def handle_call({:mark_message, message_id, new_status}, _from, state) do
    found = Enum.find(state.messages, &(&1.id == message_id))

    case found do
      nil ->
        {:reply, {:error, :message_not_found}, state}

      _msg ->
        updated_messages =
          Enum.map(state.messages, fn m ->
            if m.id == message_id, do: %{m | status: new_status}, else: m
          end)

        Persistence.save(@messages_key, updated_messages)
        {:reply, :ok, %{state | messages: updated_messages}}
    end
  end
end
