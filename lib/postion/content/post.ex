defmodule Postion.Content.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Postion.Content.Topic
  alias Postion.Content.Contributor

  schema "posts" do
    field :title, :string
    field :content, :string
    belongs_to :topic, Topic
    has_many :contributors, Contributor

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :content, :topic_id])
    |> validate_required([:title, :content, :topic_id])
  end
end
