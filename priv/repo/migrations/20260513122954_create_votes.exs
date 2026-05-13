defmodule SoireePlateau.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :rating, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :soiree_id, references(:soirees, on_delete: :delete_all), null: false
      add :game_id, references(:games, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:votes, [:soiree_id])
    create index(:votes, [:game_id])
    create index(:votes, [:user_id])
    create unique_index(:votes, [:user_id, :soiree_id, :game_id])
  end
end
