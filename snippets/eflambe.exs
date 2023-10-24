topics = Postion.Content.list_topics()
get_limited = fn parent_ids, limit ->
  topics |> Enum.filter(& &1.parent_id in parent_ids) |> Enum.take(limit)
end
root = get_limited.([nil], 10)
l1 = root |> MapSet.new(& &1.id) |> get_limited.(100)
l2 = l1 |> MapSet.new(& &1.id) |> get_limited.(1_000)
:eflambe.apply({Postion.Content, :topic_tree, [Enum.concat([root, l1])]}, open: :speedscope)
:eflambe.apply({Postion.Content, :topic_tree, [Enum.concat([root, l1, l2])]}, open: :speedscope)