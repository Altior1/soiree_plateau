defmodule SoireePlateau.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
