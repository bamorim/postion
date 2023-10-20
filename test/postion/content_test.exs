defmodule Postion.ContentTest do
  use Postion.DataCase

  alias Postion.Accounts
  alias Postion.Content
  alias Postion.Content.Contributor
  alias Postion.Content.Post
  alias Postion.Content.Topic

  import Postion.AccountsFixtures
  import Postion.ContentFixtures

  describe "topics" do
    @invalid_attrs %{name: nil}

    test "list_topics/0 returns all topics" do
      topic = topic_fixture()
      child_topic = topic_fixture(%{parent_id: topic.id})
      topics = Content.list_topics()
      assert [%Topic{}, %Topic{}] = topics
      assert MapSet.new(topics, & &1.id) == MapSet.new([topic.id, child_topic.id])
    end

    test "list_topics/1 can filter child topics by parent" do
      topic = topic_fixture()
      child_topic = topic_fixture(%{parent_id: topic.id})
      assert Content.list_topics(parent_id: topic.id) == [child_topic]
    end

    test "list_topics/1 can filter root topics" do
      topic = topic_fixture()
      _child_topic = topic_fixture(%{parent_id: topic.id})
      assert Content.list_topics(parent_id: nil) == [topic]
    end

    test "get_topic!/1 returns the topic with given id" do
      topic = topic_fixture()
      assert Content.get_topic!(topic.id) == topic
    end

    test "create_topic/1 with valid data creates a root topic" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Topic{} = topic} = Content.create_topic(valid_attrs)
      assert topic.name == "some name"
    end

    test "create_topic/1 with valid data creates a child topic" do
      parent = topic_fixture()
      valid_attrs = %{name: "some name", parent_id: parent.id}

      assert {:ok, %Topic{} = topic} = Content.create_topic(valid_attrs)
      assert topic.parent_id == parent.id
    end

    test "create_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_topic(@invalid_attrs)
    end

    test "create_topic/1 with non existent topic returns error changeset" do
      parent = topic_fixture()
      Repo.delete!(parent)
      attrs = %{name: "some name", parent_id: parent.id}

      assert {:error, %Ecto.Changeset{}} = Content.create_topic(attrs)
    end

    test "update_topic/2 with valid data updates the topic" do
      topic = topic_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Topic{} = topic} = Content.update_topic(topic, update_attrs)
      assert topic.name == "some updated name"
    end

    test "update_topic/2 with invalid data returns error changeset" do
      topic = topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_topic(topic, @invalid_attrs)
      assert topic == Content.get_topic!(topic.id)
    end

    test "delete_topic/1 deletes the topic" do
      topic = topic_fixture()
      assert {:ok, %Topic{}} = Content.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Content.get_topic!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset" do
      topic = topic_fixture()
      assert %Ecto.Changeset{} = Content.change_topic(topic)
    end
  end

  describe "posts" do
    @invalid_attrs %{title: nil, content: nil, topic_id: nil}

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Content.list_posts() == [post]
    end

    test "list_posts/1 returns posts by topic" do
      post = post_fixture()
      _other_post = post_fixture()
      assert Content.list_posts(topic_id: post.topic_id) == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Content.get_post!(post.id) == post
    end

    test "create_post/2 with valid data creates a post" do
      topic = topic_fixture()
      %{id: author_id} = author = user_fixture()
      valid_attrs = %{title: "some title", content: "some content", topic_id: topic.id}

      assert {:ok, %Post{} = post} = Content.create_post(author, valid_attrs)
      assert post.title == "some title"
      assert post.content == "some content"
      assert [%Contributor{user_id: ^author_id, author: true}] = post.contributors
    end

    test "create_post/2 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_post(user_fixture(), @invalid_attrs)
    end

    test "update_post/3 with valid data updates the post" do
      post = post_fixture()
      old_contributors = post.contributors
      user = user_fixture()
      update_attrs = %{title: "some updated title", content: "some updated content"}

      assert {:ok, %Post{} = post} = Content.update_post(user, post, update_attrs)
      assert post.title == "some updated title"
      assert post.content == "some updated content"

      # Add user to list of contributors
      assert %Contributor{author: false} = Enum.find(post.contributors, &(&1.user_id == user.id))

      for contributor <- old_contributors do
        assert contributor in post.contributors
      end
    end

    test "update_post/3 don't add new contributor if user is already contributor" do
      post = post_fixture()
      [contributor] = post.contributors
      user = Accounts.get_user!(contributor.user_id)
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Post{} = post} = Content.update_post(user, post, update_attrs)
      assert post.contributors == [contributor]
    end

    test "update_post/3 with invalid data returns error changeset" do
      post = post_fixture()
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_post(user, post, @invalid_attrs)
      assert take_fields(post) == post.id |> Content.get_post!() |> take_fields()
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Content.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Content.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Content.change_post(post)
    end
  end
end
