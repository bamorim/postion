defmodule Postion.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Postion.Content` context.
  """

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
    topic_id =
      Map.get_lazy(attrs, :topic_id, fn ->
        Map.get_lazy(attrs, :topic, fn ->
          topic_fixture(Map.get(attrs, :topic_attrs, %{}))
        end).id
      end)

    {:ok, post} =
      attrs
      |> Enum.into(%{
        content: "content##{System.unique_integer()}",
        title: "post##{System.unique_integer()}",
        topic_id: topic_id
      })
      |> Postion.Content.create_post()

    post
  end
end
