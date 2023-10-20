defmodule PostionWeb.TopicLive.Show do
  use PostionWeb, :live_view

  alias Postion.Content
  alias Postion.Content.Topic

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    topic = Content.get_topic!(id)

    parent_path =
      case topic.parent_id do
        nil -> ~p"/topics"
        parent_id -> ~p"/topics/#{parent_id}"
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:topic, topic)
     |> assign(:child_topic, %Topic{})
     |> assign(:parent_path, parent_path)
     |> stream(:child_topics, Content.list_topics(parent_id: id))}
  end

  defp page_title(:show), do: "Show Topic"
  defp page_title(:edit), do: "Edit Topic"
  defp page_title(:new_child), do: "New Topic"

  @impl true
  def handle_info({PostionWeb.TopicLive.FormComponent, {:saved, _topic}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} = Content.delete_topic(socket.assigns.topic)

    {:noreply, redirect(socket, to: socket.assigns.parent_path)}
  end
end
