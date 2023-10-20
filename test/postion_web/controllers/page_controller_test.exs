defmodule PostionWeb.PageControllerTest do
  use PostionWeb.ConnCase

  import Postion.AccountsFixtures

  describe "GET /" do
    test "redirect to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert redirected_to(conn) =~ "/users/log_in"
    end

    test "redirect to topics index when authenticated", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get(~p"/")
      assert redirected_to(conn) == "/topics"
    end
  end
end
