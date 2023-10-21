defmodule PostionWeb.TopicBreadcrumbsComponent do
  use PostionWeb, :live_component

  alias Postion.Content
  alias PetalComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-4">
      <PetalComponents.Breadcrumbs.breadcrumbs separator="chevron" links={@links} />
    </div>
    """
  end

  @impl true
  def update(%{topic_id: topic_id} = assigns, socket) do
    links = links_for(topic_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(links: links)}
  end

  defp links_for(topic_id, agg \\ [])

  defp links_for(nil, agg) do
    [%{label: "Root", to: ~p"/topics"} | agg]
  end

  defp links_for(topic_id, agg) do
    topic = Content.get_topic!(topic_id)
    links_for(topic.parent_id, [%{label: topic.name, to: ~p"/topics/#{topic}"} | agg])
  end
end
