defmodule Neptuner.Repo do
  use Ecto.Repo,
    otp_app: :neptuner,
    adapter: Ecto.Adapters.Postgres
end
