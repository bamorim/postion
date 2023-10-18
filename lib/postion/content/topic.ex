defmodule Postion.Content.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :name, :string
    belongs_to :parent, __MODULE__

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name, :parent_id])
    |> validate_required([:name])
    |> foreign_key_constraint(:parent_id)
  end
end
