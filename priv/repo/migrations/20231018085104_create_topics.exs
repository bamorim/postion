defmodule Postion.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string
      add :parent, references(:topics, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:topics, [:parent])
  end
end
