defmodule Postion.Repo.Migrations.CreatePostContributors do
  use Ecto.Migration

  def change do
    create table(:post_contributors) do
      add :post_id, references(:posts, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)
      add :author, :boolean, null: false, default: false
    end
  end
end
