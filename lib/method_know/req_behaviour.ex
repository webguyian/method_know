defmodule MethodKnow.ReqBehaviour do
  @callback post(String.t(), keyword()) :: {:ok, map()} | {:error, any()}
end
