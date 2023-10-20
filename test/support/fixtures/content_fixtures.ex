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
    {:ok, post} =
      attrs
      |> Enum.into(%{
        content: "some content",
        title: "some title"
      })
      |> Postion.Content.create_post()

    post
  end
end