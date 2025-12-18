defmodule MethodKnowWeb.ErrorController do
  use MethodKnowWeb, :controller

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_layout(html: {MethodKnowWeb.Layouts, :app})
    |> put_view(html: MethodKnowWeb.ErrorHTML)
    |> render(:"404")
  end
end
