defmodule SoireePlateau.Repo.Migrations.CreateSoirees do
  use Ecto.Migration

  def change do
    create table(:soirees) do
      add :title, :string
      add :date, :naive_datetime
      add :home, :string
      add :capacity, :integer
      add :host, references(:users, on_delete: :delete_all)
      add :game_id, references(:games, on_delete: :nothing)


      timestamps(type: :utc_datetime)
    end

    create index(:soirees, [:host])
    create index(:soirees, [:game_id])
  end
end
