defmodule NeptunerWeb.Plugs.AdminAuthentication do
  alias Plug.BasicAuth

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    config = Application.get_env(:neptuner, :basic_auth)
    BasicAuth.basic_auth(conn, config)
  end
end
