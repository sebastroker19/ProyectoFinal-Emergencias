defmodule EmergencySystem.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Phoenix.PubSub, name: EmergencySystem.PubSub},
      EmergencySystem.Auth,
      EmergencySystem.ZoneManager,
      EmergencySystem.ResourceManager,
      EmergencySystem.NeedManager,
      EmergencySystem.PersonManager,
      EmergencySystem.PetManager,
      EmergencySystem.Shelter,
      EmergencySystemWeb.Endpoint
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
