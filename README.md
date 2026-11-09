# Sistema Distribuido de Coordinación y Gestión de Emergencias en Elixir

> **Universidad del Quindío**  
> **Facultad de Ingeniería — Programa de Ingeniería de Sistemas y Computación**  
> **Asignatura:** Programación III  
> **Contexto:** Atención y coordinación posterior a un terremoto  

---

## 📋 Descripción del Proyecto

Plataforma distribuida y concurrente desarrollada en **Elixir / OTP** para coordinar las labores de rescate, atención humanitaria, asignación de suministros, control de albergues y localización de personas y mascotas tras un evento sísmico de gran magnitud.

El sistema cuenta con dos modos de interacción:
1. **Interfaz Web Reactiva con Phoenix:** Panel de control visual moderno con Tailwind CSS, gráficos de aforo, triaje de necesidades y laboratorio de concurrencia en vivo.
2. **Línea de Comandos (CLI):** Shell interactiva para operar mediante comandos textuales directos según las especificaciones del proyecto.

---

## 🏛️ Arquitectura del Sistema (OTP Tree)

El sistema utiliza un supervisor raíz `EmergencySystem.Supervisor` con estrategia `:one_for_one` que supervisa los siguientes procesos:

```
                          [ EmergencySystem.Supervisor ]
                                        │
    ┌──────────────┬──────────────┬─────┴────────┬──────────────┬──────────────┐
    ▼              ▼              ▼              ▼              ▼              ▼
[ Auth ]    [ ZoneManager ] [ ResourceManager ] [ NeedManager ] [ Shelter ] [ PersonManager ]
                                  │
                          [ PetManager ]
                                  │
                    [ EmergencySystemWeb.Endpoint ]
```

* **`EmergencySystem.Auth` (GenServer):** Registro automático, autenticación, control de sesiones, roles (`ciudadano`, `voluntario`, `coordinador`, `administrador`) y log de auditoría.
* **`EmergencySystem.ZoneManager` (GenServer):** Modela la jerarquía **Zona $\to$ Sectores $\to$ Puntos de atención** e implementa las **4 funciones recursivas propias**.
* **`EmergencySystem.ResourceManager` (GenServer):** Control atómico de inventario en almacenes y centros de acopio. Aplica la regla obligatoria de concurrencia impidiendo sobreasignación y cantidades negativas.
* **`EmergencySystem.NeedManager` (GenServer):** Gestión de necesidades puntuales ordenadas por prioridad (`crítica > alta > media > baja`). Impide que solicitudes atendidas vuelvan a consumir recursos.
* **`EmergencySystem.Shelter` (GenServer):** Gestión de albergues con `MapSet` de ocupantes, control de cupos y prevención estricta de sobrecupo.
* **`EmergencySystem.PersonManager` (GenServer):** Directorio de personas afectadas, trazabilidad histórica de estados y muro de mensajes familiares con estado de entrega.
* **`EmergencySystem.PetManager` (GenServer):** Algoritmo de similitud ponderada por scoring de atributos (especie, zona, color, tamaño, nombre) y resolución mutua sin doble cierre.
* **`EmergencySystem.Persistence`:** Almacenamiento y recarga en archivos planos legibles `.txt` en la carpeta `data/`.

---

## 🧠 Algoritmos Recursivos Implementados (Rúbrica: 4 Propias)

En el módulo `EmergencySystem.ZoneManager`:
1. `sum_zone_affected/1`: Recorrido recursivo sobre la lista de sectores para calcular el total de personas afectadas.
2. `sum_points/1`: Recorrido recursivo sobre la lista de puntos de atención dentro de cada sector.
3. `count_total_points/1`: Conteo recursivo del número total de puntos de atención existentes en la zona.
4. `collect_critical_points/2`: Filtro y acumulación recursiva de puntos de atención con afectación sobre un umbral crítico.

---

## ⚡ Demostración de Concurrencia y Resolución de Conflictos

El sistema garantiza que si dos o más solicitudes simultáneas intentan reservar unidades que superen el inventario real:
* Las llamadas se serializan atómicamente a través del mailbox del `GenServer`.
* Una solicitud es confirmada y la excedente es rechazada con `{:error, {:insufficient_inventory, ...}}`.
* El inventario nunca cae en números negativos ni inconsistencias.
* Incluye un **Laboratorio Interactivo de Concurrencia** en la interfaz web (`/concurrency`) para ejecutar y visualizar esta prueba en vivo.

---

## 🚀 Puesta en Marcha

### Prerrequisitos
* **Elixir** $\ge$ 1.14 (Probado en Elixir 1.20 / OTP 29)
* **Git**

### 1. Iniciar la Interfaz Web (Phoenix)
```powershell
# En Windows PowerShell:
$env:MIX_OS_CONCURRENCY_LOCK="0"
mix.bat phx.server
```
Abre en tu navegador web: **`http://localhost:4000`**

### 2. Iniciar la Consola Interactiva (CLI)
```powershell
$env:MIX_OS_CONCURRENCY_LOCK="0"
mix.bat run -e "EmergencySystem.CLI.main()"
```

### 3. Ejecutar la Suite de Pruebas Automatizadas
```powershell
$env:MIX_OS_CONCURRENCY_LOCK="0"
mix.bat test
```
*16 pruebas automatizadas (`16 passed, 0 failures`) cubriendo concurrencia, recursión, límites de capacidad, persistencia y controladores web.*

---

## 📑 Lista de Verificación de Requisitos

- [x] El sistema gestiona usuarios y roles (`ciudadano`, `voluntario`, `coordinador`, `administrador`).
- [x] El sistema gestiona zonas, sectores y puntos de atención.
- [x] El sistema gestiona necesidades ordenadas por prioridad.
- [x] El sistema gestiona inventario de recursos y transferencias.
- [x] Existe comunicación y mensajería entre familiares.
- [x] Existe gestión de mascotas perdidas/encontradas con algoritmo de matching.
- [x] Existe gestión de albergues con control estricto de cupo.
- [x] Se utilizan estructuras funcionales: Mapas, Listas, Tuplas y `MapSet`.
- [x] Existen al menos 4 funciones recursivas propias.
- [x] Existen procesos concurrentes supervisados (`GenServer` y `Supervisor`).
- [x] Se demuestra el conflicto concurrente resuelto correctamente.
- [x] Existe persistencia en archivos de texto plano (`data/*.txt`).
- [x] Existen pruebas automatizadas con ExUnit.
- [x] Interfaz Web funcional desarrollada con el framework Phoenix.
