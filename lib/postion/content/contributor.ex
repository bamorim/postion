defmodule Postion.Content.Contributor do
  use Ecto.Schema

  alias Postion.Content.Post

  schema "post_contributors" do
    belongs_to :post, Post
    field :user_id, :id
    field :author, :boolean, default: false
  end
end
