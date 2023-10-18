defmodule Postion.ContentTest do
  use Postion.DataCase

  alias Postion.Content

  describe "topics" do
    alias Postion.Content.Topic

    import Postion.ContentFixtures

    @invalid_attrs %{name: nil}

    test "list_topics/0 returns all topics" do
      topic = topic_fixture()
      assert Content.list_topics() == [topic]
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
end
