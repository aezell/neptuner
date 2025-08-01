defmodule NeptunerWeb.ErrorHTMLTest do
  use NeptunerWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    assigns = %{flash: %{}, current_scope: nil}
    html = render_to_string(NeptunerWeb.ErrorHTML, "404", "html", assigns)
    assert html =~ "404"
    assert html =~ "LOST IN THE COSMIC VOID"
  end

  test "renders 500.html" do
    assigns = %{flash: %{}, current_scope: nil}
    html = render_to_string(NeptunerWeb.ErrorHTML, "500", "html", assigns)
    assert html =~ "500"
    assert html =~ "COSMIC MALFUNCTION DETECTED"
  end
end
