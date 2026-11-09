defmodule EmergencySystem do
  @moduledoc """
  Fachada principal del Sistema Distribuido de Coordinación y Gestión de Emergencias.
  Coordina las operaciones autorizadas sobre los GenServers de dominio y registra la actividad.
  """
  alias EmergencySystem.Auth
  alias EmergencySystem.ZoneManager
  alias EmergencySystem.ResourceManager
  alias EmergencySystem.NeedManager
  alias EmergencySystem.PersonManager
  alias EmergencySystem.PetManager
  alias EmergencySystem.Shelter

  # =========================================================================
  # GESTIÓN DE USUARIOS Y SESIONES (1.4.1 y 1.4.2)
  # =========================================================================

  def connect(user, pass, role \\ "ciudadano", zone \\ "centro", full_name \\ "") do
    Auth.connect(user, pass, role, zone, full_name)
  end

  def disconnect(user) do
    Auth.disconnect(user)
  end

  def get_user_info(user) do
    Auth.get_user(user)
  end

  def list_active_sessions do
    Auth.list_active_sessions()
  end

  def get_activity_log(user, target_user \\ nil) do
    with :ok <- Auth.authorize(user, ["administrador", "coordinador"]) do
      {:ok, Auth.get_activity_log(target_user)}
    end
  end

  # =========================================================================
  # GESTIÓN DE ZONAS AFECTADAS Y JERARQUÍA RECURSIVA (1.4.3)
  # =========================================================================

  def register_zone(user, code, name, level) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "register_zone: #{code}")
      ZoneManager.register_zone(code, name, level)
    end
  end

  def add_sector(user, zone_code, sector_name) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "add_sector: #{sector_name} en #{zone_code}")
      ZoneManager.add_sector(zone_code, sector_name)
    end
  end

  def add_point_of_attention(user, zone_code, sector_name, point_name, affected_count) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador", "voluntario"]) do
      Auth.log_activity(user, "add_point: #{point_name} (#{affected_count} afectados)")
      ZoneManager.add_point_of_attention(zone_code, sector_name, point_name, affected_count)
    end
  end

  def get_zone_stats(user, zone_code) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      ZoneManager.zone_statistics(zone_code)
    end
  end

  def list_zones(user) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, ZoneManager.list_zones()}
    end
  end

  # =========================================================================
  # GESTIÓN DE NECESIDADES PUNTUALES (1.4.4)
  # =========================================================================

  def register_need(user, type, qty, priority, zone, desc) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "register_need: #{type} qty: #{qty}")
      NeedManager.register_need(type, qty, priority, zone, desc, user)
    end
  end

  def list_needs(user, filters \\ %{}) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, NeedManager.list_needs(filters)}
    end
  end

  def assign_resource(user, need_id, resource_code, qty) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "assign_resource: #{resource_code} (#{qty}) a necesidad #{need_id}")
      NeedManager.assign_resources(need_id, resource_code, qty)
    end
  end

  def update_need_status(user, need_id, new_status) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador", "voluntario"]) do
      Auth.log_activity(user, "update_need_status: #{need_id} -> #{new_status}")
      NeedManager.update_status(need_id, new_status)
    end
  end

  # =========================================================================
  # GESTIÓN DE RECURSOS E INVENTARIO CONCURRENTE (1.4.5)
  # =========================================================================

  def register_resource(user, code, name, category, qty, unit, location) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "register_resource: #{code} (#{qty} #{unit}) en #{location}")
      ResourceManager.register_resource(code, name, category, qty, unit, location)
    end
  end

  def list_resources(user, filters \\ %{}) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, ResourceManager.list_resources(filters)}
    end
  end

  def transfer_resource(user, code, origin, target, qty) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "transfer_resource: #{code} qty: #{qty} from #{origin} to #{target}")
      ResourceManager.transfer_resource(code, origin, target, qty)
    end
  end

  def critical_resources(user, threshold \\ 10) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador", "voluntario"]) do
      {:ok, ResourceManager.get_critical_resources(threshold)}
    end
  end

  def get_resource_history(user, code \\ nil) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      {:ok, ResourceManager.get_history(code)}
    end
  end

  # =========================================================================
  # COMUNICACIÓN FAMILIAR Y PERSONAS AFECTADAS (1.4.6)
  # =========================================================================

  def report_person(user, document, name, age \\ 0, zone \\ "desconocida", status \\ "reportada") do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "report_person: #{document} - #{name}")
      PersonManager.report_person(document, name, age, zone, status)
    end
  end

  def find_person(user, document) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      PersonManager.find_person(document)
    end
  end

  def search_people(user, filters) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, PersonManager.search_people(filters)}
    end
  end

  def update_person_status(user, document, status, zone \\ nil) do
    with :ok <- Auth.authorize(user, ["voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "update_person_status: #{document} -> #{status}")
      PersonManager.update_person_status(document, status, zone)
    end
  end

  def send_family_message(user, document, content) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "send_message to: #{document}")
      PersonManager.send_message(document, user, content)
    end
  end

  def list_family_messages(user, document) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, PersonManager.list_messages(document)}
    end
  end

  def mark_message_delivered(user, message_id) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "mark_message_delivered: #{message_id}")
      PersonManager.mark_message_delivered(message_id)
    end
  end

  # =========================================================================
  # MASCOTAS PERDIDAS Y ENCONTRADAS (1.4.7)
  # =========================================================================

  def report_pet(user, type, species, name, traits, color, size, zone, contact) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "report_pet: #{type} #{species} #{name}")
      PetManager.report_pet(type, species, name, traits, color, size, zone, contact)
    end
  end

  def match_pets(user, min_score \\ 50) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, PetManager.match_pets(min_score)}
    end
  end

  def confirm_pet_match(user, lost_id, found_id) do
    with :ok <- Auth.authorize(user, ["voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "confirm_pet_match: #{lost_id} con #{found_id}")
      PetManager.confirm_match(lost_id, found_id)
    end
  end

  def list_pets(user, filters \\ %{}) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, PetManager.list_reports(filters)}
    end
  end

  # =========================================================================
  # GESTIÓN DE ALBERGUES (1.4.8)
  # =========================================================================

  def register_shelter(user, code, name, zone, max_capacity) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador"]) do
      Auth.log_activity(user, "register_shelter: #{code} #{name} cap: #{max_capacity}")
      Shelter.register_shelter(code, name, zone, max_capacity)
    end
  end

  def check_shelter(user, code) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      Shelter.check_shelter(code)
    end
  end

  def register_shelter_entry(user, shelter_code, person_doc) do
    with :ok <- Auth.authorize(user, ["voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "shelter_entry: #{person_doc} en #{shelter_code}")
      Shelter.register_entry(shelter_code, person_doc)
    end
  end

  def register_shelter_exit(user, shelter_code, person_doc) do
    with :ok <- Auth.authorize(user, ["voluntario", "coordinador", "administrador"]) do
      Auth.log_activity(user, "shelter_exit: #{person_doc} de #{shelter_code}")
      Shelter.register_exit(shelter_code, person_doc)
    end
  end

  def shelter_occupancy_report(user) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador", "voluntario"]) do
      {:ok, Shelter.occupancy_report()}
    end
  end

  def list_shelters(user) do
    with :ok <- Auth.authorize(user, ["ciudadano", "voluntario", "coordinador", "administrador"]) do
      {:ok, Shelter.list_shelters()}
    end
  end

  # =========================================================================
  # RESUMEN GENERAL (DASHBOARD)
  # =========================================================================

  def summary(user) do
    with :ok <- Auth.authorize(user, ["coordinador", "administrador", "voluntario", "ciudadano"]) do
      %{
        critical_resources: ResourceManager.get_critical_resources(),
        pending_needs: NeedManager.list_needs(%{status: "pendiente"}),
        pet_matches: PetManager.match_pets(60),
        shelters_occupancy: Shelter.occupancy_report()
      }
    end
  end
end
