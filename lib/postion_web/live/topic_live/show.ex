defmodule PostionWeb.TopicLive.Show do
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
     |> assign(:topic, Content.get_topic!(id))}
  end

  defp page_title(:show), do: "Show Topic"
  defp page_title(:edit), do: "Edit Topic"
end
