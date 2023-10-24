alias Postion.Content.Topic

defmodule TreeViewOld do
  def topic_tree(topics) do
    do_topic_tree(topics, nil, 1, 5)
  end

  defp do_topic_tree(_all_topics, _parent_id, level, level), do: %{}

  defp do_topic_tree(all_topics, parent_id, level, max_level) do
    all_topics
    |> Enum.filter(&(&1.parent_id == parent_id))
    |> Map.new(&{&1.id, {&1.name, do_topic_tree(all_topics, &1.id, level + 1, max_level)}})
  end
end

defmodule TreeViewNew do
  def topic_tree(topics) do
    topics
    |> Enum.group_by(& &1.parent_id)
    |> do_topic_tree(nil, 1, 5)
  end

  defp do_topic_tree(_topics_per_parent, _parent_id, level, level), do: %{}

  defp do_topic_tree(topics_per_parent, parent_id, level, max_level) do
    topics_per_parent
    |> Map.get(parent_id, [])
    |> Map.new(&{&1.id, {&1.name, do_topic_tree(topics_per_parent, &1.id, level + 1, max_level)}})
  end
end

defmodule TopicGeneration do
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

Benchee.run(
  %{
    "old" => &TreeViewOld.topic_tree/1,
    "new" => &TreeViewNew.topic_tree/1
  },
  inputs: %{
    "1 level" => TopicGeneration.generate(10, 1),
    "2 level" => TopicGeneration.generate(10, 2),
    "3 level" => TopicGeneration.generate(10, 3),
    "4 level" => TopicGeneration.generate(10, 4),
    "large level" => TopicGeneration.generate(100, 2)
  },
  formatters: [
    Benchee.Formatters.HTML,
    Benchee.Formatters.Console
  ]
)
