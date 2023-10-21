defmodule PostionWeb.TopicLive.FormComponent do
  use PostionWeb, :live_component

  alias Postion.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.h2>
        <%= @title %>
      </.h2>

      <.simple_form
        for={@form}
        id="topic-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:parent_id]} type="hidden" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Topic</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{topic: topic} = assigns, socket) do
    changeset = Content.change_topic(topic, Map.get(assigns, :changes, %{}))

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset =
      socket.assigns.topic
      |> Content.change_topic(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"topic" => topic_params}, socket) do
    save_topic(socket, socket.assigns.action, topic_params)
  end

  defp save_topic(socket, :edit, topic_params) do
    case Content.update_topic(socket.assigns.topic, topic_params) do
      {:ok, topic} ->
        notify_parent({:saved, topic})

        {:noreply,
         socket
         |> put_flash(:info, "Topic updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_topic(socket, :new, topic_params) do
    case Content.create_topic(topic_params) do
      {:ok, topic} ->
        notify_parent({:saved, topic})

        {:noreply,
         socket
         |> put_flash(:info, "Topic created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
