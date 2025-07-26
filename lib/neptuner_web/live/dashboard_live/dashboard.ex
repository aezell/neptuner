defmodule NeptunerWeb.DashboardLive do
  use NeptunerWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.dashboard flash={@flash} current_scope={@current_scope}>
      <div>
        <.header>Dashboard</.header>
      </div>
    </Layouts.dashboard>
    """
  end
end
