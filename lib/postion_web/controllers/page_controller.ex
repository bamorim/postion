defmodule PostionWeb.PageController do
  use PostionWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: ~p"/topics")
      |> halt()
    else
      conn
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end
end
