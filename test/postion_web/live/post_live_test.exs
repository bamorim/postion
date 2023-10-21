defmodule PostionWeb.PostLiveTest do
  use PostionWeb.ConnCase

  import Phoenix.LiveViewTest
  import Postion.ContentFixtures
  import Postion.AccountsFixtures

  @update_attrs %{title: "some updated title", content: "some updated content"}
  @invalid_attrs %{title: nil, content: nil}

  defp create_topic(_) do
    topic = topic_fixture()
    %{topic: topic}
  end

  defp create_post(context) do
    post = post_fixture(Map.take(context, [:topic]))
    %{post: post}
  end

  defp login(%{conn: conn}) do
    user = user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  describe "Show" do
    setup [:create_topic, :create_post, :login]

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post}")

      assert html =~ "Show Post"
      assert html =~ post.title
    end

    test "updates post within modal", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Post"

      assert_patch(show_live, ~p"/posts/#{post}/show/edit")

      assert show_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#post-form", post: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/posts/#{post}")

      html = render(show_live)
      assert html =~ "Post updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes post from page", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      assert show_live |> element("button", "Delete") |> render_click()

      assert_redirect(show_live, ~p"/topics/#{post.topic_id}")

      {:ok, index_live, _html} = live(conn, ~p"/topics/#{post.topic_id}")

      refute has_element?(index_live, "#posts-#{post.id}")
    end
  end
end
