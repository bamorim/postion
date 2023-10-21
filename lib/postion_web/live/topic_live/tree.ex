defmodule PostionWeb.TopicLive.Tree do
  use PostionWeb, :live_view

  alias Postion.Content

  @impl true
  def render(assigns) do
    ~H"""
    <.header>Topics</.header>

    <section class="my-4">
      <.vertical_menu current_page={:home} menu_items={@topic_menu} />
    </section>

    <.back navigate={~p"/topics"}>Back to topics</.back>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    topic_menu = Content.topic_tree() |> to_menu()
    {:ok, assign(socket, :topic_menu, topic_menu)}
  end

  defp to_menu(topic_tree) do
    Enum.map(topic_tree, fn {id, {name, children}} ->
      base = %{
        name: "topic-#{id}",
        label: name,
        icon: :folder,
        path: ~p"/topics/#{id}"
      }

      if Enum.empty?(children) do
        base
      else
        Map.merge(base, %{
          menu_items: [Map.merge(base, %{icon: :link, label: "Open"}) | to_menu(children)]
        })
      end
    end)
  end
end
