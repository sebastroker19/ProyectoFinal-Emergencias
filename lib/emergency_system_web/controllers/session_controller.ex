defmodule EmergencySystemWeb.SessionController do
  use EmergencySystemWeb, :controller
  alias EmergencySystemWeb.Layout

  @demo_profiles %{
    "laura" => %{
      username: "laura.morales",
      password: "1234",
      full_name: "Dra. Laura Morales",
      role: "coordinador",
      zone: "Zona 1 - Centro Histórico",
      title: "Coordinadora de Zona",
      desc: "Gestión de suministros, asignación a necesidades críticas, albergues y zonas."
    },
    "sofia" => %{
      username: "sofia.admin",
      password: "admin123",
      full_name: "Ing. Sofía Mendoza",
      role: "administrador",
      zone: "Puesto de Mando Central",
      title: "Directora General de Emergencias",
      desc: "Acceso total, auditoría de eventos y reabastecimiento estratégico de inventario."
    },
    "carlos" => %{
      username: "carlos.restrepo",
      password: "1234",
      full_name: "Carlos Restrepo",
      role: "voluntario",
      zone: "Zona 2 - Cordillera Norte",
      title: "Socorrista y Rescatista Cruz Roja",
      desc: "Control de ingresos/salidas a albergues, reporte de mascotas y localización de personas."
    },
    "andres" => %{
      username: "andres.gomez",
      password: "1234",
      full_name: "Andrés Felipe Gómez",
      role: "ciudadano",
      zone: "Zona 1 - Centro Histórico",
      title: "Ciudadano de la Comunidad",
      desc: "Registro de solicitudes de auxilio familiar, búsqueda de allegados y mascotas."
    }
  }

  def new(conn, _params) do
    html_content = render_login_page()
    html(conn, Layout.render(conn, "login", "Ingreso al Sistema", html_content))
  end

  def login(conn, %{"username" => username, "password" => password}) do
    case EmergencySystem.connect(username, password) do
      {:ok, status, role} when status in [:connected, :registered_and_connected] ->
        {:ok, user_info} = EmergencySystem.get_user_info(username)

        user_session = %{
          username: username,
          full_name: user_info.full_name || username,
          role: role,
          zone: user_info.zone || "centro"
        }

        conn
        |> put_session(:current_user, user_session)
        |> put_flash(:info, "Bienvenido(a), #{user_session.full_name}. Has ingresado con rol de #{String.upcase(role)}.")
        |> redirect(to: "/")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Contraseña incorrecta para el usuario '#{username}'.")
        |> redirect(to: "/login")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error de ingreso: #{inspect(reason)}")
        |> redirect(to: "/login")
    end
  end

  def quick_login(conn, %{"profile" => profile_key}) do
    profile = Map.get(@demo_profiles, profile_key, @demo_profiles["laura"])

    EmergencySystem.connect(
      profile.username,
      profile.password,
      profile.role,
      profile.zone,
      profile.full_name
    )

    user_session = %{
      username: profile.username,
      full_name: profile.full_name,
      role: profile.role,
      zone: profile.zone
    }

    conn
    |> put_session(:current_user, user_session)
    |> put_flash(:info, "Sesión activa iniciada como: #{profile.full_name} (#{String.capitalize(profile.role)})")
    |> redirect(to: "/")
  end

  def register(conn, %{"username" => user, "password" => pass, "full_name" => name, "role" => role, "zone" => zone}) do
    case EmergencySystem.connect(user, pass, role, zone, name) do
      {:ok, :registered_and_connected, assigned_role} ->
        user_session = %{
          username: user,
          full_name: name,
          role: assigned_role,
          zone: zone
        }

        conn
        |> put_session(:current_user, user_session)
        |> put_flash(:info, "Usuario '#{name}' registrado exitosamente en el sistema.")
        |> redirect(to: "/")

      {:error, reason} ->
        conn
        |> put_flash(:error, "No se pudo registrar el usuario: #{inspect(reason)}")
        |> redirect(to: "/login")
    end
  end

  def logout(conn, _params) do
    if user = get_session(conn, :current_user) do
      EmergencySystem.disconnect(user.username)
    end

    conn
    |> clear_session()
    |> put_flash(:info, "Has cerrado sesión correctamente.")
    |> redirect(to: "/login")
  end

  def switch(conn, %{"role" => role}) do
    # Mapeo a perfiles reales
    profile_key =
      case role do
        "coordinador" -> "laura"
        "administrador" -> "sofia"
        "voluntario" -> "carlos"
        _ -> "andres"
      end

    quick_login(conn, %{"profile" => profile_key})
  end

  defp render_login_page do
    """
    <div class="max-w-5xl mx-auto py-4 space-y-8">
      <!-- Encabezado de Ingreso -->
      <div class="text-center space-y-2">
        <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-red-100 text-red-700 text-xs font-bold uppercase tracking-wider">
          <span class="w-2 h-2 rounded-full bg-red-600 animate-pulse"></span>
          Control de Acceso y Gestión de Identidades
        </div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Portal de Coordinación de Emergencias</h1>
        <p class="text-slate-500 text-sm max-w-xl mx-auto">
          Selecciona un perfil de demostración oficial o ingresa con tus credenciales de voluntario, coordinador o ciudadano.
        </p>
      </div>

      <!-- Sección de Perfiles de Demostración (Ingreso con 1 Clic) -->
      <div class="bg-gradient-to-br from-slate-900 to-indigo-950 p-6 sm:p-8 rounded-3xl text-white shadow-xl border border-indigo-900/50 space-y-4">
        <div class="flex items-center justify-between border-b border-slate-800 pb-3">
          <div>
            <h2 class="text-base font-bold text-white flex items-center gap-2">
              <span>⚡</span> Perfiles Oficiales para Sustentación y Demostración
            </h2>
            <p class="text-xs text-indigo-300">Haz clic en cualquiera de los perfiles para ingresar al instante con su rol y permisos autorizados.</p>
          </div>
          <span class="text-[11px] bg-indigo-500/30 text-indigo-200 px-3 py-1 rounded-full font-mono border border-indigo-400/30">1-Clic Demo</span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-2">
          <!-- Tarjeta 1: Laura Morales (Coordinadora) -->
          <form action="/session/quick-login" method="post" class="h-full">
            <input type="hidden" name="profile" value="laura">
            <button type="submit" class="w-full h-full text-left p-4 rounded-2xl bg-slate-800/80 hover:bg-slate-700/90 border border-slate-700/80 hover:border-blue-400 transition-all shadow-md group flex flex-col justify-between">
              <div>
                <div class="w-12 h-12 rounded-xl bg-blue-600/30 border border-blue-400/40 text-blue-300 flex items-center justify-center text-xl font-bold mb-3 group-hover:scale-105 transition-transform">
                  👩‍⚕️
                </div>
                <div class="font-bold text-sm text-white">Dra. Laura Morales</div>
                <span class="inline-block px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-blue-500/20 text-blue-300 border border-blue-500/30 mt-1">
                  Coordinadora
                </span>
                <p class="text-xs text-slate-300 mt-2 line-clamp-3">
                  Asignación de recursos vitales, gestión de zonas y albergues en Zona Centro.
                </p>
              </div>
              <div class="pt-3 mt-3 border-t border-slate-700/60 flex items-center justify-between text-xs font-semibold text-blue-400 group-hover:text-blue-300">
                <span>Ingresar perfil &rarr;</span>
              </div>
            </button>
          </form>

          <!-- Tarjeta 2: Sofía Mendoza (Administradora) -->
          <form action="/session/quick-login" method="post" class="h-full">
            <input type="hidden" name="profile" value="sofia">
            <button type="submit" class="w-full h-full text-left p-4 rounded-2xl bg-slate-800/80 hover:bg-slate-700/90 border border-slate-700/80 hover:border-purple-400 transition-all shadow-md group flex flex-col justify-between">
              <div>
                <div class="w-12 h-12 rounded-xl bg-purple-600/30 border border-purple-400/40 text-purple-300 flex items-center justify-center text-xl font-bold mb-3 group-hover:scale-105 transition-transform">
                  🛡️
                </div>
                <div class="font-bold text-sm text-white">Ing. Sofía Mendoza</div>
                <span class="inline-block px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-purple-500/20 text-purple-300 border border-purple-500/30 mt-1">
                  Administradora
                </span>
                <p class="text-xs text-slate-300 mt-2 line-clamp-3">
                  Dirección general, transferencias entre almacenes y auditoría completa.
                </p>
              </div>
              <div class="pt-3 mt-3 border-t border-slate-700/60 flex items-center justify-between text-xs font-semibold text-purple-400 group-hover:text-purple-300">
                <span>Ingresar perfil &rarr;</span>
              </div>
            </button>
          </form>

          <!-- Tarjeta 3: Carlos Restrepo (Voluntario) -->
          <form action="/session/quick-login" method="post" class="h-full">
            <input type="hidden" name="profile" value="carlos">
            <button type="submit" class="w-full h-full text-left p-4 rounded-2xl bg-slate-800/80 hover:bg-slate-700/90 border border-slate-700/80 hover:border-emerald-400 transition-all shadow-md group flex flex-col justify-between">
              <div>
                <div class="w-12 h-12 rounded-xl bg-emerald-600/30 border border-emerald-400/40 text-emerald-300 flex items-center justify-center text-xl font-bold mb-3 group-hover:scale-105 transition-transform">
                  ⛑️
                </div>
                <div class="font-bold text-sm text-white">Carlos Restrepo</div>
                <span class="inline-block px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 mt-1">
                  Voluntario Socorrista
                </span>
                <p class="text-xs text-slate-300 mt-2 line-clamp-3">
                  Registro de traslados, aforo de albergues y rescate de mascotas en Zona Norte.
                </p>
              </div>
              <div class="pt-3 mt-3 border-t border-slate-700/60 flex items-center justify-between text-xs font-semibold text-emerald-400 group-hover:text-emerald-300">
                <span>Ingresar perfil &rarr;</span>
              </div>
            </button>
          </form>

          <!-- Tarjeta 4: Andrés Gómez (Ciudadano) -->
          <form action="/session/quick-login" method="post" class="h-full">
            <input type="hidden" name="profile" value="andres">
            <button type="submit" class="w-full h-full text-left p-4 rounded-2xl bg-slate-800/80 hover:bg-slate-700/90 border border-slate-700/80 hover:border-amber-400 transition-all shadow-md group flex flex-col justify-between">
              <div>
                <div class="w-12 h-12 rounded-xl bg-amber-600/30 border border-amber-400/40 text-amber-300 flex items-center justify-center text-xl font-bold mb-3 group-hover:scale-105 transition-transform">
                  🧑
                </div>
                <div class="font-bold text-sm text-white">Andrés Felipe Gómez</div>
                <span class="inline-block px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-amber-500/20 text-amber-300 border border-amber-500/30 mt-1">
                  Ciudadano
                </span>
                <p class="text-xs text-slate-300 mt-2 line-clamp-3">
                  Solicitud de auxilios humanitarios, localización y mensajes a familiares.
                </p>
              </div>
              <div class="pt-3 mt-3 border-t border-slate-700/60 flex items-center justify-between text-xs font-semibold text-amber-400 group-hover:text-amber-300">
                <span>Ingresar perfil &rarr;</span>
              </div>
            </button>
          </form>
        </div>
      </div>

      <!-- Formularios: Iniciar Sesión / Registrar Nuevo -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Formulario Iniciar Sesión -->
        <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
          <div class="border-b border-slate-100 pb-3">
            <h3 class="font-bold text-slate-900 text-base flex items-center gap-2">
              <span>🔐</span> Iniciar Sesión con Credenciales
            </h3>
            <p class="text-xs text-slate-500">Para usuarios ya registrados en el sistema.</p>
          </div>

          <form action="/session/login" method="post" class="space-y-4">
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Nombre de Usuario</label>
              <input type="text" name="username" placeholder="Ej: laura.morales" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none">
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Contraseña</label>
              <input type="password" name="password" placeholder="••••••••" required class="w-full text-xs px-3.5 py-2.5 border rounded-xl focus:ring-2 focus:ring-blue-500 outline-none">
            </div>
            <button type="submit" class="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs rounded-xl shadow-sm transition">
              Iniciar Sesión
            </button>
          </form>
        </div>

        <!-- Formulario Registro Nuevo Usuario -->
        <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
          <div class="border-b border-slate-100 pb-3">
            <h3 class="font-bold text-slate-900 text-base flex items-center gap-2">
              <span>📝</span> Registro de Nuevo Usuario
            </h3>
            <p class="text-xs text-slate-500">Da de alta a un ciudadano, voluntario o coordinador.</p>
          </div>

          <form action="/session/register" method="post" class="space-y-3">
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Nombre Completo</label>
              <input type="text" name="full_name" placeholder="Ej: Marcela Trujillo" required class="w-full text-xs px-3 py-2 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
            </div>
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Usuario</label>
                <input type="text" name="username" placeholder="Ej: marcela.t" required class="w-full text-xs px-3 py-2 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Contraseña</label>
                <input type="password" name="password" placeholder="••••••••" required class="w-full text-xs px-3 py-2 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
            </div>
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Rol</label>
                <select name="role" class="w-full text-xs px-3 py-2 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none bg-white">
                  <option value="ciudadano">Ciudadano</option>
                  <option value="voluntario">Voluntario</option>
                  <option value="coordinador">Coordinador</option>
                </select>
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Zona Principal</label>
                <input type="text" name="zone" placeholder="Ej: Zona Centro" required class="w-full text-xs px-3 py-2 border rounded-xl focus:ring-2 focus:ring-red-500 outline-none">
              </div>
            </div>
            <button type="submit" class="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl shadow-sm transition">
              Completar Registro e Ingresar
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
