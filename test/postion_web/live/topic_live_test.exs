defmodule PostionWeb.TopicLiveTest do
  use PostionWeb.ConnCase

  import Phoenix.LiveViewTest
  import Postion.ContentFixtures
  import Postion.AccountsFixtures

  @create_topic_attrs %{name: "some name"}
  @update_topic_attrs %{name: "some updated name"}
  @invalid_topic_attrs %{name: nil}
  @create_post_attrs %{title: "some title", content: "some content"}
  @invalid_post_attrs %{title: nil, content: nil}

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

  describe "Index" do
    setup [:create_topic, :login]

    test "lists all topics", %{conn: conn, topic: topic} do
      {:ok, _index_live, html} = live(conn, ~p"/topics")

      assert html =~ "Topics"
      assert html =~ topic.name
    end

    test "saves new topic", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      index_live |> element("a", "New Topic") |> render_click()

      assert index_live
             |> element("h1", "New Topic")
             |> has_element?()

      assert_patch(index_live, ~p"/topics/new")

      assert index_live
             |> form("#topic-form", topic: @invalid_topic_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#topic-form", topic: @create_topic_attrs)
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

      show_live |> element("a", "Edit") |> render_click()

      assert show_live
             |> element("h1", "Edit Topic")
             |> has_element?()

      assert_patch(show_live, ~p"/topics/#{topic}/edit")

      assert show_live
             |> form("#topic-form", topic: @invalid_topic_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#topic-form", topic: @update_topic_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/topics/#{topic}")

      html = render(show_live)
      assert html =~ "Topic updated successfully"
      assert html =~ "some updated name"
    end

    test "saves new child topic", %{conn: conn, topic: topic} do
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      show_live |> element("a", "New Topic") |> render_click()

      assert show_live
             |> element("h1", "New Topic")
             |> has_element?()

      assert_patch(show_live, ~p"/topics/#{topic}/children/new")

      assert show_live
             |> form("#topic-form", topic: @invalid_topic_attrs)
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

  describe "Show - Post List and Actions" do
    setup [:create_topic, :create_post, :login]

    test "lists all posts", %{conn: conn, topic: topic, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      assert show_live
             |> element("*", post.title)
             |> has_element?()
    end

    test "saves new post", %{conn: conn, topic: topic} do
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      assert show_live |> element("a", "New Post") |> render_click()

      assert show_live
             |> element("h1", "New Post")
             |> has_element?()

      assert_patch(show_live, ~p"/topics/#{topic}/posts/new")

      assert show_live
             |> form("#post-form", post: @invalid_post_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#post-form", post: @create_post_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/topics/#{topic}")

      html = render(show_live)
      assert html =~ "Post created successfully"
      assert html =~ "some title"
    end
  end
end
