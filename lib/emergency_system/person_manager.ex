defmodule EmergencySystem.PersonManager do
  use GenServer
  alias EmergencySystem.Persistence

  @persistence_key "people"

  defstruct people: %{}, messages: []

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def report_person(document, name, zone, status) do
    GenServer.call(__MODULE__, {:report, document, name, zone, status})
  end

  def find_person(document) do
    GenServer.call(__MODULE__, {:find, document})
  end

  def send_message(document, sender, content) do
    GenServer.call(__MODULE__, {:send_message, document, sender, content})
  end

  def list_messages(document) do
    GenServer.call(__MODULE__, {:list_messages, document})
  end

  # Callbacks
  @impl true
  def init(_) do
    persisted = Persistence.load(@persistence_key, %{})
    {:ok, %__MODULE__{people: persisted}}
  end

  @impl true
  def handle_call({:report, doc, name, zone, status}, _from, state) do
    now = DateTime.utc_now()

    case Map.get(state.people, doc) do
      nil ->
        person = %{
          document: doc,
          name: name,
          zone: zone,
          status: status,
          history: [%{status: status, timestamp: now}]
        }
        new_people = Map.put(state.people, doc, person)
        Persistence.save(@persistence_key, new_people)
        {:reply, {:ok, person}, %{state | people: new_people}}

      existing ->
        updated = %{
          existing |
          status: status,
          zone: zone,
          history: [%{status: status, timestamp: now} | existing.history]
        }
        new_people = Map.put(state.people, doc, updated)
        Persistence.save(@persistence_key, new_people)
        {:reply, {:ok, updated}, %{state | people: new_people}}
    end
  end

  @impl true
  def handle_call({:find, doc}, _from, state) do
    {:reply, Map.fetch(state.people, doc), state}
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
    {:reply, {:ok, msg}, %{state | messages: new_messages}}
  end

  @impl true
  def handle_call({:list_messages, doc}, _from, state) do
    msgs = Enum.filter(state.messages, &(&1.recipient_doc == doc))
    {:reply, msgs, state}
  end
end
