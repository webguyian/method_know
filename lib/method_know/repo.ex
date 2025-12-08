defmodule MethodKnow.Repo do
  use Ecto.Repo,
    otp_app: :method_know,
    adapter: Ecto.Adapters.SQLite3
end
