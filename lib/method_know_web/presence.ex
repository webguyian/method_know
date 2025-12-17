defmodule MethodKnowWeb.Presence do
  use Phoenix.Presence,
    otp_app: :method_know,
    pubsub_server: MethodKnow.PubSub
end
