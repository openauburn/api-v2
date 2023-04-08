defmodule OpenAuburnApi.Repo do
  use Ecto.Repo,
    otp_app: :open_auburn_api,
    adapter: Ecto.Adapters.Postgres
end
