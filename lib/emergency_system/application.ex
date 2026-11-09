defmodule EmergencySystem.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    result = EmergencySystem.Supervisor.start_link([])

    if Mix.env() != :test do
      EmergencySystem.Seeds.run()
    end

    result
  end
end
