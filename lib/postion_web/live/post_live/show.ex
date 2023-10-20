defmodule PostionWeb.PostLive.Show do
  use PostionWeb, :live_view

  alias Postion.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Content.get_post!(id))}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} = Content.delete_post(socket.assigns.post)

    {:noreply, redirect(socket, to: ~p"/topics/#{socket.assigns.post.topic_id}")}
  end
end
