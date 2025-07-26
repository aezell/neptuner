defmodule NeptunerWeb.LegalController do
  use NeptunerWeb, :controller

  def terms(conn, _params) do
    render(conn, :terms)
  end

  def privacy(conn, _params) do
    render(conn, :privacy)
  end
end
