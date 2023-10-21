defmodule PostionWeb.UserBadgeComponent do
  use PostionWeb, :live_component

  alias Postion.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <span class="bg-brand/5 text-brand rounded-full px-2 font-medium leading-6">
      <%= @display_name %>
    </span>
    """
  end

  @impl true
  def update(%{user_id: user_id} = assigns, socket) do
    user = Accounts.get_user!(user_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(display_name: user.email)}
  end
end
