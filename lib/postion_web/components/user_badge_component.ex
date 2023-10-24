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
  def update_many(assigns_sockets) do
    ids = for {assigns, _sockets} <- assigns_sockets, do: assigns.id

    users = ids |> Accounts.get_users_by_id() |> Map.new(&{&1.id, &1})

    for {assigns, socket} <- assigns_sockets do
      assign(socket, display_name: users[assigns.id].email)
    end
  end
end
