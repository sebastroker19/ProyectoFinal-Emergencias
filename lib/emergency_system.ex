defmodule EmergencySystem do
  alias EmergencySystem.Auth
  alias EmergencySystem.ResourceManager
  alias EmergencySystem.NeedManager
  alias EmergencySystem.PersonManager
  alias EmergencySystem.PetManager
  alias EmergencySystem.Shelter

  def connect(user, pass, role \\ "ciudadano", zone \\ "centro") do
    Auth.connect(user, pass, role, zone)
  end

  def disconnect(user) do
    Auth.disconnect(user)
  end

  def register_need(user, type, qty, priority, zone, desc) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "register_need")
      NeedManager.register_need(type, qty, priority, zone, desc, user)
    end
  end

  def register_resource(user, code, name, category, qty, unit, location) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "register_resource")
      ResourceManager.register_resource(code, name, category, qty, unit, location)
    end
  end

  def assign_resource(user, need_id, resource_code, qty) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "assign_resource")
      NeedManager.assign_resources(need_id, resource_code, qty)
    end
  end

  def summary(user) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador", "voluntario", "ciudadano"]) do
      %{
        critical_resources: ResourceManager.get_critical_resources(),
        pending_needs: NeedManager.list_needs(%{status: "pendiente"}),
        pet_matches: PetManager.match_pets()
      }
    end
  end
end
