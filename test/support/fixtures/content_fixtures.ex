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
        name: "some name"
      })
      |> Postion.Content.create_topic()

    topic
  end
end
