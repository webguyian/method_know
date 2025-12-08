defmodule MethodKnowWeb.PageController do
  use MethodKnowWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
