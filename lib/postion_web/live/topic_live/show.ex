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
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:topic, Content.get_topic!(id))
     |> assign(:child_topic, %Topic{})
     |> stream(:child_topics, Content.list_topics(parent_id: id))}
  end

  defp page_title(:show), do: "Show Topic"
  defp page_title(:edit), do: "Edit Topic"
  defp page_title(:new_child), do: "New Child Topic"

  @impl true
  def handle_info({PostionWeb.TopicLive.FormComponent, {:saved, _topic}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} = Content.delete_topic(socket.assigns.topic)

    case socket.assigns.topic.parent_id do
      nil ->
        {:noreply, redirect(socket, to: ~p"/topics")}

      parent_id ->
        {:noreply, redirect(socket, to: ~p"/topics/#{parent_id}")}
    end
  end
end
