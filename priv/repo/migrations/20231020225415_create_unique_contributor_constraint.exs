defmodule Postion.Repo.Migrations.CreateUniqueContributorConstraint do
  use Ecto.Migration

  def change do
    create index(:post_contributors, [:user_id, :post_id], unique: true)
  end
end
