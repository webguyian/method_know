Mox.defmock(MethodKnow.ReqMock, for: MethodKnow.ReqBehaviour)
Application.put_env(:method_know, :req, MethodKnow.ReqMock)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(MethodKnow.Repo, :manual)
