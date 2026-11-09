defmodule EmergencySystemTest do
  use ExUnit.Case, async: false

  alias EmergencySystem
  alias EmergencySystem.ZoneManager
  alias EmergencySystem.ResourceManager

  setup do
    File.rm_rf!("data")
    # Detener y reiniciar el supervisor para reiniciar el estado de todos los GenServers
    try do
      Supervisor.stop(EmergencySystem.Supervisor, :normal)
    catch
      :exit, _ -> :ok
    end

    {:ok, _} = EmergencySystem.Supervisor.start_link([])
    :ok
  end

  # =========================================================================
  # 1. GESTIÓN DE USUARIOS Y ROLES (1.4.1 y 1.4.2)
  # =========================================================================
  test "registro automático y autenticación con roles" do
    # Registro automático de nuevo usuario
    assert {:ok, :registered_and_connected, "coordinador"} =
             EmergencySystem.connect("laura", "1234", "coordinador", "centro")

    # Reconexión con contraseña correcta
    assert {:ok, :connected, "coordinador"} =
             EmergencySystem.connect("laura", "1234")

    # Intento con contraseña errónea
    assert {:error, :invalid_credentials} =
             EmergencySystem.connect("laura", "clave_invalida")

    # Desconexión
    assert :ok = EmergencySystem.disconnect("laura")
  end

  # =========================================================================
  # 2. RESOLUCIÓN DE CONFLICTO CONCURRENTE (REGLA OBLIGATORIA DEL PDF)
  # =========================================================================
  test "demostración de conflicto concurrente resuelto correctamente (sobreasignación de recursos)" do
    # Crear usuario coordinador
    EmergencySystem.connect("coord_conc", "1234", "coordinador", "centro")

    # Registrar 50 litros de agua disponibles
    assert {:ok, _} =
             EmergencySystem.register_resource("coord_conc", "R_CONC_01", "Agua Potable", "liquidos", 50, "litros", "centro_acopio_1")

    # Lanzar 2 procesos concurrentes simultáneos:
    # Proceso A intenta deducir 30 litros.
    # Proceso B intenta deducir 25 litros.
    # Total solicitado: 55 litros. Solo existen 50.
    task_a = Task.async(fn ->
      ResourceManager.deduct_resource("R_CONC_01", 30)
    end)

    task_b = Task.async(fn ->
      ResourceManager.deduct_resource("R_CONC_01", 25)
    end)

    res_a = Task.await(task_a)
    res_b = Task.await(task_b)

    # Uno debe tener éxito y el otro debe fallar por inventario insuficiente
    assert (match?({:ok, _}, res_a) and match?({:error, {:insufficient_inventory, _}}, res_b)) or
           (match?({:ok, _}, res_b) and match?({:error, {:insufficient_inventory, _}}, res_a))

    # El inventario restante nunca debe ser negativo
    {:ok, final_res} = ResourceManager.get_resource("R_CONC_01")
    assert final_res.available >= 0
    assert final_res.available in [20, 25]
  end

  # =========================================================================
  # 3. CUATRO FUNCIONES RECURSIVAS PROPIAS EN EL ÁRBOL DE ZONAS (1.4.3)
  # =========================================================================
  test "las 4 funciones recursivas sobre la jerarquía zona -> sectores -> puntos" do
    EmergencySystem.connect("coord_rec", "1234", "coordinador", "norte")
    EmergencySystem.register_zone("coord_rec", "Z_REC", "Zona Cordillera", "alto")
    EmergencySystem.add_sector("coord_rec", "Z_REC", "Sector_A")
    EmergencySystem.add_sector("coord_rec", "Z_REC", "Sector_B")

    # Puntos de atención
    EmergencySystem.add_point_of_attention("coord_rec", "Z_REC", "Sector_A", "Punto 1", 30)
    EmergencySystem.add_point_of_attention("coord_rec", "Z_REC", "Sector_A", "Punto 2", 70)
    EmergencySystem.add_point_of_attention("coord_rec", "Z_REC", "Sector_B", "Punto 3", 40)

    {:ok, zone} = ZoneManager.get_zone("Z_REC")
    sectors_list = Map.values(zone.sectors)

    # Recursión 1: sum_zone_affected/1
    total_affected = ZoneManager.sum_zone_affected(sectors_list)
    assert total_affected == 140

    # Recursión 2: sum_points/1 (en Sector_A: 30 + 70 = 100)
    sector_a = zone.sectors["Sector_A"]
    assert ZoneManager.sum_points(sector_a.points) == 100

    # Recursión 3: count_total_points/1
    assert ZoneManager.count_total_points(sectors_list) == 3

    # Recursión 4: collect_critical_points/2 (umbral >= 50, debe capturar Punto 2 con 70)
    criticos = ZoneManager.collect_critical_points(sectors_list, 50)
    assert length(criticos) == 1
    assert hd(criticos).name == "Punto 2"
    assert hd(criticos).affected == 70
  end

  # =========================================================================
  # 4. GESTIÓN Y PRIORIZACIÓN DE NECESIDADES (1.4.4)
  # =========================================================================
  test "registro, ordenamiento por prioridad y prevención de reasignación en necesidad atendida" do
    EmergencySystem.connect("voluntario1", "1234", "voluntario", "centro")
    EmergencySystem.connect("admin1", "1234", "administrador", "centro")

    # Registrar necesidades con diferente prioridad
    {:ok, _n_baja} = EmergencySystem.register_need("voluntario1", "mantas", 10, "baja", "centro", "Abrigo general")
    {:ok, n_crit} = EmergencySystem.register_need("voluntario1", "agua", 20, "critica", "centro", "Agua para hospital")

    # Listar: la crítica debe aparecer antes que la baja
    {:ok, list} = EmergencySystem.list_needs("voluntario1")
    assert hd(list).id == n_crit.id

    # Registrar recurso y asignar
    EmergencySystem.register_resource("admin1", "R_AGUA", "Agua", "liquidos", 50, "litros", "centro")
    assert {:ok, updated_need} = EmergencySystem.assign_resource("admin1", n_crit.id, "R_AGUA", 20)
    assert updated_need.status == "atendida"

    # Regla: Evitar que una necesidad ya atendida vuelva a consumir recursos
    assert {:error, :need_already_closed} =
             EmergencySystem.assign_resource("admin1", n_crit.id, "R_AGUA", 10)
  end

  # =========================================================================
  # 5. CONTROL DE ALBERGUES Y CAPACIDAD MÁXIMA (1.4.8)
  # =========================================================================
  test "control de aforo en albergues impidiendo superar la capacidad máxima" do
    EmergencySystem.connect("coord_alb", "1234", "coordinador", "sur")

    # Albergue con capacidad para 2 personas
    assert {:ok, _} = EmergencySystem.register_shelter("coord_alb", "ALB_01", "Albergue Sur", "sur", 2)

    # Ingreso persona 1 y 2
    assert {:ok, s1} = EmergencySystem.register_shelter_entry("coord_alb", "ALB_01", "DOC111")
    assert s1.current_occupancy == 1

    assert {:ok, s2} = EmergencySystem.register_shelter_entry("coord_alb", "ALB_01", "DOC222")
    assert s2.current_occupancy == 2

    # Intentar ingresar una tercera persona cuando el cupo está lleno
    assert {:error, :shelter_full} =
             EmergencySystem.register_shelter_entry("coord_alb", "ALB_01", "DOC333")

    # Registrar salida y verificar liberación de cupo
    assert {:ok, s3} = EmergencySystem.register_shelter_exit("coord_alb", "ALB_01", "DOC111")
    assert s3.current_occupancy == 1
  end

  # =========================================================================
  # 6. MASCOTAS: SCORING Y CIERRE MUTUO SIN DOBLE RESOLUCIÓN (1.4.7)
  # =========================================================================
  test "algoritmo de similitud de mascotas y cierre mutuo" do
    EmergencySystem.connect("user_pet", "1234", "ciudadano", "norte")
    EmergencySystem.connect("vol_pet", "1234", "voluntario", "norte")

    # Mascota perdida
    {:ok, lost} = EmergencySystem.report_pet("user_pet", "perdida", "perro", "Luna", "collar rojo", "negro", "mediano", "zona_norte", "3001234567")

    # Mascota encontrada con características coincidentes
    {:ok, found} = EmergencySystem.report_pet("vol_pet", "encontrada", "perro", "Luna", "mancha blanca", "negro", "mediano", "zona_norte", "3119876543")

    # Búsqueda de coincidencias
    {:ok, matches} = EmergencySystem.match_pets("vol_pet", 60)
    assert length(matches) >= 1
    match = hd(matches)
    assert match.score >= 80

    # Confirmar coincidencia y cerrar ambos reportes
    assert {:ok, res_lost, res_found} = EmergencySystem.confirm_pet_match("vol_pet", lost.id, found.id)
    assert res_lost.status == "resuelta"
    assert res_found.status == "resuelta"

    # Regla: No se puede cerrar dos veces un reporte
    assert {:error, :lost_pet_already_resolved} =
             EmergencySystem.confirm_pet_match("vol_pet", lost.id, found.id)
  end

  # =========================================================================
  # 7. COMUNICACIÓN ENTRE FAMILIARES (1.4.6)
  # =========================================================================
  test "búsqueda de personas y mensajería familiar con cambio de estado" do
    EmergencySystem.connect("fam_user", "1234", "ciudadano", "centro")

    # Registrar persona
    {:ok, person} = EmergencySystem.report_person("fam_user", "10949001", "Carlos Gómez", 35, "centro", "localizada")
    assert person.name == "Carlos Gómez"

    # Búsqueda
    assert {:ok, found_person} = EmergencySystem.find_person("fam_user", "10949001")
    assert found_person.status == "localizada"

    # Dejar mensaje
    assert {:ok, msg} = EmergencySystem.send_family_message("fam_user", "10949001", "Estamos todos bien en casa.")
    assert msg.status == "pendiente"

    # Listar mensajes
    {:ok, msgs} = EmergencySystem.list_family_messages("fam_user", "10949001")
    assert length(msgs) == 1

    # Marcar entregado
    assert :ok = EmergencySystem.mark_message_delivered("fam_user", msg.id)
  end

  # =========================================================================
  # 8. TRANSFERENCIA DE RECURSOS ENTRE CENTROS Y PERSISTENCIA (1.4.5 y 1.4.9)
  # =========================================================================
  test "transferencia de recursos entre centros y recarga desde persistencia (.txt)" do
    EmergencySystem.connect("admin_trans", "1234", "administrador", "centro")

    # Registrar recurso en centro de acopio
    assert {:ok, _} = EmergencySystem.register_resource("admin_trans", "R_MEDS", "Botiquines", "salud", 100, "cajas", "acopio_central")

    # Transferir 40 unidades hacia albergue 1
    assert {:ok, :transferred, orig, dest} =
             EmergencySystem.transfer_resource("admin_trans", "R_MEDS", "acopio_central", "albergue_1", 40)

    assert orig.available == 60
    assert dest.available == 40
    assert dest.location == "albergue_1"

    # Verificar que el archivo plano existe
    assert File.exists?("data/resources.txt")

    # Simular reinicio del supervisor para probar persistencia
    Supervisor.stop(EmergencySystem.Supervisor, :normal)
    {:ok, _} = EmergencySystem.Supervisor.start_link([])

    # Los datos deben persistir después del reinicio
    {:ok, reloaded} = ResourceManager.get_resource("R_MEDS")
    assert reloaded.available == 60
  end
end
