defmodule EmergencySystemWeb.ErrorHTML do
  def render(template, _assigns) do
    "<h1>Error: #{Phoenix.Controller.status_message_from_template(template)}</h1>"
  end
end
