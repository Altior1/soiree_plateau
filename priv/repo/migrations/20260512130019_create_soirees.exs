defmodule SoireePlateau.Repo.Migrations.CreateSoirees do
  use Ecto.Migration

  def change do
    create table(:soirees) do
      add :title, :string
      add :date, :naive_datetime
      add :home, :string
      add :capacity, :integer
      add :host, references(:User, on_delete: :nothing)
      add :game, references(:Game, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:soirees, [:user_id])

    create index(:soirees, [:host])
    create index(:soirees, [:game])
  end
end
