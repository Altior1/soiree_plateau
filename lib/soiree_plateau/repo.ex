defmodule SoireePlateau.Repo do
  use Ecto.Repo,
    otp_app: :soiree_plateau,
    adapter: Ecto.Adapters.Postgres
end
