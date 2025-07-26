defmodule NeptunerWeb.RateLimit do
  use Hammer, backend: :ets
end
