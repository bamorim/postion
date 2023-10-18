defmodule Postion.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string
      add :parent_id, references(:topics, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:topics, [:parent_id])
  end
end
