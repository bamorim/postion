defmodule TopicGeneration do
  alias Postion.Content.Topic

  def generate(per_level, levels, parent_ids \\ [nil], result \\ [])

  def generate(_per_level, 0, _parent_ids, topics), do: Enum.shuffle(topics)

  def generate(per_level, levels, parent_ids, topics) do
    new_topics =
      Enum.flat_map(parent_ids, fn parent_id ->
        Enum.map(1..per_level, fn _ ->
          id = :erlang.unique_integer([:positive, :monotonic])
          %Topic{id: id, name: "Topic #{id}", parent_id: parent_id}
        end)
      end)

    topics = Enum.concat(topics, new_topics)
    parent_ids = Enum.map(new_topics, & &1.id)
    generate(per_level, levels - 1, parent_ids, topics)
  end
end

for {name, arg} <- [
      two_level: TopicGeneration.generate(10, 2),
      three_level: TopicGeneration.generate(10, 3)
    ] do
  :eflambe.apply({Postion.Content, :topic_tree, [arg]}, open: :speedscope)
end