defmodule EmergencySystem.Seeds do
  @moduledoc """
  Semilla de datos iniciales con información humana, realista y profesional
  para la coordinación de la emergencia (Atención post-terremoto).
  """
  alias EmergencySystem.ZoneManager
  alias EmergencySystem.ResourceManager
  alias EmergencySystem.NeedManager
  alias EmergencySystem.Shelter
  alias EmergencySystem.PersonManager
  alias EmergencySystem.PetManager
  alias EmergencySystem.Auth

  def run do
    # 1. Usuarios Oficiales del Sistema
    Auth.connect("laura.morales", "1234", "coordinador", "Zona 1 - Centro Histórico", "Dra. Laura Morales (Coordinadora PMU)")
    Auth.connect("sofia.admin", "admin123", "administrador", "Puesto de Mando Unificado", "Ing. Sofía Mendoza (Directora de Operaciones)")
    Auth.connect("carlos.restrepo", "1234", "voluntario", "Zona 2 - Cordillera Norte", "Carlos Restrepo (Socorrista Cruz Roja)")
    Auth.connect("andres.gomez", "1234", "ciudadano", "Zona 1 - Centro Histórico", "Andrés Felipe Gómez (Ciudadano)")

    # 2. Zonas y Jerarquía Territorial (Zona -> Sectores -> Puntos de Atención)
    if ZoneManager.list_zones() == [] do
      # Zona 1: Centro Histórico
      ZoneManager.register_zone("ZONA-CENTRO", "Zona 1 - Centro Histórico y Comercial", "alto")
      ZoneManager.add_sector("ZONA-CENTRO", "Sector Catedral y Plaza de Bolívar")
      ZoneManager.add_sector("ZONA-CENTRO", "Sector Residencial Parque Sucre")
      ZoneManager.add_point_of_attention("ZONA-CENTRO", "Sector Catedral y Plaza de Bolívar", "Puesto Médico Avanzado Plaza Bolívar", 45)
      ZoneManager.add_point_of_attention("ZONA-CENTRO", "Sector Catedral y Plaza de Bolívar", "Centro de Distribución Parque Infantil", 30)
      ZoneManager.add_point_of_attention("ZONA-CENTRO", "Sector Residencial Parque Sucre", "Punto de Triage Parque Sucre", 55)

      # Zona 2: Ladera y Cordillera Norte (Crítica)
      ZoneManager.register_zone("ZONA-NORTE", "Zona 2 - Comuna Norte y Ladera Cordillera", "critico")
      ZoneManager.add_sector("ZONA-NORTE", "Sector Barrio Las Palmas")
      ZoneManager.add_sector("ZONA-NORTE", "Sector Colinas de La Pradera")
      ZoneManager.add_point_of_attention("ZONA-NORTE", "Sector Barrio Las Palmas", "Hospital Militar de Campaña", 95)
      ZoneManager.add_point_of_attention("ZONA-NORTE", "Sector Barrio Las Palmas", "Estación de Bomberos #2", 60)
      ZoneManager.add_point_of_attention("ZONA-NORTE", "Sector Colinas de La Pradera", "Refugio Temporal La Pradera", 70)
    end

    # 3. Inventario Inicial de Recursos en Almacenes
    if ResourceManager.list_resources() == [] do
      ResourceManager.register_resource("AGUA-01", "Agua Potable Tratada (Bidones 5L)", "Líquidos Vitales", 250, "bidones", "Centro de Acopio Estadio Centenario")
      ResourceManager.register_resource("MED-01", "Botiquines Médicos de Trauma y Cirugía", "Insumos Médicos", 50, "cajas", "Almacén Central Cruz Roja")
      ResourceManager.register_resource("ALIM-01", "Raciones Alimentarias de Emergencia", "Víveres", 320, "paquetes", "Centro de Acopio Estadio Centenario")
      ResourceManager.register_resource("REF-01", "Mantas Térmicas de Campaña", "Refugio y Abrigo", 8, "unidades", "Albergue Polideportivo Norte") # Stock Crítico <= 10
      ResourceManager.register_resource("R_CONC_LAB", "Reserva Estratégica de Suero Oral", "Salud Vital", 50, "litros", "Puesto Médico Central")
    end

    # 4. Solicitudes de Necesidades Priorizadas
    if NeedManager.list_needs() == [] do
      NeedManager.register_need(
        "medicamentos",
        35,
        "critica",
        "Zona 2 - Comuna Norte",
        "Urgencia médica: Antisépticos, analgésicos y material de sutura para heridos en Hospital de Campaña",
        "Carlos Restrepo (Socorrista)"
      )

      NeedManager.register_need(
        "agua",
        60,
        "critica",
        "Zona 1 - Centro Histórico",
        "Corte total de suministro de acueducto en el sector Plaza Bolívar; se requieren bidones de agua potable",
        "Dra. Laura Morales"
      )

      NeedManager.register_need(
        "refugio",
        40,
        "alta",
        "Zona 2 - Comuna Norte",
        "Carpas familiares impermeables y colchonetas para personas evacuadas por deslizamiento en Las Palmas",
        "Carlos Restrepo (Socorrista)"
      )

      NeedManager.register_need(
        "alimentos",
        80,
        "media",
        "Zona 1 - Centro Histórico",
        "Raciones calóricas y leche en polvo para familias en albergues temporales",
        "Andrés Felipe Gómez (Ciudadano)"
      )
    end

    # 5. Albergues y Centros de Resguardo con Ocupantes
    if Shelter.list_shelters() == [] do
      Shelter.register_shelter("ALB-01", "Albergue Temporal Polideportivo Norte", "Zona 2 - Comuna Norte", 120)
      Shelter.register_entry("ALB-01", "10949001")
      Shelter.register_entry("ALB-01", "10949002")
      Shelter.register_entry("ALB-01", "10949003")
      Shelter.register_entry("ALB-01", "10949004")

      Shelter.register_shelter("ALB-02", "Albergue Escolar Colegio San José", "Zona 1 - Centro Histórico", 65)
      Shelter.register_entry("ALB-02", "10949005")
      Shelter.register_entry("ALB-02", "10949006")
    end

    # 6. Personas Afectadas y Mensajes Familiares Reales
    if PersonManager.search_people(%{}) == [] do
      PersonManager.report_person("10949001", "Andrés Felipe Restrepo", 28, "Zona 2 - Comuna Norte", "en_albergue")
      PersonManager.send_message("10949001", "María Elena Restrepo (Madre)", "Hijo, toda la familia está bien en casa de la tía. Te esperamos en cuanto puedas salir del albergue.")

      PersonManager.report_person("10949002", "Camila Andrea Ospina", 34, "Zona 1 - Centro Histórico", "localizada")
      PersonManager.send_message("10949002", "Pedro Ospina (Hermano)", "Camila, ya te localizamos con la Defensa Civil. Vamos en camino hacia el punto de encuentro.")

      PersonManager.report_person("10949003", "Don Hernando Morales Gómez", 68, "Zona 2 - Comuna Norte", "en_albergue")
      PersonManager.send_message("10949003", "Claudia Morales (Hija)", "Papá, tus medicamentos para la tensión los tiene el socorrista de la Cruz Roja.")

      PersonManager.report_person("10949005", "Valentina Salazar Ríos", 19, "Zona 1 - Centro Histórico", "en_albergue")
    end

    # 7. Mascotas Perdidas y Encontradas con Reportes Humanizados
    if PetManager.list_reports() == [] do
      PetManager.report_pet(
        "perdida",
        "perro",
        "Luna",
        "Golden retriever dorada, collar rojo de cuero con placa en forma de hueso, dócil",
        "dorado",
        "grande",
        "Zona 1 - Centro Histórico",
        "315-442-8901 (Familia Gómez)"
      )

      PetManager.report_pet(
        "encontrada",
        "perro",
        "Luna",
        "Golden retriever hembra encontrada desorientada cerca al Parque Sucre, collar rojo desgastado",
        "dorado",
        "grande",
        "Zona 1 - Centro Histórico",
        "320-771-3345 (Voluntario Defensa Civil)"
      )

      PetManager.report_pet(
        "perdida",
        "gato",
        "Michi",
        "Gato criollo atigrado gris con pecho blanco, ojos verdes, asustadizo",
        "gris y blanco",
        "pequeño",
        "Zona 2 - Comuna Norte",
        "311-654-9870 (Lucía Peña)"
      )
    end

    :ok
  end
end
