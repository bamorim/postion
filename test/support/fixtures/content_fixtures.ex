defmodule Postion.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Postion.Content` context.
  """

  import Postion.AccountsFixtures

  @doc """
  Generate a topic.
  """
  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        name: "topic##{System.unique_integer()}"
      })
      |> Postion.Content.create_topic()

    topic
  end

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    author =
      Map.get_lazy(attrs, :author, fn ->
        user_fixture()
      end)

    topic_id =
      Map.get_lazy(attrs, :topic_id, fn ->
        Map.get_lazy(attrs, :topic, fn ->
          topic_fixture(Map.get(attrs, :topic_attrs, %{}))
        end).id
      end)

    attrs =
      Enum.into(attrs, %{
        content: "content##{System.unique_integer()}",
        title: "post##{System.unique_integer()}",
        topic_id: topic_id
      })

    {:ok, post} = Postion.Content.create_post(author, attrs)

    post
  end
end
