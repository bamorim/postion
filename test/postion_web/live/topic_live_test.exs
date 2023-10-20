defmodule PostionWeb.TopicLiveTest do
  use PostionWeb.ConnCase

  import Phoenix.LiveViewTest
  import Postion.ContentFixtures
  import Postion.AccountsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_topic(_) do
    topic = topic_fixture()
    %{topic: topic}
  end

  defp login(%{conn: conn}) do
    user = user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  describe "Index" do
    setup [:create_topic, :login]

    test "lists all topics", %{conn: conn, topic: topic} do
      {:ok, _index_live, html} = live(conn, ~p"/topics")

      assert html =~ "Listing Topics"
      assert html =~ topic.name
    end

    test "don't show non-root topics", %{conn: conn, topic: topic} do
      child_topic = topic_fixture(%{parent_id: topic.id, name: "child name"})
      {:ok, _index_live, html} = live(conn, ~p"/topics")

      refute html =~ child_topic.name
    end

    test "saves new topic", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert index_live |> element("a", "New Topic") |> render_click() =~
               "New Topic"

      assert_patch(index_live, ~p"/topics/new")

      assert index_live
             |> form("#topic-form", topic: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#topic-form", topic: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/topics")

      html = render(index_live)
      assert html =~ "Topic created successfully"
      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_topic, :login]

    test "displays topic", %{conn: conn, topic: topic} do
      {:ok, _show_live, html} = live(conn, ~p"/topics/#{topic}")

      assert html =~ "Show Topic"
      assert html =~ topic.name
    end

    test "displays children topics", %{conn: conn, topic: topic} do
      other_root_topic = topic_fixture()
      child_topic = topic_fixture(%{parent_id: topic.id})
      {:ok, _show_live, html} = live(conn, ~p"/topics/#{topic}")

      assert html =~ child_topic.name
      refute html =~ other_root_topic.name
    end

    test "updates topic within modal", %{conn: conn, topic: topic} do
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Topic"

      assert_patch(show_live, ~p"/topics/#{topic}/edit")

      assert show_live
             |> form("#topic-form", topic: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#topic-form", topic: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/topics/#{topic}")

      html = render(show_live)
      assert html =~ "Topic updated successfully"
      assert html =~ "some updated name"
    end

    test "saves new child topic", %{conn: conn, topic: topic} do
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      assert show_live |> element("a", "New child topic") |> render_click() =~
               "New Child Topic"

      assert_patch(show_live, ~p"/topics/#{topic}/children/new")

      assert show_live
             |> form("#topic-form", topic: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      child_topic_name = "topic##{System.unique_integer()}"

      assert show_live
             |> form("#topic-form", topic: %{name: child_topic_name})
             |> render_submit()

      assert_patch(show_live, ~p"/topics/#{topic}")

      html = render(show_live)
      assert html =~ "Topic created successfully"

      assert html =~ child_topic_name
    end

    test "deletes topic from page", %{conn: conn, topic: topic} do
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      assert show_live |> element("a", "Delete") |> render_click()

      assert_redirect(show_live, ~p"/topics")

      {:ok, index_live, _html} = live(conn, ~p"/topics")

      refute has_element?(index_live, "#topics-#{topic.id}")
    end

    test "redirects back to parent topic when deleting child topic", %{conn: conn, topic: topic} do
      child_topic = topic_fixture(%{parent_id: topic.id})
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{child_topic}")

      assert show_live |> element("a", "Delete") |> render_click()

      assert_redirect(show_live, ~p"/topics/#{topic}")
    end
  end
end
