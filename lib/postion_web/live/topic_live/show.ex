defmodule PostionWeb.TopicLive.Show do
  use PostionWeb, :live_view

  alias Postion.Content
  alias Postion.Content.Topic
  alias Postion.Content.Post

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    posts = Content.list_posts(topic_id: id, limit: 50)

    {:ok,
     socket
     |> assign(:post_offset, length(posts))
     |> stream(:child_topics, Content.list_topics(parent_id: id))
     |> stream(:posts, posts)}
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
     |> assign(:parent_path, parent_path)
     |> assign(:topic, topic)
     |> assign(:child_topic, %Topic{})
     |> assign(:post, %Post{})}
  end

  defp page_title(:show), do: "Show Topic"
  defp page_title(:edit), do: "Edit Topic"
  defp page_title(:new_child), do: "New Topic"
  defp page_title(:new_post), do: "New Post"

  @impl true
  def handle_info({PostionWeb.TopicLive.FormComponent, {:saved, topic}}, socket) do
    if topic.id != socket.assigns.topic.id do
      {:noreply, stream_insert(socket, :child_topics, topic)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({PostionWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} = Content.delete_topic(socket.assigns.topic)

    {:noreply, redirect(socket, to: socket.assigns.parent_path)}
  end
end
