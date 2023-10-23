defmodule PostionWeb.TopicLive.Show do
  use PostionWeb, :live_view

  alias Postion.Content
  alias Postion.Content.Topic
  alias Postion.Content.Post

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    topic = Content.get_topic!(id)
    child_topics = Content.list_topics(parent_id: id)

    parent_path =
      case topic.parent_id do
        nil -> ~p"/topics"
        parent_id -> ~p"/topics/#{parent_id}"
      end

    {:ok,
     socket
     |> assign(:topic, topic)
     |> assign(:parent_path, parent_path)
     |> assign(:child_topic, %Topic{})
     |> assign(:post, %Post{})
     |> stream(:child_topics, child_topics)
     |> stream(:posts, [])
     |> assign(:posts_offset, 0)
     |> get_posts_paginated()}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action))}
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

  def handle_event("load_more", _, socket) do
    {:noreply, get_posts_paginated(socket)}
  end

  @per_page 50
  defp get_posts_paginated(socket) do
    %{topic: %{id: topic_id}, posts_offset: offset} = socket.assigns

    posts = Content.list_posts(topic_id: topic_id, limit: @per_page + 1, offset: offset)
    has_more = length(posts) > @per_page
    posts = posts |> Enum.take(@per_page) |> Enum.map(&render_post/1)
    new_offset = offset + length(posts)

    socket
    |> assign(:posts_offset, new_offset)
    |> assign(:has_more_posts, has_more)
    |> stream(:posts, posts)
  end

  defp render_post(%Post{} = post) do
    post
    |> Map.take([:id, :title])
    |> Map.put(:content, Post.to_text(post))
    |> Map.put(:updated_at, Timex.format!(post.updated_at, "{relative}", :relative))
  end
end
