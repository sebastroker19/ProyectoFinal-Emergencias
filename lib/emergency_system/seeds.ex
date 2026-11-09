defmodule EmergencySystem.Seeds do
  @moduledoc """
  Semilla de datos iniciales para demostración interactiva (PDF Páginas 6 y 7).
  Se ejecuta automáticamente si no existen datos previos en el sistema.
  """
  alias EmergencySystem.ZoneManager
  alias EmergencySystem.ResourceManager
  alias EmergencySystem.NeedManager
  alias EmergencySystem.Shelter
  alias EmergencySystem.PersonManager
  alias EmergencySystem.PetManager
  alias EmergencySystem.Auth

  def run do
    # 1. Usuarios demo
    Auth.connect("laura", "1234", "coordinador", "centro", "Laura Coordinadora")
    Auth.connect("carlos", "1234", "voluntario", "norte", "Carlos Voluntario")
    Auth.connect("andres", "1234", "ciudadano", "norte", "Andrés Ciudadano")
    Auth.connect("admin", "admin123", "administrador", "centro", "Administrador Principal")

    # 2. Zonas y jerarquía territorial (si no existen)
    if ZoneManager.list_zones() == [] do
      ZoneManager.register_zone("Z_CENTRO", "Zona Centro Histórico", "alto")
      ZoneManager.add_sector("Z_CENTRO", "Sector 1 Comercial")
      ZoneManager.add_sector("Z_CENTRO", "Sector 2 Residencial")
      ZoneManager.add_point_of_attention("Z_CENTRO", "Sector 1 Comercial", "Punto Plaza Bolívar", 35)
      ZoneManager.add_point_of_attention("Z_CENTRO", "Sector 2 Residencial", "Punto Parque Sucre", 45)

      ZoneManager.register_zone("Z_NORTE", "Zona Cordillera Norte", "critico")
      ZoneManager.add_sector("Z_NORTE", "Sector Las Palmas")
      ZoneManager.add_sector("Z_NORTE", "Sector La Pradera")
      ZoneManager.add_point_of_attention("Z_NORTE", "Sector Las Palmas", "Hospital de Campaña", 85)
      ZoneManager.add_point_of_attention("Z_NORTE", "Sector La Pradera", "Refugio Temporal Norte", 60)
    end

    # 3. Recursos iniciales (si no existen)
    if ResourceManager.list_resources() == [] do
      ResourceManager.register_resource("R001", "Agua Potable 500ml", "liquidos", 180, "botellas", "centro_acopio_1")
      ResourceManager.register_resource("R002", "Kits Primeros Auxilios", "salud", 45, "cajas", "centro_acopio_1")
      ResourceManager.register_resource("R003", "Mantas Térmicas", "refugio", 7, "unidades", "albergue_norte") # Stock crítico <= 10
      ResourceManager.register_resource("R_CONC_LAB", "Agua Potable Demo", "liquidos", 50, "litros", "centro_acopio_1")
    end

    # 4. Necesidades iniciales
    if NeedManager.list_needs() == [] do
      NeedManager.register_need("agua", 30, "critica", "centro", "Punto de atención sector 3 requiere agua urgente", "laura")
      NeedManager.register_need("refugio", 20, "alta", "norte", "Mantas y carpas para familias evacuadas", "carlos")
      NeedManager.register_need("alimentos", 50, "media", "centro", "Raciones no perecederas para centro de apoyo", "andres")
    end

    # 5. Albergues
    if Shelter.list_shelters() == [] do
      Shelter.register_shelter("A01", "Albergue Norte", "zona_norte", 150)
      Shelter.register_entry("A01", "10949001")
      Shelter.register_entry("A01", "10949002")
      Shelter.register_entry("A01", "10949003")

      Shelter.register_shelter("A02", "Polideportivo Central", "zona_centro", 60)
      Shelter.register_entry("A02", "10949004")
      Shelter.register_entry("A02", "10949005")
    end

    # 6. Personas y mensajes familiares
    if PersonManager.search_people(%{}) == [] do
      PersonManager.report_person("10949001", "Andrés Restrepo", 28, "zona_norte", "en_albergue")
      PersonManager.send_message("10949001", "Familiar María", "Estoy bien, estoy en el albergue norte. Te esperamos.")

      PersonManager.report_person("10949002", "Camila Ospina", 34, "zona_centro", "localizada")
      PersonManager.send_message("10949002", "Familiar Pedro", "Comunícate pronto con la abuela.")
    end

    # 7. Mascotas (Perdida y Encontrada con scoring alto)
    if PetManager.list_reports() == [] do
      PetManager.report_pet("perdida", "perro", "Luna", "collar rojo con placa", "negro", "mediano", "zona_norte", "3001234567")
      PetManager.report_pet("encontrada", "perro", "Luna", "mancha blanca en pecho", "negro", "mediano", "zona_norte", "3119876543")
    end

    :ok
  end
end
