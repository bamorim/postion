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

  def to_html(%__MODULE__{content: content}) do
    MDEx.to_html(content,
      extension: [autolink: true, strikethrough: true, table: true],
      features: [sanitize: true]
    )
  end

  def to_text(post, max_size \\ 50) do
    post
    |> to_html()
    |> Floki.parse_fragment!()
    |> Floki.text(sep: " ")
    |> String.split(~r/\s+/)
    |> Enum.reduce({"", true}, fn
      _, {acc, false} ->
        {acc, false}

      word, {acc, _} ->
        new = Enum.join([acc, word], " ")

        if String.length(new) < max_size do
          {new, true}
        else
          {"#{acc}...", false}
        end
    end)
    |> elem(0)
  end
end
