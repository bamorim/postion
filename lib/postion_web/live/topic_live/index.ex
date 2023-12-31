defmodule PostionWeb.TopicLive.Index do
  use PostionWeb, :live_view

  alias Postion.Content
  alias Postion.Content.Topic

  @impl true
  def mount(_params, _session, socket) do
    show_tree = Postion.FeatureFlags.enabled?("TREE_VIEW", socket.assigns.current_user.id)

    {:ok,
     socket
     |> assign(:show_tree, show_tree)
     |> stream(:topics, Content.list_topics(parent_id: nil))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Topic")
    |> assign(:topic, %Topic{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Topics")
    |> assign(:topic, nil)
  end

  @impl true
  def handle_info({PostionWeb.TopicLive.FormComponent, {:saved, topic}}, socket) do
    {:noreply, stream_insert(socket, :topics, topic)}
  end
end
