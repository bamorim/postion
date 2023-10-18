defmodule Postion.Repo do
  use Ecto.Repo,
    otp_app: :postion,
    adapter: Ecto.Adapters.Postgres
end
