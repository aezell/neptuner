defmodule NeptunerWeb.PageController do
  use NeptunerWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def home2(conn, _params) do
    render(conn, :home2, layout: false)
  end

  def design_system(conn, _params) do
    render(conn, :design_system)
  end
end
