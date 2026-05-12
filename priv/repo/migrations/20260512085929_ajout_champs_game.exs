defmodule SoireePlateau.Repo.Migrations.AjoutChampsGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :image_url, :string
      add :nb_players_min, :integer
      add :nb_players_max, :integer
      add :duration, :integer
      add :complexity, :integer
    end
  end
end
